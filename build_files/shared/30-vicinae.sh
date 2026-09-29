#!/bin/bash
# Vicinae launcher - https://docs.vicinae.com/install/linux

set -ouex pipefail

dnf5 -y copr enable quadratech188/vicinae
# Install Node.js explicitly so extensions work even if weak dependencies are off.
dnf5 -y install vicinae nodejs
# Updates arrive through image rebuilds, as with the other COPR packages.
dnf5 -y copr disable quadratech188/vicinae

# Upstream's user unit follows graphical-session.target, so the server starts
# with Plasma and stops at logout. Enable for all users without starting it
# inside the image build (which has no graphical session or user bus).
systemctl --global enable vicinae.service

vicinae version
node --version
