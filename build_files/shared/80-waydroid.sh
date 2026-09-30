#!/bin/bash
# Waydroid and its configuration GUI, shared by every image.

set -ouex pipefail

# Waydroid comes from Fedora; only the helper needs the upstream COPR.
dnf5 install -y waydroid
dnf5 -y copr enable cuteneko/waydroid-helper
dnf5 install -y waydroid-helper
# Updates arrive through image rebuilds, as with the other COPR packages.
dnf5 -y copr disable cuteneko/waydroid-helper

# Android images and container initialization belong on each installed machine,
# where /var/lib/waydroid persists across OS image updates.
