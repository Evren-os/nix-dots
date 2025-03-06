#!/usr/bin/env bash

set -e
set -o pipefail

GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
NC="\033[0m"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

command_exists() {
    command -v "$1" &> /dev/null
}

confirm() {
    read -p "$1 [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

if [ "$EUID" -eq 0 ]; then
    log_error "This script should not be run as root."
    exit 1
fi

if ! command_exists paru; then
    log_error "Paru package manager not found. Please install paru first."
    log_info "You can install it by following instructions at: https://github.com/Morganamilo/paru"
    exit 1
fi

echo "================================================================="
log_info "Hyprland Desktop Environment Setup"
echo "This script will set up a complete Hyprland desktop environment"
echo "with Catppuccin Macchiato theme, necessary fonts, and configs."
echo "================================================================="

if ! confirm "Do you want to continue with the installation?"; then
    log_info "Installation aborted."
    exit 0
fi

log_info "Creating required directories..."
mkdir -p ~/.local/bin
mkdir -p ~/.local/share/icons
mkdir -p ~/.config

log_info "Installing Hyprland and essential packages..."
paru -S --needed --noconfirm \
    hyprland hyprlock hypridle xdg-desktop-portal-hyprland hyprpicker \
    swww waybar waybar-updates rofi-wayland swaync wl-clipboard \
    cliphist swayosd-git brightnessctl udiskie devify polkit-gnome \
    playerctl pyprland grim slurp fastfetch fzf jq eza fd vivid fish \
    starship ripgrep bat yazi pavucontrol satty nemo zathura zathura-pdf-mupdf \
    qimgv-light mpv || {
        log_error "Failed to install Hyprland and essential packages"
        exit 1
    }
log_success "Hyprland and essential packages installed successfully"

log_info "Installing AMD GPU drivers and graphics libraries..."
paru -S --needed --noconfirm \
    xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon vulkan-tools \
    opencl-clover-mesa lib32-opencl-clover-mesa mesa lib32-mesa \
    vdpauinfo clinfo || {
        log_error "Failed to install GPU drivers"
        exit 1
    }
log_success "AMD GPU drivers installed successfully"

log_info "Installing audio components..."
paru -S --needed --noconfirm \
    pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber alsa-utils || {
        log_error "Failed to install audio components"
        exit 1
    }
log_success "Audio components installed successfully"

log_info "Enabling PipeWire and WirePlumber services..."
systemctl --user enable --now pipewire wireplumber || {
    log_warning "Failed to enable pipewire services. Please check manually after installation."
}
log_success "PipeWire services enabled"

log_info "Installing theming packages..."
paru -S --needed --noconfirm \
    catppuccin-gtk-theme-macchiato catppuccin-cursors-macchiato \
    qt5ct qt5-wayland qt6-wayland kvantum kvantum-qt5 nwg-look || {
        log_error "Failed to install theming packages"
        exit 1
    }
log_success "Theming packages installed successfully"

log_info "Installing Catppuccin icons..."
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR" || {
    log_error "Failed to create temporary directory"
    exit 1
}

if ! curl -LJO https://github.com/ljmill/catppuccin-icons/releases/download/v0.2.0/Catppuccin-SE.tar.bz2; then
    log_error "Failed to download Catppuccin icons"
    exit 1
fi

tar -xf Catppuccin-SE.tar.bz2 || {
    log_error "Failed to extract Catppuccin icons"
    exit 1
}

cp -r Catppuccin-SE ~/.local/share/icons/ || {
    log_error "Failed to install Catppuccin icons"
    exit 1
}

cd - > /dev/null
rm -rf "$TEMP_DIR"
log_success "Catppuccin icons installed successfully"

log_info "Installing fonts..."
paru -S --needed --noconfirm \
    ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols ttf-nerd-fonts-symbols-mono \
    ttf-nerd-fonts-symbols-common ttf-font-awesome noto-fonts-cjk \
    ttf-ms-win11-auto ttf-twemoji ttf-iosevka-nerd otf-geist-mono-nerd \
    otf-geist otf-geist-mono apple-fonts || {
        log_error "Failed to install fonts"
        exit 1
    }
log_success "Fonts installed successfully"

log_info "Updating font cache..."
fc-cache -fv || log_warning "Font cache update failed, but we'll continue..."

log_info "Installing additional utilities..."
paru -S --needed --noconfirm \
    xdg-user-dirs grimblast-git alacritty zsh neovim nodejs npm go zed bun \
    zip unrar zen-browser-bin qbittorrent yt-dlp cava btop tree rsync \
    flatpak wlsunset vscodium-bin vscodium-bin-marketplace dolphin qmplay2 github-cli proxychains-ng nomacs spotify || {
        log_error "Failed to install additional utilities"
        exit 1
    }
log_success "Additional utilities installed successfully"

if confirm "Do you want to install Matt-FTW's dotfiles?"; then
    log_info "Cloning dotfiles repository..."
    if [ -d "dotfiles" ]; then
        log_warning "Dotfiles directory already exists. Removing it..."
        rm -rf dotfiles
    fi

    if ! git clone https://github.com/Matt-FTW/dotfiles.git; then
        log_error "Failed to clone dotfiles repository"
        exit 1
    fi

    log_info "Installing dotfiles..."
    cd dotfiles || {
        log_error "Failed to change to dotfiles directory"
        exit 1
    }

    if [ -d ~/.config ]; then
        log_info "Backing up existing config..."
        BACKUP_DIR=~/.config.bak.$(date +%Y%m%d%H%M%S)
        mkdir -p "$BACKUP_DIR"
        cp -r ~/.config/* "$BACKUP_DIR/" 2>/dev/null || true
        log_success "Config backed up to $BACKUP_DIR"
    fi

    log_info "Copying configuration files..."
    cp -r .config/* ~/.config/ || {
        log_error "Failed to copy config files"
        exit 1
    }

    log_info "Copying binary files..."
    cp -r .local/bin/* ~/.local/bin/ 2>/dev/null || {
        log_warning "Failed to copy bin files or none exist"
    }

    cd - > /dev/null
    log_success "Dotfiles installed successfully"
fi

if confirm "Do you want to install Oh My Zsh?"; then
    log_info "Installing Oh My Zsh..."
    paru -S --needed --noconfirm oh-my-zsh-git || {
        log_error "Failed to install Oh My Zsh"
        exit 1
    }
    log_success "Oh My Zsh installed successfully"

    if [[ "$SHELL" != *"zsh"* ]]; then
        if confirm "Do you want to set Zsh as your default shell?"; then
            chsh -s "$(which zsh)" || log_warning "Failed to change shell. You can do it manually later."
        fi
    fi
fi

if command_exists xdg-user-dirs-update; then
    log_info "Updating XDG user directories..."
    xdg-user-dirs-update || log_warning "Failed to update XDG user directories"
fi

echo "================================================================="
log_success "Hyprland desktop environment setup completed successfully!"
echo "----------------------------------------------------------------"
echo "What to do next:"
echo "1. Log out of your current session"
echo "2. Select Hyprland from your display manager"
echo "3. Log in to your new Hyprland environment"
echo "================================================================="

if confirm "Would you like to reboot now?"; then
    log_info "Rebooting system..."
    sudo reboot
else
    log_info "You can reboot later to apply all changes."
fi

exit 0