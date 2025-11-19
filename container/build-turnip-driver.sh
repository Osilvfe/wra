#!/bin/bash
set -x
set -e

source() {
    command -v git &> /dev/null || apt-get install git ca-certificates -y --no-install-suggests --no-install-recommends
    [ ! -d "mesa" ] && git clone https://gitlab.freedesktop.org/zsnow/mesa --depth=1
    echo ""
}

build() {
    cd mesa || exit 1
    git pull
    
    # Fix: missing headers causing implicit declaration errors
    # We inject include directives at the top of the file
    if [ -f src/loader/loader_wayland_helper.c ]; then
        echo "Patching src/loader/loader_wayland_helper.c..."
        sed -i '1i #include <time.h>\n#include "util/timespec.h"' src/loader/loader_wayland_helper.c
    fi

    mkdir -p build
    cd build || exit 1
    command -v meson &> /dev/null || apt-get install meson ninja-build -y
    apt-get -y install python3-mako python3-yaml zlib1g-dev libexpat1-dev libdrm-dev bison flex cmake wayland-protocols \
    libwayland-dev xorg-dev libxml2-dev libxcb-dri2-0-dev libxcb-dri3-dev libxcb-glx0-dev libxcb-present-dev libxcb-randr0-dev \
    libxcb-shm0-dev libxcb-sync-dev libxcb-xfixes0-dev libxshmfence-dev libxcb1-dev libx11-xcb-dev libxcb-keysyms1-dev
    # Added --libdir to ensure correct install path for copy_built_files.sh
    meson setup '-Dfreedreno-kmds=['\''msm'\'','\''kgsl'\'']' '-Dgallium-drivers=[]' '-Dvulkan-drivers=['\''freedreno'\'']' --libdir=lib/aarch64-linux-gnu
    ninja
}

install() {
    ninja install
    strip --strip-unneeded /usr/local/lib/aarch64-linux-gnu/libvulkan_freedreno.so
}

case "$1" in
"source")
    source
    ;;
"build")
    build
    ;;
"install")
    install
    ;;
*)
    source
    build
    install
    ;;
esac
