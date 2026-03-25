#!/bin/bash
# Brightness control with donut OSD (Wayland)

case "$1" in
    up)   brightnessctl set +5%;;
    down) brightnessctl set 5%-;;
esac

BRIGHT=$(brightnessctl -m | cut -d, -f4 | tr -d '%')

pkill -f "python3.*osd.py" 2>/dev/null

python3 ~/.config/hypr/osd.py "" "$BRIGHT" &
