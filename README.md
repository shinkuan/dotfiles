# dotfiles

Arch Linux + Hyprland(NVIDIA)日常環境,目標:一台全新電腦 → 完整可用的 daily driver。

## 新機器安裝流程

### 1. Arch 開機碟進入後 — 用 archinstall 裝底層系統

連上網路——有線插了就通;Android 手機接 USB 開「USB 網路共享」也是零設定;Wi-Fi 則用:

```sh
iwctl --passphrase "你的密碼" station wlan0 connect SSID
```

接著下載本 repo 的 archinstall 設定並安裝:

```sh
curl -LO https://raw.githubusercontent.com/shinkuan/dotfiles/main/archinstall/user_configuration.json
archinstall --config user_configuration.json
```

進入 archinstall 後只需手動設定 **磁碟分割** 和 **使用者帳號 / root 密碼**,
其餘(台/日鏡像站、GRUB、NetworkManager、multilib、zram swap、時區)都在設定檔裡了。
裝完重開機、拔開機碟。

### 2. 重開機後 — 跑安裝腳本

用剛建立的使用者登入 TTY(Wi-Fi 先用 `nmtui` 連線),然後:

```sh
git clone https://github.com/shinkuan/dotfiles.git ~/Documents/dotfiles
cd ~/Documents/dotfiles
./install.sh
```

腳本會:裝 yay → 裝全部套件(官方 + AUR)→ 啟用服務(NetworkManager、bluetooth、docker、libvirtd、sshd)→ 複製 `.config`、`.local/bin`、桌布、`.bashrc` → 產生 hellwal 色票與預設桌布。

### 3. 再重開機

讓群組(docker/libvirt)生效。之後在 tty1 登入會自動啟動 Hyprland + caelestia shell。

> 注意:NTFS 磁區直接用核心內建的 `ntfs3` 掛載即可,不需要 ntfs-3g;fstab 裡型別寫 `ntfs3`。
