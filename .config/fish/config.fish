# XDG fallback for contexts without the Hyprland session env (ssh, tty) —
# fastfetch's config expands $XDG_CONFIG_HOME and has no fallback of its own.
set -q XDG_CONFIG_HOME; or set -gx XDG_CONFIG_HOME $HOME/.config

if status is-interactive
    # Commands to run in interactive sessions can go here
    set fish_greeting
    fastfetch
end

# Start ssh-agent
if test -z "$SSH_AUTH_SOCK"
    ssh-agent -c | source
    if test -f ~/.ssh/ppk
        ssh-add ~/.ssh/ppk
    end
end

# Custom Aliases and Functions
alias ll='ls -alh --color=auto'
alias vi=vim

set -gx QT_QPA_PLATFORMTHEME qt6ct

# CUDA
# set -x CUDA_PATH "/opt/cuda"
# set -x LD_LIBRARY_PATH "$LD_LIBRARY_PATH /opt/cuda/lib64"
# set -x NVCC_CCBIN "/usr/bin/g++-14"

starship init fish | source