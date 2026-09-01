#!/usr/bin/env bash
#
# Arch Linux post-install script: packages, services, config symlinks and the
# few pieces of system provisioning the desktop shell relies on.
#
#   ./install.sh            interactive (asks about optional package groups)
#   ./install.sh --all      install every optional group without asking
#   ./install.sh --minimal  skip every optional group
#   ./install.sh --link     only (re)link configs, units and scripts; no packages,
#                           services or system provisioning

set -euo pipefail

REPO_ROOT="$(dirname "$(realpath "$0")")"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

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
    error "pacman not found - this script is for Arch Linux only."
    exit 1
fi

MODE="ask"
LINK_ONLY=0
case "${1:-}" in
    --all) MODE="all" ;;
    --minimal) MODE="none" ;;
    --link) LINK_ONLY=1 ;;
    "") ;;
    *) error "unknown option: $1"; exit 1 ;;
esac

ask() {
    # ask "<question>" -> 0 = yes
    case "$MODE" in
        all) return 0 ;;
        none) return 1 ;;
    esac
    local reply
    read -rp "$1 [y/N] " reply
    [[ $reply =~ ^[Yy] ]]
}

if [[ $LINK_ONLY -eq 0 ]]; then

# ---------- Step 1: Sync system & install build prerequisites ----------
info "Syncing pacman databases and updating system..."
sudo pacman -Syu --noconfirm

info "Ensuring base-devel and git are installed..."
sudo pacman -S --needed --noconfirm base-devel git

# ---------- Step 2: Install yay ----------
if command -v yay &>/dev/null; then
    success "yay is already installed - skipping."
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
# Everything the desktop needs, official repos and AUR alike (yay handles
# both). Packages that are only pulled in as dependencies elsewhere are still
# listed explicitly when the config uses them directly.
yay -S --needed --noconfirm rustup
rustup default stable

PACKAGES=(
    # ----- Hyprland & Wayland desktop -----
    hyprland
    hyprlock
    hypridle
    hyprpaper                 # fallback wallpaper daemon; the shell paints the wallpaper itself
    hyprpicker
    hyprshot
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    xdg-user-dirs
    quickshell-git            # desktop shell runtime (.config/quickshell/desktop)
    gtk-layer-shell
    polkit-gnome              # manual fallback agent only (polkit-fallback)
    gnome-keyring
    wlroots0.19
    app2unit-git

    # ----- Terminal, screenshots, clipboard -----
    foot
    grim
    slurp
    satty
    wtype
    cliphist
    wl-clipboard
    libnotify

    # ----- Shell tooling (scheme / wallpaper / launcher) -----
    python-materialyoucolor
    python-pillow
    hellwal
    matugen-bin
    libqalculate
    yad

    # ----- File manager / GUI utilities -----
    nautilus
    nautilus-open-any-terminal
    file-roller
    gnome-disk-utility
    qdirstat

    # ----- Theming & icons & cursors -----
    adw-gtk-theme
    bibata-cursor-theme
    papirus-icon-theme
    qt5-wayland
    qt5ct
    qt6ct
    qt6-tools

    # ----- Fonts -----
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    noto-fonts-extra
    ttf-rubik-vf
    ttf-cascadia-code-nerd
    ttf-jetbrains-mono-nerd
    ttf-noto-nerd
    ttf-ibm-plex
    ttf-material-symbols-variable-git

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

    # ----- GPU drivers (NVIDIA) -----
    nvidia-open
    nvidia-settings
    nvidia-utils
    lib32-nvidia-utils
    libva-nvidia-driver
    nvtop

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
    lan-mouse
    openssh
    openssl
    filezilla
    rclone
    samba
    aria2
    wget
    curl
    socat
    dnsmasq
    ethtool
    passt

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
    gdu
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
    python312
    python313
    go
    gdb
    openmp

    # ----- AI / LLM CLIs -----
    claude-code

    # ----- Multimedia -----
    mpv
    mpv-uosc
    vlc
    vlc-plugin-ffmpeg
    vlc-plugins-all
    obs-studio

    # ----- Communication -----
    vesktop-bin

    # ----- Streaming -----
    moonlight-qt
    sunshine

    # ----- Boot / disk / system maintenance -----
    grub
    efibootmgr
    os-prober
    arch-update
    downgrade
    pacman-contrib
    reflector
    timeshift
    zram-generator
    cpio
    flatpak

    # ----- Misc utilities -----
    transmission-qt
    ghost-downloader-bin
    qalculate-qt
    p7zip-gui
    7zip
    unzip
    gzip
    github-cli
    icu76
    leveldb
    libldm
    glfw
    glu
    unixodbc
    cuda
)

# ----- Optional groups -----
declare -A GROUP_PACKAGES=(
    [music]="spotify-launcher spicetify-cli spicetify-marketplace-bin"
    [gaming]="steam proton-ge-custom-bin"
    [containers]="docker docker-compose lazydocker"
    [virtualization]="libvirt virt-manager"
)
declare -A GROUP_PROMPT=(
    [music]="Install music tools (spotify + spicetify)?"
    [gaming]="Install gaming (steam + proton-ge)?"
    [containers]="Install containers (docker + compose + lazydocker)?"
    [virtualization]="Install virtualization (libvirt + virt-manager)?"
)
declare -A SELECTED=()
for group in music gaming containers virtualization; do
    if ask "${GROUP_PROMPT[$group]}"; then
        SELECTED[$group]=1
        # shellcheck disable=SC2206
        PACKAGES+=(${GROUP_PACKAGES[$group]})
    fi
done

# ---------- Step 3.5: LizardByte repo (sunshine prebuilt) ----------
if ! grep -q '^\[lizardbyte\]' /etc/pacman.conf; then
    info "Adding lizardbyte pacman repos..."
    sudo tee -a /etc/pacman.conf >/dev/null <<'EOT'

[lizardbyte]
SigLevel = Optional
Server = https://github.com/LizardByte/pacman-repo/releases/latest/download

[lizardbyte-beta]
SigLevel = Optional
Server = https://github.com/LizardByte/pacman-repo/releases/download/beta
EOT
    sudo pacman -Sy
fi

# ---------- Step 4: Install packages ----------
info "Installing ${#PACKAGES[@]} packages via yay..."
yay -S --needed --noconfirm "${PACKAGES[@]}"

# ---------- Step 5: Services and groups ----------
info "Enabling system services..."
sudo systemctl enable --now NetworkManager.service
sudo systemctl enable --now bluetooth.service
sudo systemctl enable --now sshd.service
sudo systemctl enable --now power-profiles-daemon.service || warn "power-profiles-daemon could not be enabled"

groups_to_add=(wheel)
if [[ -n ${SELECTED[containers]:-} ]]; then
    sudo systemctl enable --now docker.service
    groups_to_add+=(docker)
fi
if [[ -n ${SELECTED[virtualization]:-} ]]; then
    sudo systemctl enable --now libvirtd.service
    groups_to_add+=(libvirt)
fi
info "Adding $USER to groups: ${groups_to_add[*]}"
sudo usermod -aG "$(IFS=,; echo "${groups_to_add[*]}")" "$USER" || true

# ---------- Step 6: Device permissions the shell depends on ----------
# Nothing here is assumed to already work: every rule is written, then
# verified, and a failure is reported loudly instead of discovered later.

# Game controllers: the controller idle watcher reads the joystick event
# node so controller input keeps the session awake.
info "Provisioning controller access (udev uaccess rule)..."
sudo tee /etc/udev/rules.d/70-joystick-uaccess.rules >/dev/null <<'EOT'
# Give the active seat user access to game controllers (desktop shell idle watcher)
SUBSYSTEM=="input", ENV{ID_INPUT_JOYSTICK}=="1", TAG+="uaccess"
EOT
sudo udevadm control --reload-rules && sudo udevadm trigger --subsystem-match=input || warn "udev reload failed"
joystick_ok=1
for node in /dev/input/by-id/*-event-joystick; do
    [[ -e $node ]] || continue
    if [[ -r $node ]]; then
        success "controller readable: $node"
    else
        joystick_ok=0
        warn "controller NOT readable: $node (re-login may be needed for uaccess)"
    fi
done
if [[ $joystick_ok -eq 0 ]]; then
    warn "Controller idle inhibit will not work until the nodes are readable."
    warn "Fallback: sudo usermod -aG input $USER  (then log out and back in)"
fi

# External monitor brightness via DDC/CI: ddcutil needs /dev/i2c-* access
# (the ddcutil package ships the udev rule; the kernel module must be loaded).
info "Provisioning DDC/CI access for ddcutil..."
echo i2c-dev | sudo tee /etc/modules-load.d/i2c-dev.conf >/dev/null
sudo modprobe i2c-dev || warn "could not load i2c-dev"
sudo udevadm trigger --subsystem-match=i2c-dev || true
if ls /dev/i2c-* &>/dev/null; then
    if [[ -r /dev/i2c-0 || -r "$(ls /dev/i2c-* | head -1)" ]]; then
        success "i2c devices readable - external brightness available"
    else
        warn "i2c devices not readable yet (uaccess applies at next login); fallback: sudo usermod -aG i2c $USER"
    fi
else
    warn "no /dev/i2c-* nodes found; external monitor brightness will be unavailable"
fi

fi  # LINK_ONLY

# Go back to repo root
cd "$REPO_ROOT"

# ---------- Step 7: Files ----------
info "Copying Pictures to ~/Pictures..."
mkdir -p ~/Pictures
cp -rn Pictures/* ~/Pictures/

# Symlink .config entries (repo is the live config; edits apply immediately)
link_config() {
    local src="$1" dst="$2"

    # Already linked to the repo - nothing to do
    if [[ -L "$dst" && "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]]; then
        return
    fi

    # Back up whatever is there (real dir/file or stale link)
    if [[ -e "$dst" || -L "$dst" ]]; then
        warn "Backing up existing $dst -> $dst.bak"
        rm -rf "$dst.bak"
        mv "$dst" "$dst.bak"
    fi

    ln -s "$src" "$dst"
}

info "Symlinking .config entries into $CONFIG_HOME..."
mkdir -p "$CONFIG_HOME"
for src in "$REPO_ROOT"/.config/*; do
    name="$(basename "$src")"
    dst="$CONFIG_HOME/$name"

    # glib rewrites mimeapps.list via atomic rename, which would replace a
    # symlink with a plain file - keep it as a copy instead.
    if [[ "$name" == "mimeapps.list" ]]; then
        [[ -e "$dst" ]] || cp "$src" "$dst"
        continue
    fi

    # ~/.config/quickshell may host other quickshell configs, so link its
    # children individually instead of replacing the whole directory.
    if [[ "$name" == "quickshell" || "$name" == "systemd" ]]; then
        mkdir -p "$dst"
        if [[ "$name" == "systemd" ]]; then
            mkdir -p "$dst/user"
            for unit in "$src"/user/*; do
                link_config "$unit" "$dst/user/$(basename "$unit")"
            done
        else
            for sub in "$src"/*; do
                link_config "$sub" "$dst/$(basename "$sub")"
            done
        fi
        continue
    fi

    link_config "$src" "$dst"
done
systemctl --user daemon-reload || true

# Seed per-machine hyprland overrides (gitignored; hyprland.lua requires it)
if [[ ! -e "$REPO_ROOT/.config/hypr/hyprland/local.lua" ]]; then
    info "Seeding hypr per-machine config from local.lua.example..."
    cp "$REPO_ROOT/.config/hypr/hyprland/local.lua.example" "$REPO_ROOT/.config/hypr/hyprland/local.lua"
fi

# qt6ct cannot expand env vars in its config: seed the real file from the
# template with the resolved XDG_CONFIG_HOME (gitignored).
if [[ ! -e "$REPO_ROOT/.config/qt6ct/qt6ct.conf" ]]; then
    info "Seeding qt6ct.conf from template..."
    sed "s|@XDG_CONFIG_HOME@|$CONFIG_HOME|g" "$REPO_ROOT/.config/qt6ct/qt6ct.conf.example" > "$REPO_ROOT/.config/qt6ct/qt6ct.conf"
fi

# .local/bin: only the tracked scripts, only they get chmod'ed
info "Installing .local/bin scripts to ~/.local/bin..."
mkdir -p ~/.local/bin
for script in "$REPO_ROOT"/.local/bin/*; do
    [[ -f $script && $(basename "$script") != README.md ]] || continue
    cp "$script" ~/.local/bin/
    chmod +x ~/.local/bin/"$(basename "$script")"
done

# Install G502 HiRes Scroll Patch
sudo mkdir -p /etc/libinput
sudo tee /etc/libinput/local-overrides.quirks >/dev/null <<'EOT'
[Logitech G502]
MatchName=*Logitech G502*
AttrEventCode=-REL_WHEEL_HI_RES;-REL_HWHEEL_HI_RES;
EOT

if [[ $LINK_ONLY -eq 1 ]]; then
    success "Configs, units and scripts linked."
    exit 0
fi

# Default wallpaper + full colour pipeline (scheme + hellwal + templates)
info "Generating the initial colour scheme..."
if ~/.local/bin/wallpaper -f "$HOME/Pictures/Wallpapers/wlop_1.jpg"; then
    success "colour scheme generated"
else
    warn "wallpaper/scheme failed - run 'wallpaper -f <image>' after logging in"
fi

# bashrc
cp .bashrc ~/.bashrc

# Install fish plugins listed in fish_plugins
info "Installing fish plugins (fisher update)..."
fish -c 'fisher update' || warn "fisher update failed - run it manually later."

success "Installation finished."
warn  "Log out / reboot for group changes, udev uaccess and graphical services to take effect."
