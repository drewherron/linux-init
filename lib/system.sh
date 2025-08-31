#!/usr/bin/env bash

# Get the script directory to locate secrets
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."

update_system() {
    echo "Updating and upgrading the system..."
    sudo dnf update -y
}

setup_keys() {
    echo "Setting up SSH and GPG keys..."

    # Check if secrets directory exists
    if [ ! -d "$SCRIPT_DIR/secrets" ]; then
        echo "Error: secrets/ directory not found!"
        echo "Please copy your .ssh and .gnupg directories to secrets/ before running setup."
        echo "Expected: secrets/.ssh/ and secrets/.gnupg/"
        exit 1
    fi

    # Copy SSH keys if directory exists
    if [ -d "$SCRIPT_DIR/secrets/.ssh" ]; then
        echo "Copying SSH configuration..."
        cp -r "$SCRIPT_DIR/secrets/.ssh" "$HOME/"
        chmod 700 "$HOME/.ssh"
        chmod 600 "$HOME/.ssh/"*

        # Start ssh-agent if not already running and add keys
        if ! pgrep -u "$USER" ssh-agent > /dev/null; then
            eval "$(ssh-agent -s)"
        else
            # If agent is running, ensure the environment variables are set
            # This is a simple approach; a more robust solution might involve sourcing a shared env file
            export SSH_AUTH_SOCK=$(find /tmp/ssh-*/agent.* -user "$USER" -type s 2>/dev/null | head -n 1)
        fi

        for key in "$HOME/.ssh/id_"*; do
            if [ -f "$key" ] && [ ! "${key##*.}" = "pub" ]; then
                ssh-add "$key" 2>/dev/null || true
            fi
        done

        # Test GitHub connection
        echo "Testing GitHub SSH connection..."
        if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
            echo "✓ GitHub SSH authentication successful!"
        else
            echo "Warning: GitHub SSH test failed. You may need to add your public key to GitHub."
            echo "Your public key(s):"
            for pubkey in "$HOME/.ssh/"*.pub; do
                if [ -f "$pubkey" ]; then
                    echo "--- $pubkey ---"
                    cat "$pubkey"
                fi
            done
            echo ""
            echo "Add your key(s) to your GitHub account at: https://github.com/settings/keys"
        fi
    else
        echo "Warning: No SSH keys found in secrets/.ssh/"
    fi

    # Copy GPG keys if directory exists
    if [ -d "$SCRIPT_DIR/secrets/.gnupg" ]; then
        echo "Copying GPG configuration..."
        sudo cp -r "$SCRIPT_DIR/secrets/.gnupg" "$HOME/"
	sudo chown -R "$USER:$USER" "$HOME/.gnupg"
	find "$HOME/.gnupg" -type f -exec chmod 600 {} \; 2>/dev/null || true
	find "$HOME/.gnupg" -type d -exec chmod 700 {} \; 2>/dev/null || true
        echo "✓ GPG keys copied"
    else
        echo "No GPG keys found in secrets/.gnupg/ (optional)"
    fi
}

make_directories() {
    echo "Creating directories..."

    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/.local/bin"
    mkdir -p "$HOME/bin"
    mkdir -p "$HOME/Documents"
    mkdir -p "$HOME/Downloads"
    mkdir -p "$HOME/Music"
    mkdir -p "$HOME/Pictures"
    mkdir -p "$HOME/Sync"
    mkdir -p "$HOME/Videos"

    echo "✓ Directories created"
}

setup_xinitrc() {
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
}
