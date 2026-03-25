#!/bin/bash
# =============================================================================
# Hyprland Desktop Setup - Ubuntu 24.04 (Nvidia Hybrid GPU)
# =============================================================================
# Sets up Hyprland with grayscale theme, waybar, hyprlock, hypridle,
# rofi, donut OSD, wallpapers, multi-monitor, and Nvidia support.
#
# Usage:
#   git clone https://github.com/sudiarth/hyprland-dotfiles
#   cd hyprland-dotfiles
#   sudo ./build-hyprland.sh   # Build Hyprland v0.42.0 from source first
#   sudo ./install.sh          # Then install configs and tools
#
# After install, log out and select "Hyprland" from the session menu.
# =============================================================================

set -e

if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo: sudo ./install.sh"
    exit 1
fi

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(eval echo "~$REAL_USER")
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# =============================================================================
# 1. Check if Hyprland is installed (built from source via build-hyprland.sh)
# =============================================================================
if ! command -v Hyprland &>/dev/null; then
    echo ""
    echo "ERROR: Hyprland is not installed."
    echo ""
    echo "  Ubuntu 24.04 requires building Hyprland from source."
    echo "  Run the build script first:"
    echo ""
    echo "    sudo ./build-hyprland.sh"
    echo ""
    echo "  Then re-run this install script."
    exit 1
fi

echo "=== Hyprland found: $(Hyprland --version 2>&1 | head -1) ==="

# =============================================================================
# 2. Install packages
# =============================================================================
echo ""
echo "=== Installing packages ==="
apt update
apt install -y \
    git \
    curl \
    waybar \
    swaybg \
    dunst \
    rofi \
    grim \
    slurp \
    wl-clipboard \
    brightnessctl \
    playerctl \
    pavucontrol \
    network-manager-gnome \
    blueman \
    fonts-font-awesome \
    gnome-keyring \
    python3-gi \
    python3-cairo \
    gir1.2-gtk-3.0 \
    gir1.2-gtklayershell-0.1 \
    kitty \
    breeze-gtk-theme \
    breeze-icon-theme \
    breeze-cursor-theme \
    papirus-icon-theme

# =============================================================================
# 3. Install Poppins font
# =============================================================================
echo ""
echo "=== Installing Poppins font ==="
mkdir -p "$REAL_HOME/.local/share/fonts"
for weight in Regular Bold Medium; do
    curl -sL "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-${weight}.ttf" \
        -o "$REAL_HOME/.local/share/fonts/Poppins-${weight}.ttf"
done
chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.local/share/fonts"
sudo -u "$REAL_USER" fc-cache -f

# =============================================================================
# 4. Set up Hyprland config
# =============================================================================
echo ""
echo "=== Setting up Hyprland config ==="
mkdir -p "$REAL_HOME/.config/hypr"
cp "$SCRIPT_DIR/hyprland.conf" "$REAL_HOME/.config/hypr/hyprland.conf"
cp "$SCRIPT_DIR/hyprlock.conf" "$REAL_HOME/.config/hypr/hyprlock.conf"
cp "$SCRIPT_DIR/hypridle.conf" "$REAL_HOME/.config/hypr/hypridle.conf"
cp "$SCRIPT_DIR/show-keys.sh" "$REAL_HOME/.config/hypr/show-keys.sh"
cp "$SCRIPT_DIR/volume.sh" "$REAL_HOME/.config/hypr/volume.sh"
cp "$SCRIPT_DIR/brightness.sh" "$REAL_HOME/.config/hypr/brightness.sh"
cp "$SCRIPT_DIR/osd.py" "$REAL_HOME/.config/hypr/osd.py"
chmod +x "$REAL_HOME/.config/hypr/show-keys.sh"
chmod +x "$REAL_HOME/.config/hypr/volume.sh"
chmod +x "$REAL_HOME/.config/hypr/brightness.sh"
chmod +x "$REAL_HOME/.config/hypr/osd.py"
chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/hypr"

# =============================================================================
# 5. Set up Waybar config
# =============================================================================
echo ""
echo "=== Setting up Waybar ==="
mkdir -p "$REAL_HOME/.config/waybar"
cp "$SCRIPT_DIR/waybar/config.jsonc" "$REAL_HOME/.config/waybar/config.jsonc"
cp "$SCRIPT_DIR/waybar/style.css" "$REAL_HOME/.config/waybar/style.css"
chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/waybar"

# =============================================================================
# 6. Set up adi1090x rofi themes
# =============================================================================
echo ""
echo "=== Setting up adi1090x/rofi themes ==="
if [ ! -d "$REAL_HOME/.config/rofi/launchers" ]; then
    ROFI_TMP=$(mktemp -d)
    sudo -u "$REAL_USER" git clone --depth 1 https://github.com/adi1090x/rofi.git "$ROFI_TMP"
    sudo -u "$REAL_USER" bash "$ROFI_TMP/setup.sh" <<< "Y" || true
    rm -rf "$ROFI_TMP"

    # Apply Nord color scheme
    echo "=== Applying Nord color scheme to rofi ==="
    for colors_file in $(find "$REAL_HOME/.config/rofi" -path "*/shared/colors.rasi"); do
        cat > "$colors_file" << 'RASI'
/**
 *
 * Author : Aditya Shakya (adi1090x)
 * Github : @adi1090x
 *
 * Colors
 *
 **/

/* Import color-scheme from `colors` directory */

@import "~/.config/rofi/colors/nord.rasi"
RASI
        chown "$REAL_USER:$REAL_USER" "$colors_file"
    done
else
    echo "Rofi themes already installed, skipping."
fi

# =============================================================================
# 7. Copy wallpapers
# =============================================================================
echo ""
echo "=== Copying wallpapers ==="
mkdir -p "$REAL_HOME/Pictures/wallpapers"
if [ -d "$SCRIPT_DIR/wallpapers" ]; then
    cp "$SCRIPT_DIR/wallpapers/"* "$REAL_HOME/Pictures/wallpapers/" 2>/dev/null || true
fi
chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/Pictures/wallpapers"

# =============================================================================
# 8. GTK theme
# =============================================================================
echo ""
echo "=== Applying GTK settings ==="
mkdir -p "$REAL_HOME/.config/gtk-4.0"
cat > "$REAL_HOME/.config/gtk-4.0/gtk.css" << 'CSS'
/* Remove libadwaita forced rounded corners */
window, window.background {
    border-radius: 0;
}
CSS
chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/gtk-4.0/gtk.css"

sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u $REAL_USER)/bus" \
    gsettings set org.gnome.desktop.interface gtk-theme 'Breeze-Dark' 2>/dev/null || true
sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u $REAL_USER)/bus" \
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u $REAL_USER)/bus" \
    gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true

# =============================================================================
# Done
# =============================================================================
echo ""
echo "========================================="
echo "  Hyprland setup complete!"
echo "========================================="
echo ""
echo "  Log out and select 'Hyprland' from"
echo "  the session menu at the login screen."
echo ""
echo "  Keybindings:"
echo "    Win+Return       Terminal (kitty)"
echo "    Win+Space        App launcher (rofi)"
echo "    Win+Shift+q      Kill window"
echo "    Win+Shift+e      Power menu"
echo "    Win+f            Fullscreen"
echo "    Win+r            Resize mode"
echo "    Win+h/j/k/l      Focus left/down/up/right"
echo "    Win+1-0          Switch workspace"
echo "    Win+p/o          Move workspace between monitors"
echo "    Win+F1           Show all keybindings"
echo "    Print            Screenshot"
echo ""
echo "  Idle behavior:"
echo "    3 min            Screen dims"
echo "    5 min            Screen locks (hyprlock)"
echo "    8 min            Display off"
echo "    15 min           Suspend"
echo ""
echo "  Settings apps:"
echo "    pavucontrol          Sound / Volume"
echo "    nm-connection-editor Network / WiFi"
echo "    blueman-manager      Bluetooth"
echo ""
