#!/bin/bash
# Deadband, a desktop configurator for GameSir controllers.

set -ouex pipefail

version=0.7.0
source_sha256=bb26745a93b4ded48d008c704c67cd814747a8309b094c9f54ecf2f5a1f66474
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

dnf5 install -y libusb1 python3-hidapi python3-pyside6

curl --fail --location --retry 3 \
    --output "$work_dir/deadband.tar.gz" \
    "https://codeload.github.com/broroeror/gamesir-linux-tools/tar.gz/refs/tags/v${version}"
printf '%s  %s\n' "$source_sha256" "$work_dir/deadband.tar.gz" | sha256sum --check -
tar -xzf "$work_dir/deadband.tar.gz" -C "$work_dir" --no-same-owner
cd "$work_dir/gamesir-linux-tools-${version}"

app_dir=/usr/share/deadband
install -d "$app_dir"
find . -maxdepth 1 -type f -name '*.py' ! -name '*test*.py' \
    -exec install -m 0644 -t "$app_dir" {} +
cp -r assets qml translations vendors "$app_dir/"
install -Dm644 LICENSE /usr/share/licenses/deadband/LICENSE

# Keep the rule beside the app for its built-in diagnostics as well.
install -Dm644 70-gamesir.rules "$app_dir/70-gamesir.rules"
install -Dm644 70-gamesir.rules /usr/lib/udev/rules.d/70-gamesir.rules

install -Dm644 packaging/deadband.desktop /usr/share/applications/deadband.desktop
install -Dm644 assets/icon.png /usr/share/icons/hicolor/256x256/apps/deadband.png
install -Dm755 /dev/stdin /usr/bin/deadband <<'EOF'
#!/bin/sh
exec /usr/bin/python3 /usr/share/deadband/deadband.py "$@"
EOF

python3 -c 'import hidraw; from PySide6 import QtMultimedia, QtQml, QtQuick'
test "$(deadband --version)" = "deadband ${version}"
