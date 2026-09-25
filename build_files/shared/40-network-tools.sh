#!/bin/bash
# Network analysis tools from Fedora repos

set -ouex pipefail

# Wireshark (Qt GUI + dumpcap). Capturing needs membership in the
# "wireshark" group, see README.
dnf5 install -y \
    wireshark \
    nmap
