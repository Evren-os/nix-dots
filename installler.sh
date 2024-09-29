#!/bin/bash

set -euo pipefail

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install a package using pacman or AUR helper
install_package() {
    local package=$1
    if pacman -Si "$package" >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm "$package" || return 1
    elif [[ -n $aur_helper ]] && $aur_helper -Si "$package" >/dev/null 2>&1; then
        $aur_helper -S --needed --noconfirm "$package" || return 1
    else
        echo "$package" >> "$failed_packages"
        return 1
    fi
    return 0
}

# Check for root privileges
if [[ $EUID -eq 0 ]]; then
    echo "This script should not be run as root. Please run as a regular user with sudo privileges."
    exit 1
fi

# Check for sudo privileges
if ! sudo -v; then
    echo "This script requires sudo privileges. Please ensure you have sudo access."
    exit 1
fi

# Determine AUR helper
if command_exists yay; then
    aur_helper="yay"
elif command_exists paru; then
    aur_helper="paru"
else
    echo "Warning: Neither yay nor paru is installed. AUR packages will not be available."
    aur_helper=""
fi

# Initialize variables
failed_packages=$(mktemp)
total_packages=0
installed_packages=0

# Check if any input files were provided
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <package_list_file> [<package_list_file2> ...]"
    exit 1
fi

# Process each input file
for file in "$@"; do
    if [[ ! -f "$file" ]]; then
        echo "Error: File $file not found. Skipping."
        continue
    fi

    while IFS= read -r package || [[ -n "$package" ]]; do
        # Skip empty lines and comments
        [[ -z "$package" || "$package" =~ ^[[:space:]]*# ]] && continue

        ((total_packages++))
        echo "Installing $package..."
        if install_package "$package"; then
            ((installed_packages++))
        fi
    done < "$file"
done

# Print summary
echo "Installation complete."
echo "Total packages: $total_packages"
echo "Successfully installed: $installed_packages"
echo "Failed to install: $((total_packages - installed_packages))"

# Print failed packages
if [[ -s "$failed_packages" ]]; then
    echo "The following packages could not be installed:"
    sort -u "$failed_packages" | tee failed_packages.txt
    echo "A list of failed packages has been saved to failed_packages.txt"
else
    echo "All packages were installed successfully."
    rm -f failed_packages.txt
fi

# Clean up temporary file
rm "$failed_packages"