# dotfiles

Arch Linux + Hyprland(NVIDIA)日常環境,目標:一台全新電腦 → 完整可用的 daily driver。
桌面 shell 是自己用 quickshell 寫的(`.config/quickshell/desktop`),沒有第三方 shell 相依。

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
./install.sh            # 互動詢問選配群組;--all 全裝、--minimal 全跳過
```

`./install.sh --link` 只重新連結設定 / systemd 單元 / 腳本(不裝套件),換 branch 或新增單元後跑這個即可。

腳本會:裝 yay → 裝全部套件(官方 + AUR)→ 詢問選配群組(音樂 / 遊戲 / 容器 / 虛擬化,
服務與群組只在有選時才啟用),以及要不要設定 GRUB 雙開機(os-prober 抓 Windows、記住上次選的項目;
記住選項需要 `/boot` 在 ESP 上)→ 啟用服務(NetworkManager、bluetooth、sshd、power-profiles-daemon)
→ 佈建裝置權限並驗證(手把 udev uaccess 規則、ddcutil 的 i2c-dev)→ 把 `.config` symlink 進
`~/.config`(systemd user 單元逐檔連結)、複製 `.local/bin`、桌布、`.bashrc` → 種出 `local.lua`
與 `qt6ct.conf` → 跑 `wallpaper -f` 產生整套色票。

### 3. 再重開機

讓群組與 udev 規則生效。之後在 tty1 登入會自動啟動 Hyprland,`execs.lua` 再透過
systemd user service 拉起 desktop shell、hypridle 與手把 idle watcher。

> 注意:NTFS 磁區直接用核心內建的 `ntfs3` 掛載即可,不需要 ntfs-3g;fstab 裡型別寫 `ntfs3`。
> 排程備份(backintime 等)不在腳本內,需要的話自行加 crontab。

## Desktop shell

`qs -c desktop`,由 `desktop-shell.service` 管理(`Restart=on-failure`,
`journalctl --user -u desktop-shell` 看 log,`systemctl --user restart desktop-shell` 重啟)。

- **隱藏式 bar**(左側):滑鼠碰到螢幕邊緣就滑出,離開就收;從邊緣往內拖 20px 釘住、
  反向拖收回;`qs -c desktop ipc call bar toggle` 亦可。全螢幕視窗時整個 bar 停用,只剩 OSD。
- **Hover popouts**:滑到 bar 上的模組就展開,點一下完成 —— KGrid 格子、資源、音訊
  (切換輸出/輸入裝置、各 app 音量)、網路(Wi-Fi 連線 / 密碼)、VPN(nmcli:OpenVPN + WireGuard)、
  藍牙、通知中心、月曆、電源(快速開關 + session 按鈕,危險動作要點兩下)。
- **OSD**:音量 / 麥克風 / 亮度(內建面板走 brightnessctl,外接螢幕走 ddcutil);
  切換 KGrid 格子時彈出 activity + 5×5 點陣。
- **通知**:自帶 notification daemon;popup 可中鍵 / 右滑關閉、支援 action 與 inline reply;
  歷史持久化在 `$XDG_STATE_HOME/desktop-shell/`;勿擾模式。
- **Launcher**(`Super` 單擊 / `Super+Space`):app 搜尋、`>` 動作(色票 / variant / 桌布 /
  明暗 / 電源…,定義在 `config.json`)、`=` 計算(qalc)、`;` 剪貼簿歷史(cliphist,含圖片縮圖)、`:` emoji(複製並輸入)。
  數學式子直接輸入也會算。
- **Overview**(`Super+Tab`):目前 activity 的 5×5 格子 + 即時視窗預覽;點格子切換、
  點視窗聚焦、中鍵關閉、拖曳視窗到別的格子;方向鍵 / Enter / Tab / 字母鍵切 activity。
- **Dashboard**(`Super+G`,或滑鼠碰螢幕上緣中央):時鐘 / 日期 / 最新通知 + 勿擾在左,
  月曆、正在播放、CPU/記憶體/GPU 環圈在中間,當天議程與待辦清單在右。
- **Summon deck**(`Super+D` 在滑鼠位置、`Super+Shift+D` 在螢幕中央):時鐘、KGrid 格子、
  音量 / 亮度、播放控制與 launcher 入口,叫出來時滑鼠正好在正中心。
- **月曆與待辦**:讀本機 ICS 目錄,設了 `calendar.url` / `calendar.username` 就再接 CalDAV
  伺服器(自架 Radicale 等);密碼用 `desktop-calendar set-password` 存進 systemd-creds。
  在 dashboard 勾待辦會寫回伺服器。細節見 `.config/quickshell/desktop/README.md`。
- **區域截圖**(`Print`、`Super+Shift+S`;`Super+Shift+Alt+S` 直接進剪貼簿):凍結畫面後拖選,
  滑到視窗上會自動吸附,Space 切換 satty / 剪貼簿,Esc 取消。
- **桌面時鐘**:桌布上的時鐘,電源 popout 或 `qs -c desktop ipc call desktopClock toggle` 開關。
- **Keep awake**:電源 popout 的開關(`ipc call idle toggle`);播放音訊時自動抑制 idle;
  手把有輸入時也會抑制(`joystick-idle-watch`)。
- **Polkit 代理**在 shell 內;shell 掛掉時手動跑 `polkit-fallback`。

設定檔:`.config/quickshell/desktop/config.json`,存檔即時生效。`appearance.style` 切換視覺風格:
`frame`(repo 出貨值:整個螢幕一圈圓角外框,bar 從左側帶滑出,popout / OSD / dashboard 直接
從外框長出來)、`rim`(深漆面板 + 受光鑲邊)、`ledger`(規線帳冊、等寬標籤)、
`capsule`(懸浮膠囊 dock、pill 列)、`signal`(HUD 角標、分段量表)、
`poster`(實心色塊、粗線標題)、`classic`。
`bar.position` 可設 `left`(預設)、`right` 或 `top`(水平 bar,popout 從下方彈出);`bar.entries` 決定模組順序與取捨。
不想改檔案的話:launcher 打 `>style`,或 `qs -c desktop ipc call theme set rim`(`theme cycle` 輪流切;這會由 shell 回寫 config.json,只保留它認得的鍵)。
色票由 `scheme` / `wallpaper` 產生,shell 熱載入 `$XDG_STATE_HOME/scheme/colours.json`。

### 常用快捷鍵

| 鍵 | 動作 |
|---|---|
| `Super`(單擊)/ `Super+Space` / `Super+B` | Launcher |
| `Super+V` | 剪貼簿歷史 |
| `Super+Tab` | Overview |
| `Super+G` | Dashboard |
| `Super+D` / `Super+Shift+D` | Summon deck(滑鼠位置 / 螢幕中央) |
| `Ctrl+Alt+Delete` / `Super+Esc` | 電源 / session 選單 |
| `Ctrl+Alt+N` | 通知中心;`Ctrl+Alt+C` 清空通知 |
| `Ctrl+Super+{Z,X,C,A,S,D,Q,W,E,Space}` | 切換 KGrid activity(`Space` = main) |
| `Ctrl+Super+方向鍵` | 在 5×5 格子內移動(加 `Shift` 帶著視窗) |
| `Print` / `Super+Shift+S` | 區域截圖(satty);`Super+Shift+Alt+S` 進剪貼簿;`Super+Print` 抓視窗;`Super+Alt+Print` 整個螢幕 |
| `Alt+XF86AudioPlay` | 音訊 popout(切換輸出裝置) |

## Theming

Colours come from a single generator, `scheme` (Material You, all 9 variants,
light/dark, preset schemes), which renders every consumer template — hypr,
hyprlock, Qt (qt6ct), GTK, the desktop shell's `colours.json`, and the
terminal palette. `wallpaper -f <image>` (or `-r` for random) sets the
wallpaper and re-runs the whole pipeline, including hellwal for terminal
colours. See `.local/bin/README.md` for details and how to add preset
schemes.

## Development

Never switch branches in this checkout: `~/.config` is symlinked into it, so
the checked-out tree *is* the running desktop. Work on diverging branches in a
separate `git worktree` and test in a nested Hyprland session
(`dev/README.md`).

### Switching a running machine to a new shell version

1. Merge (or fast-forward) the branch into the checkout that `~/.config`
   points at — never `git switch` there.
2. `./install.sh --link` to link new systemd units / scripts and seed any new
   gitignored files, then `systemctl --user daemon-reload`.
3. Log out and back in: `execs.lua` starts `desktop-shell.service` at session
   start. From a running session, `systemctl --user restart desktop-shell`
   restarts only the shell.
4. Rollback is a `git revert` of the merge plus another relogin; the previous
   shell's packages are never removed by this repo, so nothing needs
   reinstalling.

First-session checklist (things a nested test session cannot exercise):
hover the left edge and drag the bar to pin it; right-click a tray icon;
type in the launcher (`Super`); drag a window between cells in the overview
(`Super+Tab`); run `pkexec true` for the polkit dialog; press a controller
button and confirm `qs -c desktop ipc call idle isInhibited` says true;
brightness keys on an external monitor; a real notification with actions.
