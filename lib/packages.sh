#!/usr/bin/env bash

# Get the script directory to locate external_packages.txt
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."

install_packages() {
    echo ""
    read -p "Install packages from packages.txt? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping package installation."
        return
    fi

    local PKG_FILE="packages.txt"

    # Ensure we have the package file
    if [[ ! -f "$PKG_FILE" ]]; then
        echo "Error: $PKG_FILE not found in the current directory."
        echo "Please make sure the file exists and try again."
        exit 1
    fi

    echo "Installing packages from $PKG_FILE ..."
    # Read all non-empty, non-commented lines into a variable
    PACKAGES=$(grep -vE '^\s*#' "$PKG_FILE" | grep -vE '^\s*$')

    if [[ -z "$PACKAGES" ]]; then
        echo "No packages to install. Please check $PKG_FILE."
    else
        # Install them
        sudo dnf install -y --skip-unavailable $PACKAGES
    fi

    # Clean up unwanted packages after installation
    cleanup_unwanted

    # Install external packages
    install_external_packages
}

cleanup_unwanted() {
    local unwanted_file="$SCRIPT_DIR/unwanted_packages.txt"

    # Check if unwanted packages file exists
    if [ ! -f "$unwanted_file" ]; then
        echo "No unwanted_packages.txt found. Skipping package cleanup."
        echo "Create $unwanted_file with packages you want removed (see unwanted_packages.example.txt)"
        return
    fi

    echo ""
    read -p "Remove unwanted packages? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping package cleanup."
        return
    fi

    echo "Removing unwanted packages..."

    # Read unwanted packages from file, skipping empty lines and comments
    local unwanted_packages=()
    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        unwanted_packages+=("$line")
    done < "$unwanted_file"

    # Check if we have any packages to remove
    if [ ${#unwanted_packages[@]} -eq 0 ]; then
        echo "No packages found in $unwanted_file. Skipping package cleanup."
        return
    fi

    # Build list of installed unwanted packages in one query
    local to_remove=()
    for package in "${unwanted_packages[@]}"; do
        if rpm -qa | grep -q "^$package"; then
            to_remove+=("$package")
        fi
    done

    # Remove all at once if any found
    if [ ${#to_remove[@]} -gt 0 ]; then
        echo "The following packages will be removed: ${to_remove[*]}"
        read -p "Do you want to proceed with their removal? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Removing packages..."
            sudo dnf remove -y "${to_remove[@]}"
        else
            echo "Skipping removal of unwanted packages."
        fi
    else
        echo "None of the unwanted packages are currently installed."
    fi

    echo "✓ Cleanup completed"
}

install_external_packages() {
    local external_script="$SCRIPT_DIR/external_install.sh"

    # Check if external install script exists
    if [ ! -f "$external_script" ]; then
        echo "No external_install.sh found. Skipping external package installation."
        echo "Create $external_script with your external packages (see external_install.example.sh)"
        return
    fi

    echo ""
    read -p "Install external packages? This runs custom installation scripts. (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping external package installation."
        return
    fi

    # Source and run the external install script
    echo "Running external package installation..."
    source "$external_script"
    setup_external_packages
}
