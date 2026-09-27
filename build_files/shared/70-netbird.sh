#!/bin/bash
# NetBird daemon and desktop app - https://docs.netbird.io/get-started/install/linux

set -ouex pipefail

# Enable the signed upstream repository only for the image build transaction.
# Installed systems receive NetBird updates through image updates.
cat > /etc/yum.repos.d/netbird.repo <<'EOF'
[netbird]
name=NetBird
baseurl=https://pkgs.netbird.io/yum/
enabled=0
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://pkgs.netbird.io/yum/repodata/repomd.xml.key
EOF

# Install the documented UI dependencies with their normal RPM scriptlets.
dnf5 install -y \
    gtk4 \
    webkitgtk6.0 \
    xdg-utils

# Upstream's post-install scripts start the daemon/UI and require a running init
# system. Install dependencies normally above, then skip scripts for these two
# packages. Our image supplies the systemd unit instead of generating it live.
dnf5 install -y --enable-repo=netbird --setopt=tsflags=noscripts \
    netbird \
    netbird-ui

# Enrollment and device credentials are created separately on each machine.
systemctl enable netbird.service
