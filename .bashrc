#
# ~/.bashrc
#

# If not running interactively, don't do anything
# [[ $- != *i* ]] && return

# Start ssh agent
if [ -z "$SSH_AUTH_SOCK" ]; then
  eval "$(ssh-agent -s)"
  ssh-add ~/.ssh/ppk
fi

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

# Custom Aliases and Functions
alias ll='ls -alh --color=auto'
alias vi=vim
alias H=Hyprland

# PATH
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export QT_QPA_PLATFORMTHEME=qt6ct


if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
  # exec Hyprland -c ~/.config/hypr/hyprland_noctalia.conf
  exec start-hyprland 
  echo "Hyprland"
fi

hyprctl_socat() {
    local runtime_dir="/run/user/$(id -u)"
    local instance_sig=$(find "$runtime_dir/hypr/" -name ".socket.sock" 2>/dev/null | awk -F'/' '{print $(NF-1)}' | head -n 1)

    if [ -z "$instance_sig" ]; then
        echo "Error: Active Hyprland instance not found."
        return 1
    fi

    local socket_path="$runtime_dir/hypr/$instance_sig/.socket.sock"

    if command -v socat >/dev/null 2>&1; then
        echo -n "$1" | socat - "UNIX-CONNECT:$socket_path"
    else
        HYPRLAND_INSTANCE_SIGNATURE="$instance_sig" hyprctl "$1"
    fi
}

remote_display_on() {
    # Hyprland 0.55+ dispatch takes a Lua expression instead of dispatcher-name args
    hyprctl_socat 'dispatch hl.dsp.dpms({ action = "enable" })'
}
