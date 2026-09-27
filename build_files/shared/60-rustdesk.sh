#!/bin/bash
# Latest upstream unattended Wayland preview.
# This installs the Debian archive's payload, not its maintainer scripts.

set -ouex pipefail

[[ "$(uname -m)" == x86_64 ]]

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

# Old versions can remain attached to the nightly release. Select the newest
# uploaded unattended-Wayland x86_64 Debian asset, never the ordinary build.
curl --fail --location --retry 3 \
    --output "${work_dir}/release.json" \
    https://api.github.com/repos/rustdesk/rustdesk/releases/tags/nightly
jq --exit-status '
    [.assets[] | select(.state == "uploaded") |
        select(.name | test("^rustdesk-unattended-wayland-.+-x86_64\\.deb$"))] |
    sort_by(.created_at, .id) | last |
    if . == null then error("No unattended Wayland nightly asset found") else . end
' "${work_dir}/release.json" > "${work_dir}/asset.json"
asset_url="$(jq --exit-status --raw-output '.url' "${work_dir}/asset.json")"
asset_sha256="$(jq --exit-status --raw-output \
    '.digest | capture("^sha256:(?<hash>[0-9a-f]{64})$") | .hash' \
    "${work_dir}/asset.json")"

curl --fail --location --retry 3 \
    --header 'Accept: application/octet-stream' \
    --output "${work_dir}/rustdesk.deb" "$asset_url"
echo "${asset_sha256}  ${work_dir}/rustdesk.deb" | sha256sum --check -
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
install -Dm644 "${work_dir}/asset.json" \
    /usr/share/aurora-base-image/rustdesk-nightly-asset.json

# Fail the build if the payload or its directly linked dependencies stop working.
test -n "$(/usr/bin/rustdesk --version)"
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
