#!/usr/bin/env bash
#
# Arch Linux post-install script

set -euo pipefail

# ---------- Pretty printing ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[ OK ]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[FAIL]${NC} $*" >&2; }

# ---------- Sanity checks ----------
if [[ $EUID -eq 0 ]]; then
    error "Do not run this script as root. Run as a normal user with sudo privileges."
    exit 1
fi

if ! command -v pacman &>/dev/null; then
    error "pacman not found — this script is for Arch Linux only."
    exit 1
fi

# ---------- Step 1: Sync system & install build prerequisites ----------
info "Syncing pacman databases and updating system..."
sudo pacman -Syu --noconfirm

info "Ensuring base-devel and git are installed..."
sudo pacman -S --needed --noconfirm base-devel git

# ---------- Step 2: Install yay ----------
if command -v yay &>/dev/null; then
    success "yay is already installed — skipping."
else
    info "Installing yay (AUR helper)..."
    cd ~
    rm -rf yay-bin
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
    cd ~
    rm -rf yay-bin
    success "yay installed and yay-bin cleanup done."
    yay -Y --gendb
fi

# ---------- Step 3: Package list ----------
# Organized by category for readability. yay handles both official repos and AUR.
PACKAGES=(
    # ----- Hyprland & Wayland desktop -----
    hyprland
    hyprlock
    hypridle
    hyprpaper
    hyprpicker
    hyprshot
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    xdg-user-dirs
    quickshell-git
    gtk-layer-shell
    polkit-gnome
    gnome-keyring
    wlroots0.19

    # ----- Terminals, launchers, screen tools -----
    foot
    fuzzel
    rofi
    grim
    slurp
    swappy
    wtype
    cliphist
    gpu-screen-recorder

    # ----- File manager / GUI utilities -----
    nautilus
    nautilus-open-any-terminal
    file-roller
    gnome-text-editor
    gnome-disk-utility
    qdirstat
    yad

    # ----- Theming & icons & cursors -----
    adw-gtk-theme
    bibata-cursor-theme
    papirus-icon-theme
    nwg-look
    qt5-wayland
    qt5ct
    qt6ct
    qt6-tools
    xcursor-viewer-git

    # ----- Fonts -----
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    noto-fonts-extra
    ttf-jetbrains-mono-nerd
    ttf-noto-nerd
    ttf-ibm-plex
    ttf-material-symbols-variable-git
    # ttf-ms-win11-auto

    # ----- Wallpaper / color generation -----
    hellwal
    matugen-bin

    # ----- Audio (PipeWire) -----
    pipewire
    pipewire-alsa
    pipewire-jack
    pipewire-pulse
    wireplumber
    gst-plugin-pipewire
    pavucontrol
    alsa-utils
    libpulse
    cava
    libcava
    aubio

    # ----- GPU drivers (NVIDIA) -----
    nvidia-open-dkms
    nvidia-settings
    nvidia-utils
    lib32-nvidia-utils
    libva-nvidia-driver

    # ----- Hardware control -----
    brightnessctl
    ddcutil
    solaar
    power-profiles-daemon
    intel-ucode
    sof-firmware
    lm_sensors

    # ----- Bluetooth -----
    bluez
    bluez-utils
    bluez-deprecated-tools
    blueman
    bluetui

    # ----- Networking & VPN -----
    networkmanager
    network-manager-applet
    networkmanager-openvpn
    clash-verge-rev-bin
    vopono-bin
    proxychains-ng
    tailscale
    openssh
    openssl
    putty
    filezilla
    rclone
    samba
    aria2
    wget
    curl
    iperf3
    traceroute
    socat
    dnsmasq

    # ----- Input method (Chinese) -----
    fcitx5
    fcitx5-chewing
    fcitx5-configtool
    fcitx5-gtk
    fcitx5-qt

    # ----- Browsers -----
    google-chrome
    microsoft-edge-stable-bin

    # ----- Editors / IDEs -----
    vim
    visual-studio-code-bin

    # ----- Shell / terminal UX -----
    fish
    starship
    tmux
    fastfetch
    htop
    btop
    tree
    dos2unix
    tldr++
    trash-cli
    just
    jq
    inotify-tools
    man-db

    # ----- Programming languages & toolchains -----
    uv
    python-pip
    python-virtualenv
    go
    rustup
    cargo-tauri
    clang
    gdb
    openmp
    yarn
    tk

    # ----- AI / LLM CLIs -----
    claude-code
    gemini-cli
    openai-codex
    opencode

    # ----- Containers / VMs -----
    docker
    docker-compose
    lazydocker
    libvirt
    virt-manager

    # ----- Multimedia -----
    mpv
    mpv-uosc
    vlc
    vlc-plugin-ffmpeg
    vlc-plugins-all
    obs-studio
    gimp
    imagemagick

    # ----- Music / Spotify -----
    spotify-launcher
    spicetify-cli
    spicetify-marketplace-bin

    # ----- Communication / messaging -----
    vesktop-bin
    vicinae-bin

    # ----- Gaming -----
    steam
    proton-ge-custom-bin
    protontricks
    moonlight-qt
    sunshine

    # ----- Boot / disk / system maintenance -----
    grub
    efibootmgr
    os-prober
    arch-update
    downgrade
    pacman-contrib
    timeshift
    zram-generator
    cpio

    # ----- Misc utilities -----
    transmission-qt
    qalculate-qt
    libqalculate
    p7zip-gui
    7zip
    unzip
    gzip
    github-cli
    git
    icu76
    leveldb
    libldm
    glfw
    glu
    unixodbc
    cuda

    # ----- Desktop Shell -----
    caelestia-shell
)

# ---------- Step 4: Install packages ----------
info "Installing ${#PACKAGES[@]} packages via yay..."
yay -S --needed --noconfirm "${PACKAGES[@]}"

# ---------- Step 5: Enable common services ----------
info "Enabling system services..."
sudo systemctl enable --now NetworkManager.service
sudo systemctl enable --now bluetooth.service
sudo systemctl enable --now docker.service
sudo systemctl enable --now libvirtd.service
sudo systemctl enable --now tailscaled.service

# Add current user to common groups
info "Adding $USER to docker, libvirt, wheel groups..."
sudo usermod -aG docker,libvirt,wheel "$USER" || true

# Go back to repo root
cd "$(dirname "$(realpath "$0")")"

# Copy Wallpapers
info "Copying wallpapers to ~/Pictures/Wallpapers..."
mkdir -p ~/Pictures
cp -r Wallpapers ~/Pictures/Wallpapers

success "Installation finished."
warn  "You may need to log out / reboot for group changes and graphical services to take effect."
warn  "Next: copy the .config folder from this repo into ~/.config (do this in a separate step)."
