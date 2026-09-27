#!/bin/bash
# Ghostty terminal - https://ghostty.org/docs/install/binary

set -ouex pipefail

dnf5 -y copr enable scottames/ghostty
dnf5 -y install ghostty
# Disable COPRs so they don't end up enabled on the final image;
# updates arrive through the daily image rebuild instead.
dnf5 -y copr disable scottames/ghostty
