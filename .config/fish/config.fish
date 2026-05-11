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
# alias sunshine=~/.local/bin/sunshine.sh

set -gx QT_QPA_PLATFORMTHEME qt6ct

starship init fish | source