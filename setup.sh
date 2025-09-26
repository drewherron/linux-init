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

main() {
    echo "Starting Fedora post-install setup..."

    setup_keys
    make_directories
    update_system
    install_packages
    setup_flatpak
    setup_repos
    setup_xinitrc
    setup_trackpad
    setup_dotfiles
    setup_zsh
    setup_fonts
    setup_lightdm
    setup_plymouth
    setup_keyboard

    echo "Post-install script completed successfully!"
}

main "$@"
