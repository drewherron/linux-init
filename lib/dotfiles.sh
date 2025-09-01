#!/usr/bin/env bash

GITHUB_USER="drewherron"

setup_dotfiles() {
    echo ""
    read -p "Clone and set up dotfiles from GitHub? This uses my personal configurations. (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping dotfiles setup."
        return
    fi

    echo "Cloning dotfiles repository..."
    cd ~
    if [ ! -d "dotfiles" ]; then
        git clone git@github.com:$GITHUB_USER/dotfiles.git
    fi

    cd ~/dotfiles

    echo ""
    read -p "Stow dotfiles now? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
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
            "zsh"
            "syncthing"
            "lightline"
        )

        # Directories that need --no-folding --override (for absolute symlinks)
        local no_folding_override_dirs=(
            "vim"
            "emacs"
        )

        # Create backup directory for existing files
        local backup_dir="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

        # Stow each dotfile, backing up conflicts
        for dir in "${dotfiles_to_stow[@]}"; do
            if [ -d "$dir" ]; then
                echo "Processing $dir..."

                # Get list of files that would be created by stow
                files_to_stow=$(stow -n "$dir" 2>&1 | grep 'LINK: ' | sed 's/LINK: //; s/ => .*//')

                for file in $files_to_stow; do
                    local target_path="$HOME/$file"
                    # If target exists and is not already a symlink, back it up
                    if [ -e "$target_path" ] && [ ! -L "$target_path" ]; then
                        echo "Backing up existing $file..."
                        # Ensure backup directory exists
                        if [ ! -d "$backup_dir" ]; then
                            mkdir -p "$backup_dir"
                        fi
                        # Preserve directory structure in backup
                        mkdir -p "$backup_dir/$(dirname "$file")"
                        mv "$target_path" "$backup_dir/$file"
                    fi
                done

                echo "Stowing $dir..."
                if [[ " ${no_folding_override_dirs[*]} " =~ " $dir " ]]; then
                    stow --no-folding --override "$dir"
                elif [[ " ${no_folding_dirs[*]} " =~ " $dir " ]]; then
                    stow --no-folding "$dir"
                else
                    stow "$dir"
                fi
            fi
        done

        if [ -d "$backup_dir" ]; then
            echo "✓ Original files backed up to: $backup_dir"
        fi
    else
        echo "Skipping dotfiles stow. You can run it manually later."
    fi

    # Copy specific scripts to ~/.local/bin/
    if [ -f "scripts/dmenu_run_history" ]; then
        echo "Copying dmenu_run_history to ~/.local/bin/..."
        cp scripts/dmenu_run_history "$HOME/.local/bin/"
        chmod +x "$HOME/.local/bin/dmenu_run_history"
    fi

    # Special handling for lightdm (stow + run script)
    if command -v lightdm &> /dev/null; then
        if [ -d "lightdm" ] && [ ! -e "$HOME/.lightdm" ]; then
            echo "Setting up lightdm..."
            stow lightdm
            cd lightdm/greeter
            ./update_lightdm.sh
            cd ../..
        fi
    fi
}
