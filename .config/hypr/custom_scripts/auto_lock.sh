while ! qs -c caelestia log | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,3})*)?[mGK]//g" | grep " INFO: Configuration Loaded"; do
  sleep 0.01
done
hyprctl dispatch global caelestia:lock