#!/usr/bin/env sh
# ============================================================================
# GUI password prompt for sudo's SUDO_ASKPASS interface.
#
# sudo invokes this program with the prompt text as $1 and reads the password
# from its stdout. It is used by darkwindow_hyprpm_sync.sh so that
# `hyprpm update` -- which shells out to `sudo` from an exec-once with no
# controlling tty -- can ask for the password through a graphical popup
# instead of failing with "no tty present and no askpass program specified".
# ============================================================================

prompt=${1:-"Authentication required"}

if command -v zenity >/dev/null 2>&1; then
    exec zenity --password --title="hyprpm 需要 root 權限" 2>/dev/null
elif [ -x /usr/lib/gcr4-ssh-askpass ]; then
    exec /usr/lib/gcr4-ssh-askpass "$prompt"
elif [ -x /usr/lib/gcr-ssh-askpass ]; then
    exec /usr/lib/gcr-ssh-askpass "$prompt"
fi

exit 1
