#!/usr/bin/env bash
# Development tooling for the shell on a throwaway Ubuntu 24.04 box (the
# cloud sessions Claude works in), not for your machine: there, `qs` comes
# from the distro. Idempotent; each step is skipped when already done.
#
#   qmllint, qml   from PySide6 (Qt 6.12, as on the desktop)
#   qs             Quickshell v0.3.2 built against a Qt 6.12 SDK (aqtinstall)
#   sway, grim     a headless compositor to run it in, and screenshots
#                  (scripts/preview.sh)
#
#     scripts/dev-env.sh        (as root; ~10 minutes the first time)
set -euo pipefail

QT_VERSION=6.12.0
QS_VERSION=v0.3.2
QT=/opt/qt/$QT_VERSION/gcc_64
QS=/opt/quickshell

export DEBIAN_FRONTEND=noninteractive

step() { echo "== $*"; }

if ! command -v pyside6-qmllint >/dev/null || ! command -v aqt >/dev/null; then
    step "PySide6 (qmllint, qml) and aqtinstall"
    pip3 install --break-system-packages -q PySide6 aqtinstall
fi

if [[ ! -d $QT ]]; then
    step "Qt $QT_VERSION SDK"
    aqt install-qt linux desktop "$QT_VERSION" linux_gcc_64 \
        -m qtshadertools qt5compat qtimageformats qtmultimedia -O /opt/qt
fi

step "build and runtime packages"
apt-get update -qq
apt-get install -y -qq cmake ninja-build pkg-config wayland-protocols libwayland-dev \
    libdrm-dev libgbm-dev libegl-dev libgl-dev libvulkan-dev libxkbcommon-dev \
    libjemalloc-dev spirv-tools libpipewire-0.3-dev libpam0g-dev libpolkit-agent-1-dev \
    libpolkit-gobject-1-dev libglib2.0-dev libxcb1-dev sway grim fontconfig >/dev/null

mkdir -p /opt/src
if [[ ! -f /usr/local/share/cmake/CLI11/CLI11Config.cmake && ! -f /usr/local/lib/cmake/CLI11/CLI11Config.cmake ]]; then
    step "CLI11 (not packaged on 24.04)"
    rm -rf /opt/src/CLI11
    git clone -q --depth 1 --branch v2.4.2 https://github.com/CLIUtils/CLI11 /opt/src/CLI11
    cmake -S /opt/src/CLI11 -B /opt/src/CLI11/build -G Ninja \
        -DCLI11_BUILD_TESTS=OFF -DCLI11_BUILD_EXAMPLES=OFF -DCLI11_BUILD_DOCS=OFF >/dev/null
    cmake --install /opt/src/CLI11/build >/dev/null
fi

if [[ ! -x $QS/bin/quickshell ]]; then
    step "Quickshell $QS_VERSION"
    rm -rf /opt/src/quickshell
    git clone -q --depth 1 --branch "$QS_VERSION" https://github.com/quickshell-mirror/quickshell /opt/src/quickshell
    cmake -S /opt/src/quickshell -B /opt/src/quickshell/build -G Ninja \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_PREFIX_PATH="$QT" -DCMAKE_INSTALL_PREFIX="$QS" \
        -DCRASH_HANDLER=OFF -DDISTRIBUTOR=claude-cloud-dev >/dev/null
    cmake --build /opt/src/quickshell/build -j"$(nproc)"
    cmake --install /opt/src/quickshell/build >/dev/null
fi

# qs finds the SDK's libraries and QML modules through these.
cat >/usr/local/bin/qs <<EOF
#!/bin/sh
export LD_LIBRARY_PATH="$QT/lib\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="$QT/plugins"
export QML_IMPORT_PATH="$QS/lib/qt-6/qml:$QT/qml"
exec "$QS/bin/quickshell" "\$@"
EOF
chmod +x /usr/local/bin/qs
ln -sf "$(command -v pyside6-qmllint)" /usr/local/bin/qmllint

step "done: $(qs --version 2>/dev/null | head -1)"
