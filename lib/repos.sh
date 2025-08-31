#!/usr/bin/env bash

# Get the script directory to locate project_repos.txt
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
GITHUB_USER="drewherron"


setup_wm_repos() {
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

setup_theme_repos() {
    echo "Cloning theme repositories..."
    mkdir -p ~/src
    cd ~/src

    local theme_repos=("aldalome")

    for repo in "${theme_repos[@]}"; do
        if [ ! -d "$repo" ]; then
            echo "Cloning $repo..."
            git clone "git@github.com:$GITHUB_USER/$repo.git"
        fi
    done
}

setup_project_repos() {
    echo "Cloning project repositories to ~/Projects..."
    mkdir -p ~/Projects
    cd ~/Projects

    local project_file="$SCRIPT_DIR/project_repos.txt"

    # Check if project_repos.txt exists
    if [ ! -f "$project_file" ]; then
        echo "No project_repos.txt found. Skipping personal project repositories."
        echo "Create $project_file with one git URL per line to clone personal projects."
        return
    fi

    # Read URLs from file, skipping empty lines and comments
    local repo_urls=()
    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        repo_urls+=("$line")
    done < "$project_file"

    # Check if we have any repositories to clone
    if [ ${#repo_urls[@]} -eq 0 ]; then
        echo "No repositories found in $project_file. Skipping personal projects."
        return
    fi

    echo "Found ${#repo_urls[@]} repositories to clone..."

    for repo_url in "${repo_urls[@]}"; do
        # Extract repository name from URL for directory check
        local repo_name
        repo_name=$(basename "$repo_url" .git)

        if [ ! -d "$repo_name" ]; then
            echo "Cloning $repo_name from $repo_url..."
            git clone "$repo_url"
        else
            echo "$repo_name already exists, skipping..."
        fi
    done
}

setup_other_repos() {
    echo "Cloning employment repositories..."
    mkdir -p ~/Documents/
    cd ~/Documents/
    if [ ! -d "Employment" ]; then
            echo "Cloning Employment..."
            git clone "git@github.com:$GITHUB_USER/Employment.git"
        fi
        cd Employment
    # TODO Get rid of these, just use Employment
    if [ ! -d "cover_letters" ]; then
            echo "Cloning cover_letters..."
            git clone "git@github.com:$GITHUB_USER/cover_letters.git"
        fi
        cd ..
    if [ ! -d "resume" ]; then
            echo "Cloning resume..."
            git clone "git@github.com:$GITHUB_USER/resume.git"
        fi
        cd ~
}

setup_repos() {
    setup_wm_repos
    setup_theme_repos
    setup_project_repos
    setup_other_repos
}
