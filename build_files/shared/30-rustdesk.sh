#!/bin/bash
# RustDesk - official RPM from https://github.com/rustdesk/rustdesk/releases
# No dnf repo is published; the daily image rebuild picks up new releases.

set -ouex pipefail

REPO="https://github.com/rustdesk/rustdesk"

# Resolve the latest tag from the redirect (avoids GitHub API rate limits in CI)
TAG=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "${REPO}/releases/latest" | sed 's#.*/tag/##')
RPM="rustdesk-${TAG}-0.x86_64.rpm"

curl -fsSL --retry 3 -o "/tmp/${RPM}" "${REPO}/releases/download/${TAG}/${RPM}"
dnf5 install -y "/tmp/${RPM}"
rm -f "/tmp/${RPM}"

# The RPM's %post writes the unit to /etc and tries to enable/start it.
# Ship the unit from /usr instead and leave it disabled; the service is only
# needed to accept incoming connections. Enable per machine with:
#   sudo systemctl enable --now rustdesk
if [[ -f /etc/systemd/system/rustdesk.service ]]; then
    mv /etc/systemd/system/rustdesk.service /usr/lib/systemd/system/rustdesk.service
else
    install -Dm644 /usr/share/rustdesk/files/rustdesk.service /usr/lib/systemd/system/rustdesk.service
fi
find /etc/systemd/system -name 'rustdesk.service' -type l -delete

# Make sure %post side effects exist even if the scriptlet failed in the build container
[[ -e /usr/bin/rustdesk ]] || ln -s /usr/share/rustdesk/rustdesk /usr/bin/rustdesk
for desktop in rustdesk.desktop rustdesk-link.desktop; do
    if [[ -f "/usr/share/rustdesk/files/${desktop}" && ! -f "/usr/share/applications/${desktop}" ]]; then
        install -Dm644 "/usr/share/rustdesk/files/${desktop}" "/usr/share/applications/${desktop}"
    fi
done
