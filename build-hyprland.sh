#!/bin/bash
# =============================================================================
# Build Hyprland v0.42.0 from source for Ubuntu 24.04 (gcc-13)
# =============================================================================
# Hyprland v0.42.0 is the last version using C++23 (gcc-13 compatible).
# Newer versions require C++26 (gcc-15+), which is not available on 24.04.
#
# This script builds the full Hyprland ecosystem in the correct order:
#   1. hyprutils      v0.2.1
#   2. hyprlang       v0.5.2
#   3. hyprcursor     v0.1.9
#   4. hyprwayland-scanner v0.4.0
#   5. aquamarine     v0.3.1
#   6. Hyprland       v0.42.0
#   7. hyprlock       v0.4.1
#   8. hypridle       v0.1.2
#
# Usage:
#   sudo ./build-hyprland.sh
#
# Build time: ~10-20 minutes depending on CPU
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
echo ""

# =============================================================================
# 1. Install build dependencies
# =============================================================================
echo "=== [1/9] Installing build dependencies ==="
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
    cpio jq git

# =============================================================================
# 2. Prepare build directory
# =============================================================================
echo ""
echo "=== [2/9] Setting up build directory ==="
mkdir -p "$BUILD_DIR"
chown "$REAL_USER:$REAL_USER" "$BUILD_DIR"

build_cmake_project() {
    local name="$1"
    local repo="$2"
    local tag="$3"
    local extra_flags="${4:-}"

    echo ""
    echo "--- Building $name ($tag) ---"

    cd "$BUILD_DIR"
    if [ -d "$name" ]; then
        echo "  Directory exists, removing..."
        rm -rf "$name"
    fi

    sudo -u "$REAL_USER" git clone --recursive --depth 1 -b "$tag" "$repo" "$name"
    cd "$name"

    cmake -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_INSTALL_PREFIX=/usr \
          $extra_flags \
          -S . -B build -G Ninja

    cmake --build build -j"$JOBS"
    cmake --install build

    echo "  $name installed successfully."
}

build_meson_project() {
    local name="$1"
    local repo="$2"
    local tag="$3"

    echo ""
    echo "--- Building $name ($tag) ---"

    cd "$BUILD_DIR"
    if [ -d "$name" ]; then
        echo "  Directory exists, removing..."
        rm -rf "$name"
    fi

    sudo -u "$REAL_USER" git clone --recursive --depth 1 -b "$tag" "$repo" "$name"
    cd "$name"

    sudo -u "$REAL_USER" meson setup build --prefix=/usr --buildtype=release
    ninja -C build -j"$JOBS"
    ninja -C build install

    echo "  $name installed successfully."
}

# =============================================================================
# 3. Build hyprutils v0.2.1
# =============================================================================
echo ""
echo "=== [3/9] Building hyprutils ==="
build_cmake_project "hyprutils" \
    "https://github.com/hyprwm/hyprutils.git" \
    "v0.2.1"

# Update shared library cache after each install
ldconfig

# =============================================================================
# 4. Build hyprlang v0.5.2
# =============================================================================
echo ""
echo "=== [4/9] Building hyprlang ==="
build_cmake_project "hyprlang" \
    "https://github.com/hyprwm/hyprlang.git" \
    "v0.5.2"

ldconfig

# =============================================================================
# 5. Build hyprcursor v0.1.9
# =============================================================================
echo ""
echo "=== [5/9] Building hyprcursor ==="
build_cmake_project "hyprcursor" \
    "https://github.com/hyprwm/hyprcursor.git" \
    "v0.1.9"

ldconfig

# =============================================================================
# 6. Build hyprwayland-scanner v0.4.0
# =============================================================================
echo ""
echo "=== [6/9] Building hyprwayland-scanner ==="
build_cmake_project "hyprwayland-scanner" \
    "https://github.com/hyprwm/hyprwayland-scanner.git" \
    "v0.4.0"

ldconfig

# =============================================================================
# 7. Build aquamarine v0.3.1
# =============================================================================
echo ""
echo "=== [7/9] Building aquamarine ==="
build_cmake_project "aquamarine" \
    "https://github.com/hyprwm/aquamarine.git" \
    "v0.3.1"

ldconfig

# =============================================================================
# 8. Build Hyprland v0.42.0
# =============================================================================
echo ""
echo "=== [8/9] Building Hyprland v0.42.0 ==="

cd "$BUILD_DIR"
if [ -d "Hyprland" ]; then
    rm -rf "Hyprland"
fi

sudo -u "$REAL_USER" git clone --recursive --depth 1 -b "v0.42.0" \
    "https://github.com/hyprwm/Hyprland.git" "Hyprland"
cd "Hyprland"

cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -S . -B build -G Ninja

cmake --build build -j"$JOBS"
cmake --install build

ldconfig

echo "  Hyprland v0.42.0 installed successfully."

# =============================================================================
# 9. Build hyprlock v0.4.1 and hypridle v0.1.2
# =============================================================================
echo ""
echo "=== [9/9] Building hyprlock and hypridle ==="

build_cmake_project "hyprlock" \
    "https://github.com/hyprwm/hyprlock.git" \
    "v0.4.1"

ldconfig

build_cmake_project "hypridle" \
    "https://github.com/hyprwm/hypridle.git" \
    "v0.1.2"

ldconfig

# =============================================================================
# Verify installation
# =============================================================================
echo ""
echo "========================================="
echo "  Build complete!"
echo "========================================="
echo ""

if command -v Hyprland &>/dev/null; then
    echo "  Hyprland: $(Hyprland --version 2>&1 | head -1)"
else
    echo "  WARNING: Hyprland binary not found in PATH"
fi

if command -v hyprlock &>/dev/null; then
    echo "  hyprlock: installed"
else
    echo "  WARNING: hyprlock not found"
fi

if command -v hypridle &>/dev/null; then
    echo "  hypridle: installed"
else
    echo "  WARNING: hypridle not found"
fi

echo ""
echo "  Build files are in: $BUILD_DIR"
echo "  You can remove them to save space:"
echo "    rm -rf $BUILD_DIR"
echo ""
echo "  Now run the dotfiles install script:"
echo "    cd ~/hyprland-dotfiles && sudo ./install.sh"
echo ""
