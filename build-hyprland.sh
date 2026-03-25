#!/bin/bash
# =============================================================================
# Build Hyprland v0.42.0 from source for Ubuntu 24.04 (gcc-13)
# =============================================================================
# v0.42.0 is the last C++23 release. v0.43.0+ requires C++26 / gcc-15+.
#
# Builds everything in order, skipping already-installed components:
#   hyprutils -> hyprlang -> hyprcursor -> hyprwayland-scanner ->
#   libinput (1.26.0) -> aquamarine -> Hyprland -> hyprlock -> hypridle
#
# Safe to re-run -- picks up where it left off.
#
# Usage:  sudo ./build-hyprland.sh
# =============================================================================

set -e

if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo: sudo ./build-hyprland.sh"
    exit 1
fi

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(eval echo "~$REAL_USER")
BUILD_DIR="$REAL_HOME/hyprland-build"
JOBS=$(nproc 2>/dev/null || echo 4)

echo "========================================="
echo "  Building Hyprland v0.42.0 for Ubuntu 24.04"
echo "  Using $JOBS parallel jobs"
echo "========================================="

# =============================================================================
# Install ALL build dependencies up front
# =============================================================================
echo ""
echo "=== Installing build dependencies ==="
apt update
apt install -y \
    build-essential cmake ninja-build meson pkg-config \
    libwayland-dev wayland-protocols \
    libxkbcommon-dev uuid-dev \
    libcairo2-dev libpango1.0-dev \
    libpixman-1-dev libxcursor-dev \
    libdrm-dev libinput-dev hwdata \
    libseat-dev libdisplay-info-dev libliftoff-dev \
    libudev-dev libgbm-dev \
    libgles-dev libegl-dev libegl1-mesa-dev \
    libxcb1-dev libxcb-util-dev libxcb-render0-dev \
    libxcb-xfixes0-dev libxcb-icccm4-dev libxcb-composite0-dev \
    libxcb-res0-dev libxcb-ewmh-dev libxcb-dri3-dev \
    libxcb-present-dev libxcb-xinput-dev \
    xwayland \
    glslang-tools \
    libtomlplusplus-dev \
    libzip-dev librsvg2-dev libxcb-render-util0-dev \
    libpam0g-dev libsdbus-c++-dev \
    libpugixml-dev \
    libmtdev-dev libevdev-dev libwacom-dev \
    check python3-pytest python3-attr \
    cpio jq git

mkdir -p "$BUILD_DIR"
chown "$REAL_USER:$REAL_USER" "$BUILD_DIR"

# =============================================================================
# Helper: build a cmake project (clone, build, install)
# =============================================================================
build_cmake() {
    local name="$1" repo="$2" tag="$3"

    echo ""
    echo "--- Building $name ($tag) ---"
    cd "$BUILD_DIR"
    [ -d "$name" ] && rm -rf "$name"
    sudo -u "$REAL_USER" git clone --recursive --depth 1 -b "$tag" "$repo" "$name"
    cd "$name"
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -S . -B build -G Ninja
    cmake --build build -j"$JOBS"
    cmake --install build
    ldconfig
    echo "  $name ($tag) installed."
}

# =============================================================================
# Helper: build a meson project (clone, build, install)
# =============================================================================
build_meson() {
    local name="$1" repo="$2" tag="$3" extra_opts="${4:-}"

    echo ""
    echo "--- Building $name ($tag) ---"
    cd "$BUILD_DIR"
    [ -d "$name" ] && rm -rf "$name"
    sudo -u "$REAL_USER" git clone --recursive --depth 1 -b "$tag" "$repo" "$name"
    cd "$name"
    meson setup build --prefix=/usr --buildtype=release $extra_opts
    ninja -C build -j"$JOBS"
    ninja -C build install
    ldconfig
    echo "  $name ($tag) installed."
}

# =============================================================================
# Build ecosystem in order, skipping what's already installed
# =============================================================================

if pkg-config --exact-version=0.2.1 hyprutils 2>/dev/null; then
    echo ""; echo "=== hyprutils v0.2.1 already installed, skipping ==="
else
    build_cmake hyprutils https://github.com/hyprwm/hyprutils.git v0.2.1
fi

if pkg-config --exact-version=0.5.2 hyprlang 2>/dev/null; then
    echo ""; echo "=== hyprlang v0.5.2 already installed, skipping ==="
else
    build_cmake hyprlang https://github.com/hyprwm/hyprlang.git v0.5.2
fi

if pkg-config --exact-version=0.1.9 hyprcursor 2>/dev/null; then
    echo ""; echo "=== hyprcursor v0.1.9 already installed, skipping ==="
else
    build_cmake hyprcursor https://github.com/hyprwm/hyprcursor.git v0.1.9
fi

if command -v hyprwayland-scanner &>/dev/null; then
    echo ""; echo "=== hyprwayland-scanner already installed, skipping ==="
else
    build_cmake hyprwayland-scanner https://github.com/hyprwm/hyprwayland-scanner.git v0.4.0
fi

if pkg-config --atleast-version=1.26.0 libinput 2>/dev/null; then
    echo ""; echo "=== libinput >= 1.26.0 already installed, skipping ==="
else
    build_meson libinput https://gitlab.freedesktop.org/libinput/libinput.git 1.26.0 \
        "-Ddocumentation=false -Dtests=false -Ddebug-gui=false"
fi

if pkg-config --exists aquamarine 2>/dev/null; then
    echo ""; echo "=== aquamarine already installed, skipping ==="
else
    build_cmake aquamarine https://github.com/hyprwm/aquamarine.git v0.3.1
fi

if command -v Hyprland &>/dev/null; then
    echo ""; echo "=== Hyprland already installed, skipping ==="
else
    echo ""
    echo "--- Building Hyprland (v0.42.0) ---"
    cd "$BUILD_DIR"
    [ -d "Hyprland" ] && rm -rf "Hyprland"
    sudo -u "$REAL_USER" git clone --recursive --depth 1 -b v0.42.0 \
        https://github.com/hyprwm/Hyprland.git Hyprland
    cd Hyprland
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -S . -B build -G Ninja
    cmake --build build -j"$JOBS"
    cmake --install build
    ldconfig
    echo "  Hyprland v0.42.0 installed."
fi

if command -v hyprlock &>/dev/null; then
    echo ""; echo "=== hyprlock already installed, skipping ==="
else
    build_cmake hyprlock https://github.com/hyprwm/hyprlock.git v0.4.1
fi

if command -v hypridle &>/dev/null; then
    echo ""; echo "=== hypridle already installed, skipping ==="
else
    build_cmake hypridle https://github.com/hyprwm/hypridle.git v0.1.2
fi

# =============================================================================
# Done
# =============================================================================
echo ""
echo "========================================="
echo "  Build complete!"
echo "========================================="
command -v Hyprland &>/dev/null && echo "  Hyprland: $(Hyprland --version 2>&1 | head -1)"
command -v hyprlock &>/dev/null && echo "  hyprlock: installed"
command -v hypridle &>/dev/null && echo "  hypridle: installed"
echo ""
echo "  Now run: sudo ./install.sh"
echo ""
