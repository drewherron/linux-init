# Snapper Setup Guide (Fedora + Btrfs)

This guide walks through installing and configuring **Snapper** for automatic Btrfs snapshots on Fedora.
Tested with a layout where `/` and `/home` are separate Btrfs subvolumes (common in modern Fedora installs).

---

## 1. Install packages

```bash
sudo dnf install snapper snapper-plugins python3-dbus
sudo dnf install btrfs-assistant  # Optional GUI
```

Enable automatic snapshot timers:

```bash
sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer
```

---

## 2. Verify subvolumes

Check your subvolume layout:

```bash
sudo btrfs subvolume list /
```

Typical Fedora output:

```
ID 256 path home
ID 257 path root
```

---

## 3. Create Snapper configs

For root:

```bash
sudo snapper -c root create-config /
```

For home (if it’s a separate subvolume):

```bash
sudo snapper -c home create-config /home
```

List all configs:

```bash
sudo snapper list-configs
```

---

## 4. Exclude Downloads from snapshots (recommended)

**Problem:** Downloads folders accumulate large temporary files. When snapshotted, deleted downloads stick around in snapshots for weeks/months, wasting enormous disk space.

**Solution:** Create a separate btrfs subvolume for Downloads. Snapper respects subvolume boundaries and won't traverse into nested subvolumes, so Downloads will be automatically excluded from all future snapshots.

### Steps to exclude ~/Downloads

**1. Check your current btrfs UUID and mount options:**

```bash
grep btrfs /etc/fstab
```

Example output:
```
UUID=f4de1ba1-36d1-426e-b189-ea69c1623e1b /home  btrfs  subvol=home,compress=zstd:1,x-systemd.device-timeout=0 0 0
```

Note your UUID and options - you'll use them in step 4.

**2. Back up and create new subvolume:**

First, mount the btrfs root to create the subvolume at the top level:

```bash
# Create temporary mount point
sudo mkdir -p /mnt/btrfs-root

# Mount the btrfs root (replace UUID with yours from step 1)
sudo mount -o subvolid=5 UUID=f4de1ba1-36d1-426e-b189-ea69c1623e1b /mnt/btrfs-root

# Create the downloads subvolume
sudo btrfs subvolume create /mnt/btrfs-root/downloads

# Verify it was created
sudo btrfs subvolume list /mnt/btrfs-root

# Unmount
sudo umount /mnt/btrfs-root
```

**3. Move existing Downloads:**

```bash
# Temporarily rename your current Downloads
mv ~/Downloads ~/Downloads.old
```

**4. Add to /etc/fstab:**

Edit `/etc/fstab` and add a new line for Downloads (using the UUID and options from step 1):

```bash
sudo nano /etc/fstab
```

Add this line (adjust UUID and options to match your existing /home entry):

```
UUID=f4de1ba1-36d1-426e-b189-ea69c1623e1b /home/drew/Downloads  btrfs  subvol=downloads,compress=zstd:1,x-systemd.device-timeout=0 0 0
```

**5. Reload systemd and mount:**

```bash
# Reload systemd to recognize the new fstab entry
sudo systemctl daemon-reload

# Create the mount point
mkdir ~/Downloads

# Mount it
sudo mount ~/Downloads

# Fix ownership (new subvolumes are created as root:root)
sudo chown drew:drew ~/Downloads

# Verify it's mounted as a subvolume
findmnt ~/Downloads
# Should show: /home/drew/Downloads[/downloads]

# Copy files back (optional - or just leave it empty)
cp -a ~/Downloads.old/* ~/Downloads/
rm -rf ~/Downloads.old
```

**6. Reboot to verify:**

```bash
sudo reboot
```

After reboot, verify Downloads is still mounted:

```bash
findmnt ~/Downloads
sudo btrfs subvolume list /
```

### Notes

- **Existing snapshots** still contain old Downloads data. Consider cleaning up old snapshots to reclaim space:
  ```bash
  sudo snapper -c home delete 1-100  # Delete older snapshot range
  ```

- **No backup** - Downloads won't be in snapshots anymore, so deleted files are truly gone. This is usually desirable for a downloads folder.

- **Apply to other directories** - Use this same technique for any large temporary directories:
  - `~/.cache` (application caches)
  - `~/VMs` (virtual machine images)
  - `~/Games` (large game files)

---

## 5. Configure snapshot retention

Edit each config file, e.g.:

```bash
sudo nano /etc/snapper/configs/root
```

Example settings:

```
TIMELINE_CREATE="yes"
TIMELINE_CLEANUP="yes"
TIMELINE_MIN_AGE="1800"
TIMELINE_LIMIT_HOURLY="8"
TIMELINE_LIMIT_DAILY="7"
TIMELINE_LIMIT_WEEKLY="4"
TIMELINE_LIMIT_MONTHLY="3"
TIMELINE_LIMIT_YEARLY="0"
```

---

## 6. Enable pre/post snapshots for DNF

```bash
sudo dnf install python3-dnf-plugins-extras-snapper
sudo nano /etc/dnf/plugins/snapper.conf
```

Set:

```
enabled=1
```

This creates snapshots automatically before and after package updates.

---

## 7. Enable Btrfs quotas (OPTIONAL - for accurate space usage)

** Consider carefully before enabling:** Quotas add IO overhead and can slow down writes.

**When to enable:**
- Disk is >70% full and you need to identify which snapshots to delete
- You need strict per-subvolume quotas
- Debugging excessive space usage

**When to skip:**
- You have plenty of free space (>30%)
- Snapper's space limits (`SPACE_LIMIT`, `FREE_LIMIT`) provide adequate protection
- Performance is a priority

If you decide to enable:

```bash
sudo btrfs quota enable /
sudo btrfs quota enable /home  # If backing up home
sudo btrfs quota rescan -w /   # Initial scan (can be slow)
```

Check per-subvolume usage:

```bash
sudo btrfs qgroup show /
```

---

## 8. Manual snapshot operations

**Note:** Without `-c <config>`, commands default to the `root` config.

Create a snapshot:

```bash
sudo snapper create -d "Manual test"          # Creates in root config
sudo snapper -c home create -d "Manual test"  # Creates in home config
```

List snapshots:

```bash
sudo snapper list              # Lists root snapshots (default)
sudo snapper -c home list      # Lists home snapshots
```

Delete snapshots (use snapper IDs, NOT btrfs subvolume IDs):

```bash
sudo snapper delete 5          # Delete snapshot #5 from root
sudo snapper delete 1-3        # Delete range
sudo snapper delete 1 3 5      # Delete specific snapshots
sudo snapper -c home delete 2  # Delete from home config
```

** Always use `snapper delete`, not `btrfs subvolume delete`!** Snapper properly cleans up metadata and tracking.

---

### Full system rollback

For serious system-wide issues (broken updates, corrupted configs), you can rollback the entire root filesystem.

**Important:** Rollback only works on the **root** config (`/`), not home. For home files, use manual file restoration (see Section 12).

```bash
# View available snapshots
sudo snapper list

# Rollback to a specific snapshot
sudo snapper rollback <snapshot-ID>

# Reboot to apply the rollback
sudo reboot
```

**What happens during rollback:**
1. Snapper creates a new read-write snapshot from the chosen read-only snapshot
2. Sets it as the default btrfs subvolume for next boot
3. After reboot, your system will be in the state it was at snapshot time
4. Your `/home` is NOT affected (it's a separate subvolume)

**Example scenario:**
```bash
# Bad dnf update broke the system
sudo snapper list                    # Find snapshot before update (e.g., #558)
sudo snapper rollback 558            # Rollback to pre-update state
sudo reboot                          # Boot into rolled-back system
```

**For home directory issues**, use manual restoration instead:

```bash
# Recover a deleted project directory
sudo cp -a /home/.snapshots/555/snapshot/drew/Projects/myproject /home/drew/Projects/myproject
sudo chown -R drew:drew /home/drew/Projects/myproject
```

See Section 12 for detailed file/directory restoration examples.

---

### Manual cleanup (forces cleanup according to config rules):

```bash
sudo snapper cleanup number        # Clean up by snapshot number limits
sudo snapper cleanup timeline      # Clean up old timeline snapshots
sudo snapper -c home cleanup timeline  # Clean up home config
```

---

## 9. Managing snapper timers and services

### Check timer status

```bash
systemctl status snapper-timeline.timer   # Check snapshot creation timer
systemctl status snapper-cleanup.timer    # Check cleanup timer
systemctl list-timers | grep snapper      # See when timers will next run
```

### Stop timers temporarily

Useful for troubleshooting or when doing intensive disk operations:

```bash
sudo systemctl stop snapper-timeline.timer
sudo systemctl stop snapper-cleanup.timer
```

### Start timers

```bash
sudo systemctl start snapper-timeline.timer
sudo systemctl start snapper-cleanup.timer
```

### Disable/Enable timers permanently

```bash
# Disable (prevents automatic start on boot)
sudo systemctl disable snapper-timeline.timer
sudo systemctl disable snapper-cleanup.timer

# Enable (starts automatically on boot)
sudo systemctl enable snapper-timeline.timer
sudo systemctl enable snapper-cleanup.timer

# Enable and start immediately
sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer
```

### When to stop/disable timers

- **During disk-intensive operations** - Prevent snapshots during large data migrations
- **Low disk space emergencies** - Stop creating new snapshots until you clean up
- **Troubleshooting** - Isolate snapper from other disk issues
- **Temporary installations** - Don't need snapshots on a live USB or test system

---

## 10. Optional: GRUB integration for boot-time recovery

GRUB integration adds menu entries to boot directly into read-only snapshots without modifying your system.

### Install grub-btrfs

```bash
sudo dnf copr enable sentry/grub-btrfs
sudo dnf install grub-btrfs
sudo systemctl enable --now grub-btrfs.path
```

### How to use

1. **Reboot your system**
2. **At the GRUB menu**, you'll see a new entry: "Fedora Linux snapshots"
3. **Select it** to see a list of all available snapshots
4. **Choose a snapshot** to boot into that state (read-only)
5. **Inspect the system** - verify if the snapshot has what you need
6. **Make it permanent** (if desired):
   ```bash
   sudo snapper rollback <snapshot-ID>
   sudo reboot
   ```

### When to use GRUB boot vs rollback

- **GRUB boot into snapshot** (read-only, temporary)
  - Test if a snapshot has the fix you need
  - Boot a broken system to diagnose issues
  - No changes made to your actual system
  - Reboot normally to return to current state

- **Snapper rollback** (read-write, permanent)
  - Commit to restoring to a previous state
  - System becomes that snapshot after reboot
  - Use when you know the snapshot is good

**Best practice:** Boot into the snapshot via GRUB first, verify it's what you need, then rollback if satisfied.

---

## 11. Check status and space usage

### Quick status check

```bash
sudo snapper list              # List root snapshots
sudo snapper -c home list      # List home snapshots
sudo snapper list-configs      # Show all configs
sudo snapper get-config        # View root config settings
sudo snapper -c home get-config # View home config settings
```

### Check overall disk space

```bash
df -h /                        # Quick overview
sudo btrfs filesystem usage /  # Detailed btrfs usage (recommended)
```

**Important:** `btrfs filesystem usage` shows **actual** disk space used. The `du` command will report misleading totals because it counts shared blocks multiple times:

```bash
sudo du -sh /.snapshots        # Shows 99G (misleading - counts shared data)
# vs
sudo btrfs filesystem usage /  # Shows 121G total (actual usage)
```

Most snapshot data is **shared** via copy-on-write, so snapshots consume much less space than `du` suggests.

### Per-snapshot space (requires quotas enabled)

```bash
sudo btrfs qgroup show /       # Shows exclusive space per snapshot
```

Without quotas, you can estimate overhead:
**Snapshot overhead ≈ Total used - (Root size + Home size)**

---

## 12. Restoring files from snapshots

Snapshots are read-only and live in `.snapshots/` directories.

### Browse a snapshot

```bash
ls /.snapshots/3/snapshot/                    # Browse root snapshot #3
ls /home/.snapshots/2/snapshot/drew/Projects  # Browse home snapshot #2
```

### Restore a single file

```bash
# Restore a file from root snapshot
sudo cp /.snapshots/3/snapshot/etc/fstab /etc/fstab

# Restore a file from home snapshot
sudo cp /home/.snapshots/2/snapshot/drew/important-file.txt /home/drew/
sudo chown drew:drew /home/drew/important-file.txt  # Fix ownership
```

### Restore a directory

```bash
# Restore entire directory from home snapshot
sudo cp -a /home/.snapshots/2/snapshot/drew/Projects/myproject /home/drew/Projects/myproject-recovered
sudo chown -R drew:drew /home/drew/Projects/myproject-recovered
```

### Compare current vs snapshot

```bash
diff /home/drew/.bashrc /home/.snapshots/3/snapshot/drew/.bashrc
diff -r /home/drew/mydir /home/.snapshots/3/snapshot/drew/mydir
```

### Use cases for /home snapshots

- **Accidental deletion** - Deleted your work directory? Restore it
- **Bad config changes** - Messed up dotfiles? Roll back
- **File corruption** - Document corrupted? Grab yesterday's version
- **Undo bulk changes** - Script modified lots of files? Revert them

** Important:** Snapshots protect against user error and corruption, but **NOT hardware failure**. If your drive dies, snapshots die with it. Use external backups (rsync, cloud) for disaster recovery.

---

## 13. GUI management (optional)

Launch graphical tools:

```bash
btrfs-assistant
```

You can browse, compare, and delete snapshots visually.

---

## 14. Summary and best practices

### Default config settings provide good protection

Your snapper configs include built-in safety limits:
- `SPACE_LIMIT = 0.5` - Snapshots limited to 50% of disk
- `FREE_LIMIT = 0.2` - Stops creating snapshots if <20% free
- `NUMBER_LIMIT = 50` - Maximum 50 snapshots
- Retention: 8 hourly, 7 daily, 4 weekly, 3 monthly

These prevent runaway space usage even without quotas enabled.

### When to check on things

Periodically review your setup:

```bash
df -h /                          # Quick space check
sudo btrfs filesystem usage /    # Detailed usage
sudo snapper list                # Recent snapshots
```

If disk gets >70% full, consider deleting older snapshots or enabling quotas to identify which ones use the most exclusive space.

### Two configs explained

- **root config** - Backs up `/` (system files, configs in `/etc`, etc.)
- **home config** - Backs up `/home` (your user data, dotfiles, projects)

Both are valuable even on the same drive - they protect against different types of user errors.

---

## Notes

* Snapshots live in `.snapshots/` within each subvolume.
* Snapshots are copy-on-write and initially take almost no space.
* Space grows only as files change after snapshot creation.
* Cleanups are handled automatically by `snapper-cleanup.timer`.
