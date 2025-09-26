#!/usr/bin/env bash

# Get the script directory to locate secrets
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."

update_system() {
    echo "Updating and upgrading the system..."
    sudo dnf update -y
}

setup_keys() {
    echo ""
    read -p "Set up SSH and GPG keys? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping SSH and GPG key setup."
        return
    fi

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

    # Copy SECRETS file if it exists
    if [ -f "$SCRIPT_DIR/secrets/SECRETS" ]; then
        echo "Copying SECRETS file..."
        cp "$SCRIPT_DIR/secrets/SECRETS" "$HOME/"
        chmod 600 "$HOME/SECRETS"
        echo "✓ SECRETS file copied"
    else
        echo "No SECRETS file found in secrets/ (optional)"
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
    echo ""
    read -p "Configure dwm as the default window manager? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping dwm configuration."
        return
    fi

    echo "Configuring dwm as the default window manager..."

    # Create xinitrc for startx
#    if [ ! -f "$HOME/.xinitrc" ]; then
#        echo "exec dwm" > "$HOME/.xinitrc"
#        chmod +x "$HOME/.xinitrc"
#    fi

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

setup_zsh() {
    echo ""
    read -p "Set zsh as the default shell? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping zsh setup."
        return
    fi

    echo "Setting zsh as default shell..."

    # Check if zsh is installed
    if ! command -v zsh &> /dev/null; then
        echo "Error: zsh is not installed. Install packages first."
        return 1
    fi

    # Get the path to zsh
    local zsh_path=$(command -v zsh)

    if [[ -z "$zsh_path" ]]; then
        echo "Error: Could not find zsh path"
        return 1
    fi

    # Check if zsh is already the default shell
    if [[ "$SHELL" == "$zsh_path" ]]; then
        echo "zsh is already the default shell."
        return
    fi

    # Ensure zsh is in /etc/shells
    if ! grep -qx "$zsh_path" /etc/shells; then
        echo "Adding zsh to /etc/shells..."
        echo "$zsh_path" | sudo tee -a /etc/shells
    fi

    # Change shell to zsh
    echo "Changing shell to zsh..."
    if chsh -s "$zsh_path"; then
        echo "✓ Default shell set to zsh"
        echo "Note: You'll need to log out and back in for the change to take effect."
    else
        echo "Error: Failed to change shell to zsh. You may need to run 'chsh -s $zsh_path' manually."
        return 1
    fi
}

setup_fonts() {
    local fonts_dir="$SCRIPT_DIR/.fonts"
    
    # Check if fonts directory exists
    if [ ! -d "$fonts_dir" ]; then
        echo "No .fonts directory found. Skipping font installation."
        return
    fi
    
    echo ""
    read -p "Install fonts from .fonts directory? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping font installation."
        return
    fi
    
    echo "Installing fonts..."
    
    # Create user fonts directory if it doesn't exist
    mkdir -p "$HOME/.fonts"
    
    # Copy fonts from script directory to user fonts directory
    cp -r "$fonts_dir"/* "$HOME/.fonts/" 2>/dev/null
    
    # Update font cache
    fc-cache -f "$HOME/.fonts"
    
    echo "✓ Fonts installed and cache updated"
}

setup_lightdm() {
    echo ""
    read -p "Install and set LightDM as the default display manager? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping LightDM setup."
        return
    fi

    echo "Installing and configuring LightDM..."

    # Clean up any previous incomplete setup
    echo "Cleaning up previous LightDM configuration..."
    sudo rm -f /usr/share/backgrounds/shotei-takahashi-starlight.night.jpg
    sudo rm -f /usr/share/pixmaps/user-face.png

    # Install LightDM and a greeter
    sudo dnf install -y lightdm lightdm-gtk-greeter

    # Disable current display manager (likely GDM)
    echo "Disabling current display manager..."
    sudo systemctl disable gdm.service 2>/dev/null || true

    # Enable LightDM
    echo "Enabling LightDM as default display manager..."
    sudo systemctl enable lightdm.service

    # Ensure GTK greeter is configured
    sudo sed -i 's/#greeter-session=.*/greeter-session=lightdm-gtk-greeter/' /etc/lightdm/lightdm.conf

    # Copy assets and link configuration if dotfiles repo is available
    local greeter_config="$HOME/dotfiles/lightdm/greeter/lightdm-gtk-greeter.conf"
    local wallpaper_source="$HOME/Pictures/gallery/wallpaper/other/shotei-takahashi-starlight.night.jpg"
    
    # Copy wallpaper and user image to system-accessible locations
    if [ -f "$wallpaper_source" ]; then
        echo "Copying LightDM wallpaper to system directory..."
        sudo cp "$wallpaper_source" /usr/share/backgrounds/
        echo "✓ LightDM wallpaper copied"
    fi
    
    if [ -f "$HOME/.face" ]; then
        echo "Copying user face image to system directory..."
        sudo cp "$HOME/.face" /usr/share/pixmaps/user-face.png
        echo "✓ LightDM user image copied"
    fi
    
    if [ -f "$greeter_config" ]; then
        echo "Copying custom LightDM greeter configuration..."
        sudo cp "$greeter_config" /etc/lightdm/lightdm-gtk-greeter.conf
        echo "✓ Custom LightDM greeter configuration copied"
    else
        echo "Note: Custom LightDM greeter config not found (will use defaults)"
    fi

    echo "✓ LightDM installed and set as default display manager"
    echo "Note: LightDM will be active after the next reboot."
}

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
                
                # Enable and start kmonad systemd user services if they exist
                if [ -d "$HOME/.config/systemd/user" ]; then
                    echo "Checking for kmonad systemd services..."
                    for service_file in "$HOME/.config/systemd/user"/*kmonad*.service; do
                        if [ -f "$service_file" ]; then
                            local service_name=$(basename "$service_file")
                            echo "Enabling and starting $service_name..."
                            systemctl --user daemon-reload
                            systemctl --user enable "$service_name"
                            systemctl --user start "$service_name"
                            echo "✓ $service_name enabled and started"
                        fi
                    done
                fi
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


setup_trackpad() {
    echo ""
    read -p "Configure trackpad with natural scrolling and tap-to-click? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping trackpad configuration."
        return
    fi

    echo "Configuring trackpad with natural scrolling and tap-to-click..."

    # Install xinput if not already installed
    if ! command -v xinput &> /dev/null; then
        echo "Installing xinput..."
        sudo dnf install -y xinput
    fi

    # Create permanent libinput configuration for natural scrolling
    local libinput_conf="/etc/X11/xorg.conf.d/40-libinput.conf"
    
    if [ ! -f "$libinput_conf" ]; then
        echo "Creating libinput configuration file..."
        sudo tee "$libinput_conf" > /dev/null << 'EOF'
# Match on all types of devices but tablet devices and joysticks
Section "InputClass"
        Identifier "libinput pointer catchall"
        MatchIsPointer "on"
        MatchDevicePath "/dev/input/event*"
        Driver "libinput"
EndSection

Section "InputClass"
        Identifier "libinput keyboard catchall"
        MatchIsKeyboard "on"
        MatchDevicePath "/dev/input/event*"
        Driver "libinput"
EndSection

Section "InputClass"
        Identifier "libinput touchpad catchall"
        MatchIsTouchpad "on"
        MatchDevicePath "/dev/input/event*"
        Driver "libinput"
        Option "NaturalScrolling" "true"
        Option "Tapping" "true"
EndSection

Section "InputClass"
        Identifier "libinput touchscreen catchall"
        MatchIsTouchscreen "on"
        MatchDevicePath "/dev/input/event*"
        Driver "libinput"
EndSection

Section "InputClass"
        Identifier "libinput tablet catchall"
        MatchIsTablet "on"
        MatchDevicePath "/dev/input/event*"
        Driver "libinput"
EndSection
EOF
    else
        # Check if trackpad options are already configured
        if grep -q "NaturalScrolling.*true" "$libinput_conf" && grep -q "Tapping.*true" "$libinput_conf"; then
            echo "Trackpad options already configured in $libinput_conf"
        else
            echo "Adding trackpad options to existing libinput configuration..."
            # Add natural scrolling if not present
            if ! grep -q "NaturalScrolling.*true" "$libinput_conf"; then
                sudo sed -i '/MatchIsTouchpad.*on/,/EndSection/ s/Driver "libinput"/Driver "libinput"\n        Option "NaturalScrolling" "true"/' "$libinput_conf"
            fi
            # Add tapping if not present
            if ! grep -q "Tapping.*true" "$libinput_conf"; then
                sudo sed -i '/MatchIsTouchpad.*on/,/EndSection/ s/Driver "libinput"/Driver "libinput"\n        Option "Tapping" "true"/' "$libinput_conf"
            fi
        fi
    fi

    echo "✓ Trackpad configured with natural scrolling and tap-to-click"
    echo "Note: Settings will be active after X11 restart or reboot."
    echo "To apply immediately, run:"
    echo "  xinput set-prop \"\$(xinput list --name-only | grep -i touchpad)\" \"libinput Natural Scrolling Enabled\" 1"
    echo "  xinput set-prop \"\$(xinput list --name-only | grep -i touchpad)\" \"libinput Tapping Enabled\" 1"
}

setup_dark_theme() {
    echo "Setting system theme to dark mode..."
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark
    echo "✓ Dark theme enabled"
}

setup_plymouth() {
    echo ""
    read -p "Customize Plymouth boot/LUKS screen with custom background? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping Plymouth customization."
        return
    fi

    echo "Customizing Plymouth boot screen..."

    # Clean up any previous incomplete setup
    echo "Cleaning up previous Plymouth configuration..."
    sudo rm -rf /usr/share/plymouth/themes/custom-penguins
    sudo plymouth-set-default-theme -l | grep -q "^spinner$" && sudo plymouth-set-default-theme spinner 2>/dev/null || true

    # Check if dotfiles wallpaper directory exists
    local wallpaper_source="$HOME/dotfiles/wallpaper/Pictures/gallery/wallpaper/other/penguins-pc-1920x1080.jpeg"
    if [ ! -f "$wallpaper_source" ]; then
        # Try alternative location
        wallpaper_source="$HOME/Pictures/gallery/wallpaper/other/penguins-pc-1920x1080.jpeg"
        if [ ! -f "$wallpaper_source" ]; then
            echo "Warning: Background image not found. Skipping Plymouth customization."
            return
        fi
    fi

    # Create custom theme directory based on spinner theme
    local theme_dir="/usr/share/plymouth/themes/custom-penguins"
    sudo mkdir -p "$theme_dir"

    # Copy the spinner theme as a base
    sudo cp -r /usr/share/plymouth/themes/spinner/* "$theme_dir/" 2>/dev/null || {
        echo "Warning: Spinner theme not found. Installing required packages first."
        sudo dnf install -y plymouth-theme-spinner
        sudo cp -r /usr/share/plymouth/themes/spinner/* "$theme_dir/"
    }

    # Convert and copy background image
    echo "Converting and copying background image..."
    
    # Install ImageMagick if not available
    if ! command -v magick &> /dev/null && ! command -v convert &> /dev/null; then
        echo "Installing ImageMagick for image conversion..."
        sudo dnf install -y ImageMagick
    fi
    
    # Convert JPEG to PNG for better Plymouth compatibility
    if command -v magick &> /dev/null; then
        echo "Converting JPEG to PNG using magick..."
        magick "$wallpaper_source" /tmp/background.png
        sudo cp /tmp/background.png "$theme_dir/background.png"
        rm -f /tmp/background.png
        echo "✓ Background image converted and copied"
    elif command -v convert &> /dev/null; then
        echo "Converting JPEG to PNG using convert..."
        convert "$wallpaper_source" /tmp/background.png
        sudo cp /tmp/background.png "$theme_dir/background.png"
        rm -f /tmp/background.png
        echo "✓ Background image converted and copied"
    else
        echo "Warning: ImageMagick installation failed. Plymouth may not display background properly."
        sudo cp "$wallpaper_source" "$theme_dir/background.png"
    fi

    # Create custom theme configuration
    sudo tee "$theme_dir/custom-penguins.plymouth" > /dev/null << 'EOF'
[Plymouth Theme]
Name=Custom Penguins
Description=Custom theme with penguin background
ModuleName=two-step

[two-step]
ImageDir=/usr/share/plymouth/themes/custom-penguins
BackgroundStartColor=0x000000
BackgroundEndColor=0x000000
BackgroundImage=background.png
ProgressBarBackgroundColor=0x606060
ProgressBarForegroundColor=0xffffff
MessageBelowAnimation=true
HorizontalAlignment=0.5
VerticalAlignment=0.25
DialogHorizontalAlignment=0.5
DialogVerticalAlignment=0.25
MessageHorizontalAlignment=0.5
MessageVerticalAlignment=0.3
WatermarkHorizontalAlignment=1.0
WatermarkVerticalAlignment=1.0
WatermarkFade=1.0
EOF

    # Remove or hide the Fedora logo watermark
    if [ -f "$theme_dir/watermark.png" ]; then
        sudo rm "$theme_dir/watermark.png"
    fi
    
    # Create an empty/transparent watermark to replace any logo
    if command -v magick &> /dev/null; then
        magick -size 1x1 xc:transparent /tmp/empty.png
        sudo cp /tmp/empty.png "$theme_dir/watermark.png"
        rm -f /tmp/empty.png
    elif command -v convert &> /dev/null; then
        convert -size 1x1 xc:transparent /tmp/empty.png
        sudo cp /tmp/empty.png "$theme_dir/watermark.png"
        rm -f /tmp/empty.png
    fi

    # Set the custom theme as default
    echo "Setting Plymouth theme..."
    sudo plymouth-set-default-theme custom-penguins

    # Rebuild initramfs to include the new theme
    echo "Rebuilding initramfs (this may take a moment)..."
    sudo dracut -f

    echo "✓ Plymouth customization completed"
    echo "Note: Custom boot screen will be visible on next boot/reboot."
}
