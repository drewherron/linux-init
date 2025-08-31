#!/usr/bin/env bash

# Get the script directory to locate external_packages.txt
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."

install_packages() {
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
        sudo dnf install -y $PACKAGES
    fi

    # Clean up unwanted packages after installation
    cleanup_unwanted

    # Install external packages
    install_external_packages
}

cleanup_unwanted() {
    echo "Removing unwanted packages..."

    # Build list of installed unwanted packages in one query
    local to_remove=()
    local unwanted_packages=(
        "firefox"
        "gnome-shell"
        "gnome-session"
        "mutter"
        "orca"
        "brltty"
    )

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

    # Source and run the external install script
    echo "Running external package installation..."
    source "$external_script"
    run_external_installations
}
