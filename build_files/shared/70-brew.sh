#!/bin/bash
# Homebrew formulae come from /usr/share/aurora-base-image/Brewfile and are
# installed per user after login (Homebrew lives in /home, not in the image).

set -ouex pipefail

systemctl --global enable aurora-base-image-brew.service
