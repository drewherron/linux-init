#!/usr/bin/env bash

GITHUB_USER="drewherron"

setup_dotfiles() {
    echo "Cloning dotfiles repository..."
    cd ~
    if [ ! -d "dotfiles" ]; then
        git clone git@github.com:$GITHUB_USER/dotfiles.git
    fi

    cd ~/dotfiles

    # List of dotfiles directories to stow
    local dotfiles_to_stow=(
        "bash"
        "bin"
        "dwm"
        "face"
        "git"
        "lf"
        "lightline"
        "mpv"
        "profile"
        "screenlayout"
        "syncthing"
        "vim"
        "wallpaper"
        "xdefaults"
        "xresources"
        "zathura"
        "zsh"
    )

    # Directories that need --no-folding
    local no_folding_dirs=(
        "dwm"
        "lf"
        "vim"
        "zsh"
        "syncthing"
        "lightline"
    )

    # Create backup directory for existing files
    local backup_dir="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

    # Stow each dotfile, backing up conflicts
    for dir in "${dotfiles_to_stow[@]}"; do
        if [ -d "$dir" ]; then
            echo "Processing $dir..."

            # Find all files and directories that would be created by this stow directory
            # and backup any existing ones that aren't already symlinks
            while IFS= read -r -d '' item; do
                local relative_path="${item#$dir/}"
                local target_path="$HOME/$relative_path"
                if [ -e "$target_path" ] && [ ! -L "$target_path" ]; then
                    echo "Backing up existing $relative_path..."
                    # Ensure the parent directory in the backup location exists
                    mkdir -p "$backup_dir/$(dirname "$relative_path")"
                    # Move the file or directory to the backup location
                    mv "$target_path" "$backup_dir/$relative_path"
                fi
            done < <(find "$dir" -mindepth 1 -print0)

            echo "Stowing $dir..."
            if [[ " ${no_folding_dirs[*]} " =~ " $dir " ]]; then
                stow --no-folding "$dir"
            else
                stow "$dir"
            fi
        fi
    done

    if [ -d "$backup_dir" ]; then
        echo "✓ Original files backed up to: $backup_dir"
    fi

    # Copy specific scripts to ~/.local/bin/
    if [ -f "scripts/dmenu_run_history" ]; then
        echo "Copying dmenu_run_history to ~/.local/bin/..."
        cp scripts/dmenu_run_history "$HOME/.local/bin/"
        chmod +x "$HOME/.local/bin/dmenu_run_history"
    fi

    # Special handling for lightdm (stow + run script)
    if [ -d "lightdm" ] && [ ! -e "$HOME/.lightdm" ]; then
        echo "Setting up lightdm..."
        stow lightdm
        cd lightdm/greeter
        ./update_lightdm.sh
        cd ../..
    fi
}
