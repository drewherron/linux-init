#!/usr/bin/env bash
#
# external_install.example.sh - EXAMPLE FILE
# Copy this to external_install.sh and customize with your external packages
# For packages not available in standard repositories

run_external_installations() {
    echo "Installing external packages..."

    # Add your own external packages here

    # Pattern 1: Install via shell script
    # if ! command -v your_program &> /dev/null; then
    #     echo "Installing your_program..."
    #     sh <(wget -qO - https://example.com/install.sh)
    #     echo "✓ your_program installed"
    # else
    #     echo "your_program already installed, skipping..."
    # fi

    # Pattern 2: Add external repository and install packages
    # if ! dnf repolist | grep -q your_repo; then
    #     echo "Adding your_repo repository..."
    #     sudo dnf config-manager --add-repo https://example.com/repo.repo
    #     sudo rpm --import https://example.com/gpg-key.pub  # Optional
    # fi
    #
    # Install packages from external repos
    # local external_packages=(
    #     "package1"
    #     "package2"
    # )
    #
    # for package in "${external_packages[@]}"; do
    #     if ! rpm -qa | grep -q "^$package"; then
    #         echo "Installing $package..."
    #         sudo dnf install -y "$package" || echo "Warning: Failed to install $package"
    #     else
    #         echo "$package already installed, skipping..."
    #     fi
    # done

    echo "✓ External packages installation completed"
}
