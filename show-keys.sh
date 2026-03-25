#!/bin/bash
# Show Hyprland keybindings in rofi
cat <<'EOF' | rofi -dmenu -i -p "Keybindings" -theme-str 'window {width: 600px;}'
Win+Return         Terminal (kitty)
Win+Shift+q        Kill window
Win+f              Fullscreen
Win+Shift+Space    Toggle floating
Win+p              Pseudo-tile
Win+j              Toggle split
Win+r              Resize mode (h/j/k/l, Esc to exit)
Win+h/j/k/l        Focus left/down/up/right
Win+Shift+h/j/k/l  Move window
Win+1-0            Switch workspace
Win+Shift+1-0      Move to workspace
Win+p              Workspace to right monitor
Win+o              Workspace to left monitor
Win+Space          App launcher
Win+d              App launcher
Win+Shift+e        Power menu
Print              Screenshot (full)
Win+Print          Screenshot (selection)
Win+F1             This help
EOF
