#!/usr/bin/env sh
HYPRGAMEMODE=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')
if [ "$HYPRGAMEMODE" = 1 ] ; then
    hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword decoration:shadow:enabled 0;\
        keyword decoration:blur:enabled 0;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 1;\
        keyword decoration:rounding 0"
    # kill quickshell or qs
    pkill -f quickshell
    pkill -f qs
    hyprctl keyword 'windowrule[windowrule-15]:enable false'
    hyprctl keyword 'windowrule[windowrule-16]:enable false'
    exit
fi

hyprctl reload
# if quickshell or qs is not running, start it
if ! pgrep -f quickshell >/dev/null && ! pgrep -f qs >/dev/null; then
    exec caelestia shell
    exec qs -c overview -d
    hyprctl keyword 'windowrule[windowrule-15]:enable true'
    hyprctl keyword 'windowrule[windowrule-16]:enable true'

fi