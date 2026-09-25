#!/bin/bash
# Plain packages from Fedora / RPMFusion repos, shared by every image.

set -ouex pipefail

dnf5 install -y \
    tmux

systemctl enable podman.socket
