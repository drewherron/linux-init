# Linux Init Script

A modular post-install script for Fedora that sets up a complete development environment from a minimal install.

## Target Installation

- **Fedora Workstation** (standard netinstall)
- Removes unwanted packages
- Installs dwm + development tools + personal configurations

This is for my personal use, but I tried to make it a bit more generalizable and customizable for anyone else who may want to use it. I left my personal project repos out of it, and left the list of packages to be customized by you. But it does still use my dotfiles repo for configurations. Again, you can change that too. If you run this, you should end up with my simple dwm setup using my custom theme.

## Prerequisites

1. **Copy your SSH and GPG directories** to the `secrets/` folder:
```bash
cp -r ~/.ssh secrets/
cp -r ~/.gnupg secrets/
```

2. **Configure repositories** (optional):
```bash
cp repos.example.txt repos.txt
# Edit repos.txt with your repository destinations and URLs
```

3. **Configure unwanted packages** (optional):
```bash
cp unwanted_packages.example.txt unwanted_packages.txt
# Edit unwanted_packages.txt with packages to remove
```


## Usage

1. Clone this repository to your new Fedora system
2. Copy your keys to `secrets/` directory (see above)
3. Edit `packages.txt` and `lib/*.sh` files to match your preferences
4. Run the setup:

```bash
chmod +x setup.sh
./setup.sh
```

## What It Does

1. **Keys**: Copies SSH/GPG keys from `secrets/` directories
2. **Directories**: Creates standard folders (bin, config, Documents, etc.)
3. **System**: Updates system packages via dnf
4. **Display Manager**: Optionally installs and configures LightDM
5. **Packages**: Installs development tools, removes unwanted packages
6. **Window Manager**: Clones and builds dwm, st, dmenu from GitHub
7. **xinitrc**: Configures dwm session for display managers
8. **Dotfiles**: Uses GNU Stow to manage configurations (with backup)
9. **Shell**: Optionally sets zsh as default shell
10. **Keyboard**: Optionally sets up KMonad configuration
11. **Repositories**: Clones configured repositories to specified locations

