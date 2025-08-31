#!/usr/bin/env bash
#
# setup.sh
# A post-install script for Fedora to install packages,
# clone & build repos, and set up dotfiles.
#
# Target Installation:
# - Fedora Workstation
# - No additional software groups selected on install

set -e

# Get the script directory to properly source modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all modules
source "$SCRIPT_DIR/lib/system.sh"
source "$SCRIPT_DIR/lib/packages.sh"
source "$SCRIPT_DIR/lib/repos.sh"
source "$SCRIPT_DIR/lib/dotfiles.sh"

setup_keyboard() {
    echo ""
    read -p "Set up KMonad keyboard configuration? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -d "$HOME/Projects/keyboard" ]; then
            echo "Setting up KMonad keyboard configuration..."
            cd "$HOME/Projects/keyboard"
            if [ -f "kmonad-setup.sh" ]; then
                chmod +x kmonad-setup.sh
                ./kmonad-setup.sh
            else
                echo "Warning: kmonad-setup.sh not found in keyboard repository"
            fi
        else
            echo "Warning: ~/Projects/keyboard not found. Skipping keyboard setup."
        fi
    else
        echo "Skipping keyboard setup."
    fi
}

main() {
    echo "Starting Fedora post-install setup..."

    setup_keys
    make_directories
    update_system
    install_packages
    setup_repos
    setup_xinitrc
    setup_dotfiles
    setup_keyboard

    echo "Post-install script completed successfully!"
}

main "$@"
