#!/bin/bash
# OpenVPN CLI + NetworkManager/Plasma integration for importing .ovpn profiles

set -ouex pipefail

dnf5 install -y \
    openvpn \
    NetworkManager-openvpn \
    plasma-nm-openvpn
