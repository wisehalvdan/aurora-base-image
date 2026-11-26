#!/bin/bash
# Tagged upstream unattended Wayland build.
# This installs the Debian archive's payload, not its maintainer scripts.

set -ouex pipefail

[[ "$(uname -m)" == x86_64 ]]

rustdesk_version=1.5.3
asset_sha256=708f390c46c357b72255ed6a1560da644c8381c51dd9b108cbf2a3ceca733e0d
asset_name="rustdesk-unattended-wayland-${rustdesk_version}-x86_64.deb"
asset_url="https://github.com/rustdesk/rustdesk/releases/download/${rustdesk_version}/${asset_name}"
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

# bsdtar extracts both the ar container and its data archive. Runtime libraries
# are installed explicitly rather than relying on the current Aurora package set.
dnf5 install -y \
    bsdtar \
    jq \
    gtk3 \
    libxcb \
    libXfixes \
    alsa-lib \
    libva \
    libdrm \
    libglvnd-egl \
    libglvnd-gles \
    gstreamer1-plugins-base \
    libayatana-appindicator-gtk3 \
    libxdo

curl --fail --location --retry 3 \
    --output "${work_dir}/rustdesk.deb" "$asset_url"
printf '%s  %s\n' "$asset_sha256" "$work_dir/rustdesk.deb" | sha256sum --check -
bsdtar -xf "${work_dir}/rustdesk.deb" -C "$work_dir" data.tar.xz
mkdir "${work_dir}/payload"
bsdtar -xf "${work_dir}/data.tar.xz" -C "${work_dir}/payload"

# Keep the upstream Flutter bundle and private DRM library at their expected
# paths. Do not copy Debian service setup, autostart, or package scripts.
cp -a "${work_dir}/payload/usr/share/rustdesk" /usr/share/
cp -a "${work_dir}/payload/usr/lib/rustdesk" /usr/lib/
cp -a "${work_dir}/payload/usr/share/icons"/. /usr/share/icons/
install -Dm644 "${work_dir}/payload/usr/share/applications/rustdesk.desktop" \
    /usr/share/applications/rustdesk.desktop
install -Dm644 "${work_dir}/payload/usr/share/applications/rustdesk-link.desktop" \
    /usr/share/applications/rustdesk-link.desktop
ln -s ../share/rustdesk/rustdesk /usr/bin/rustdesk
# Keep the exact asset identity and checksum in each image for diagnostics.
jq --null-input --arg name "$asset_name" --arg url "$asset_url" \
    --arg digest "sha256:${asset_sha256}" \
    '{name: $name, browser_download_url: $url, digest: $digest}' > "$work_dir/asset.json"
install -Dm644 "${work_dir}/asset.json" \
    /usr/share/aurora-base-image/rustdesk-asset.json
ln -sfn rustdesk-asset.json /usr/share/aurora-base-image/rustdesk-nightly-asset.json

# Fail the build if the payload or its directly linked dependencies stop working.
test "$(/usr/bin/rustdesk --version)" = "$rustdesk_version"
test -f /usr/lib/rustdesk/libdrmtap.so.0
grep -aFq '/usr/lib/rustdesk/libdrmtap.so.0' /usr/share/rustdesk/lib/librustdesk.so
for elf in /usr/share/rustdesk/rustdesk /usr/share/rustdesk/lib/*.so /usr/lib/rustdesk/libdrmtap.so.0; do
    dependencies="$(LD_LIBRARY_PATH=/usr/share/rustdesk/lib ldd "$elf")"
    if [[ "$dependencies" == *"not found"* ]]; then
        echo "Missing RustDesk dependency in ${elf}: ${dependencies}" >&2
        exit 1
    fi
done

systemctl enable rustdesk-drm.service
