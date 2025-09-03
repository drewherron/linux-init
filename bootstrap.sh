#!/usr/bin/env bash
#
# bootstrap.sh
# Minimal bootstrap script for fresh Fedora installs
# Set up networking, installs git, clones the main setup repo
#
# CONFIGURE THESE VARIABLES:

# Network Configuration
WIFI_SSID=""                    # Leave empty if using ethernet
WIFI_PASSWORD=""                # WiFi password
USE_DHCP=true                   # Set to false for static IP

# Static IP Configuration (only used if USE_DHCP=false)
STATIC_IP=""                    # e.g., "192.168.1.100/24"
GATEWAY=""                      # e.g., "192.168.1.1"
DNS_SERVERS="8.8.8.8,8.8.4.4" # Comma-separated DNS servers

# Repository Configuration
REPO_URL="git@github.com:drewherron/linux-init.git"
REPO_DIR="$HOME/linux-init"

#############################################################################
# DO NOT EDIT BELOW THIS LINE
#############################################################################

set -e

setup_network() {
    echo "Setting up network connection..."

    if [ -n "$WIFI_SSID" ]; then
        echo "Configuring WiFi: $WIFI_SSID"
        if [ -n "$WIFI_PASSWORD" ]; then
            nmcli device wifi connect "$WIFI_SSID" password "$WIFI_PASSWORD"
        else
            nmcli device wifi connect "$WIFI_SSID"
        fi
    fi

    if [ "$USE_DHCP" = false ] && [ -n "$STATIC_IP" ]; then
        echo "Configuring static IP: $STATIC_IP"
        CONNECTION=$(nmcli -t -f NAME connection show --active | head -n1)
        nmcli connection modify "$CONNECTION" ipv4.addresses "$STATIC_IP"
        nmcli connection modify "$CONNECTION" ipv4.gateway "$GATEWAY"
        nmcli connection modify "$CONNECTION" ipv4.dns "$DNS_SERVERS"
        nmcli connection modify "$CONNECTION" ipv4.method manual
        nmcli connection up "$CONNECTION"
    fi

    # Test connectivity
    echo "Testing network connectivity..."
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo "✓ Network connectivity established"
    else
        echo "✗ Network connectivity failed"
        exit 1
    fi
}

install_essentials() {
    echo "Installing essential packages..."
    sudo dnf update -y
    sudo dnf install -y git curl wget
}

clone_repo() {
    echo "Cloning setup repository..."
    if [ -d "$REPO_DIR" ]; then
        echo "Repository already exists at $REPO_DIR"
        cd "$REPO_DIR"
        git pull
    else
        git clone "$REPO_URL" "$REPO_DIR"
        cd "$REPO_DIR"
    fi
}

run_main_setup() {
    echo "Starting main setup script..."
    chmod +x setup.sh
    ./setup.sh
}

main() {
    echo "Starting Fedora bootstrap setup..."

    # Only setup network if variables are configured
    if [ -n "$WIFI_SSID" ] || [ "$USE_DHCP" = false ]; then
        setup_network
    else
        echo "No network configuration specified, assuming network is already working..."
    fi

    install_essentials
    clone_repo

    # Ask user if they want to run the main setup script
    echo ""
    read -p "Run the main setup script now? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        run_main_setup
        echo "Bootstrap completed successfully!"
    else
        echo "Bootstrap completed. Run './setup.sh' manually when ready."
    fi
}

# Check if running as root (shouldn't be)
if [ "$EUID" -eq 0 ]; then
    echo "Error: Do not run this script as root"
    exit 1
fi

main "$@"
