#!/usr/bin/env bash

# Get the script directory to locate repos.txt
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
GITHUB_USER="drewherron"

setup_wm_repos() {
    echo ""
    read -p "Clone and build window manager tools (dwm, st, dmenu, slstatus)? This requires building from source. (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping window manager setup."
        return
    fi

    echo "Cloning and building WM tools..."
    mkdir -p ~/src
    cd ~/src

    local wm_repos=("dwm" "st" "dmenu" "slstatus")

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
}

setup_other_repos() {
    local repo_file="$SCRIPT_DIR/repos.txt"

    # Check if repos.txt exists
    if [ ! -f "$repo_file" ]; then
        echo "No repos.txt found. Skipping repository cloning."
        echo "Create $repo_file with destination:git_url format to clone repositories."
        return
    fi

    echo ""
    read -p "Clone configured repositories? This may clone many personal projects. (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping repository cloning."
        return
    fi

    echo "Cloning other repositories..."

    # Read repository configurations from file, skipping empty lines and comments
    local repo_configs=()
    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        repo_configs+=("$line")
    done < "$repo_file"

    # Check if we have any repositories to clone
    if [ ${#repo_configs[@]} -eq 0 ]; then
        echo "No repositories found in $repo_file. Skipping repository cloning."
        return
    fi

    echo "Found ${#repo_configs[@]} repositories to clone..."

    for config in "${repo_configs[@]}"; do
        # Parse destination:git_url format
        IFS=':' read -r dest_dir git_url <<< "$config"

        # Expand tilde in destination directory
        dest_dir="${dest_dir/#\~/$HOME}"

        # Extract repository name from URL
        local repo_name
        repo_name=$(basename "$git_url" .git)

        # Create destination directory
        mkdir -p "$dest_dir"
        cd "$dest_dir"

        # Clone repository if it doesn't exist
        if [ ! -d "$repo_name" ]; then
            echo "Cloning $repo_name to $dest_dir..."
            git clone "$git_url" || echo "Warning: Could not clone $git_url"
        else
            echo "$repo_name already exists in $dest_dir, skipping..."
        fi
    done
}

setup_repos() {
    setup_wm_repos
    setup_other_repos
}
