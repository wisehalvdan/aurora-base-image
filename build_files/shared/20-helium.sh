#!/bin/bash
# Helium browser - https://github.com/imputnet/helium-linux

set -ouex pipefail

dnf5 -y copr enable imput/helium
dnf5 -y install helium-bin
dnf5 -y copr disable imput/helium
