# Linux Init Script

A script that takes a basic install of Fedora Linux and fully configures and customizes it the way I like it.

Here's how I use it:

1. Install Fedora using the netinstall ISO, choose 'Basic Desktop' with no additional software selected. Personally, I encrypt my disk (the LUKS screen is one of the things customized by this script)
2. Clone this script to the new home directory
3. Add (by thumb drive from other computer or backup) `.ssh` and `.gnupg` to the `secrets` directory, and `.fonts` to the script directory
4. Run the script, entering `y` at every prompt (and user/sudo password where necessary)

That's it. I've tested it, and every step works for me.

This is for my personal use, but I tried to make it a bit more generalizable and customizable for anyone else who may want to use it. You might find some good use for the code with just a few edits. It does clone my own repos where necessary (building dwm, stowing dotfiles).

## What It Does

1. **Keys**: Copies SSH/GPG keys from `secrets/` directories
2. **Directories**: Creates standard folders (bin, .config, Documents, etc.)
3. **System**: Updates system packages via dnf
4. **Display Manager**: Installs and configures LightDM
5. **LUKS**: Adds custom background to unlock screen at boot
5. **Packages**: Installs development tools, removes unwanted packages
6. **Window Manager**: Clones and builds my versions of dwm, st, dmenu
7. **xinitrc**: Configures dwm session for display managers
8. **Dotfiles**: Uses GNU Stow to manage configurations
9. **Shell**: Sets zsh as default shell
10. **Keyboard**: Sets up KMonad configuration
11. **Repositories**: Clones configured repositories to specified locations

Nearly all of these (all except updating packages) have a confirmation beforehand so you can choose at runtime what you actually want to include. Unless you use Colemak-DH, you'll probably want to skip the keyboard setup with kmonad, although I'll be changing that soon too.
