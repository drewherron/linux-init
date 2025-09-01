#!/usr/bin/env bash
#
# install_dwm.sh
# Standalone script to install and set up dwm window manager
# This script will:
# - Clone and build window manager tools (dwm, st, dmenu, slstatus)
# - Set up xinitrc and desktop session files
# - Clone dotfiles repo and stow dwm configuration
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITHUB_USER="drewherron"

echo "Starting dwm installation and setup..."

# Clone and build window manager tools
echo "Cloning and building WM tools..."
mkdir -p ~/src
cd ~/src

wm_repos=("dwm" "st" "dmenu" "slstatus")

for repo in "${wm_repos[@]}"; do
    if [ ! -d "$repo" ]; then
        echo "Cloning $repo..."
        git clone "git@github.com:$GITHUB_USER/$repo.git"
    fi
    cd "$repo"
    echo "Building and installing $repo..."
    sudo make clean install
    cd ..
done

# Set up xinitrc and desktop session
echo "Configuring dwm as the default window manager..."

# Create xinitrc for startx
if [ ! -f "$HOME/.xinitrc" ]; then
    echo "exec dwm" > "$HOME/.xinitrc"
    chmod +x "$HOME/.xinitrc"
fi

# Create desktop session file for dwm
if [ ! -f "/usr/share/xsessions/dwm.desktop" ]; then
    echo "Creating dwm session file for display managers..."
    sudo tee /usr/share/xsessions/dwm.desktop > /dev/null << 'EOF'
[Desktop Entry]
Encoding=UTF-8
Name=dwm
Comment=Dynamic window manager
Exec=dwm
Icon=dwm
Type=XSession
EOF
fi

# Clone dotfiles if needed and stow dwm config
echo "Setting up dotfiles..."
cd ~
if [ ! -d "dotfiles" ]; then
    echo "Cloning dotfiles repository..."
    git clone git@github.com:$GITHUB_USER/dotfiles.git
fi

cd ~/dotfiles

if [ -d "dwm" ]; then
    echo "Stowing dwm configuration..."
    stow --no-folding dwm
    echo "✓ dwm dotfiles stowed"
else
    echo "Warning: dwm directory not found in dotfiles repository"
fi

echo "✓ dwm installation and setup completed!"
echo ""
echo "You can now:"
echo "- Use 'startx' to start dwm from a TTY"
echo "- Select 'dwm' from your display manager login screen"