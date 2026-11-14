#!/bin/bash
# Rex server and CLI - https://www.superlogical.com/rex/docs/linux/installation

set -ouex pipefail

# Install from the signed preview repository during the image build only.
# Rex updates arrive through image rebuilds, like the other shared packages.
cat > /etc/yum.repos.d/rex.repo <<'EOF'
[rex]
name=Rex (preview)
baseurl=https://pkgs.superlogical.com/rex/rpm/preview/$basearch
enabled=0
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://pkgs.superlogical.com/rex/keys/rex.asc
EOF

dnf5 install -y --refresh --enable-repo=rex rex
rex version

# Each user sets up their personal server after boot with `rex server install`.
