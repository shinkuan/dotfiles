#!/usr/bin/env bash
#
# Arch Linux post-install script

set -euo pipefail

REPO_ROOT="$(dirname "$(realpath "$0")")"

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

    cd "$REPO_ROOT"
fi

# ---------- Step 3: Package list ----------
# Organized by category for readability. yay handles both official repos and AUR.
yay -S --needed --noconfirm rustup
rustup default stable

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
    app2unit

    # ----- Terminals, launchers, screen tools -----
    foot
    fuzzel
    rofi
    grim
    slurp
    swappy
    satty
    wtype
    cliphist
    gpu-screen-recorder
    wl-screenrec

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
    nvidia-open
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
    ethtool

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
    cargo-tauri
    clang
    gdb
    openmp
    yarn
    tk

    # ----- AI / LLM CLIs -----
    claude-code
    gemini-cli
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
    ghost-downloader-bin
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

# ---------- Step 3.5: LizardByte repo (sunshine prebuilt) ----------
if ! grep -q '^\[lizardbyte\]' /etc/pacman.conf; then
    info "Adding lizardbyte pacman repos..."
    sudo tee -a /etc/pacman.conf >/dev/null <<'EOF'

[lizardbyte]
SigLevel = Optional
Server = https://github.com/LizardByte/pacman-repo/releases/latest/download

[lizardbyte-beta]
SigLevel = Optional
Server = https://github.com/LizardByte/pacman-repo/releases/download/beta
EOF
    sudo pacman -Sy
fi

# ---------- Step 4: Install packages ----------
info "Installing ${#PACKAGES[@]} packages via yay..."
yay -S --needed --noconfirm "${PACKAGES[@]}"

# ---------- Step 5: Enable common services ----------
info "Enabling system services..."
sudo systemctl enable --now NetworkManager.service
sudo systemctl enable --now bluetooth.service
sudo systemctl enable --now docker.service
sudo systemctl enable --now libvirtd.service
sudo systemctl enable --now sshd.service

# Add current user to common groups
info "Adding $USER to docker, libvirt, wheel groups..."
sudo usermod -aG docker,libvirt,wheel "$USER" || true

# Go back to repo root
cd "$REPO_ROOT"

# Copy Wallpapers
info "Copying Pictures to ~/Pictures..."
mkdir -p ~/Pictures
cp -r Pictures/* ~/Pictures/

# Symlink .config entries (repo is the live config; edits apply immediately)
info "Symlinking .config entries into ~/.config..."
mkdir -p ~/.config
for src in "$REPO_ROOT"/.config/*; do
    name="$(basename "$src")"
    dst="$HOME/.config/$name"

    # glib rewrites mimeapps.list via atomic rename, which would replace a
    # symlink with a plain file — keep it as a copy instead.
    if [[ "$name" == "mimeapps.list" ]]; then
        [[ -e "$dst" ]] || cp "$src" "$dst"
        continue
    fi

    # Already linked to the repo — nothing to do
    if [[ -L "$dst" && "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]]; then
        continue
    fi

    # Back up whatever is there (real dir/file or stale link)
    if [[ -e "$dst" || -L "$dst" ]]; then
        warn "Backing up existing $dst -> $dst.bak"
        rm -rf "$dst.bak"
        mv "$dst" "$dst.bak"
    fi

    ln -s "$src" "$dst"
done

# Copy .local/bin scripts (swappy shim is required by the screenshot flow)
info "Copying .local/bin scripts to ~/.local/bin..."
mkdir -p ~/.local/bin
cp -r .local/bin/* ~/.local/bin/
chmod +x ~/.local/bin/*

# Install G502 HiRes Scroll Patch
sudo mkdir -p /etc/libinput
sudo tee /etc/libinput/local-overrides.quirks >/dev/null <<'EOF'
[Logitech G502]
MatchName=*Logitech G502*
AttrEventCode=-REL_WHEEL_HI_RES;-REL_HWHEEL_HI_RES;
EOF

# Install Hyprkool
# cargo install --git https://github.com/shinkuan/hyprkool --branch hypr-v0.55

# Generate Hellwal sequences
mkdir -p ~/.cache/hellwal/cache
hellwal -i "$HOME/Pictures/Wallpapers/wlop_1.jpg" --check-contrast

# default wallpaper
caelestia wallpaper -f "$HOME/Pictures/Wallpapers/wlop_1.jpg"

# quickshell overview
mkdir -p ~/.config/quickshell
git clone https://github.com/shinkuan/quickshell-overview ~/.config/quickshell/overview -b hypr-v0.55

# bashrc
cp .bashrc ~/.bashrc

success "Installation finished."
warn  "You may need to log out / reboot for group changes and graphical services to take effect."
