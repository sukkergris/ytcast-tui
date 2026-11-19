#!/usr/bin/env bash
# Install, update or reinstall ytcast on Arch Linux.
# Note: the PKGBUILD builds from GitHub, so only pushed commits are installed.
set -euo pipefail
cd "$(dirname "$0")"
git pull --ff-only
makepkg -sf   # -s deps, -f rebuild even if the version is unchanged
git checkout -- PKGBUILD   # makepkg rewrites pkgver on every build; keep the tree clean
# --overwrite takes over the files ./dev.sh copied to /usr/bin (pacman refuses files it doesn't own)
sudo pacman -U --overwrite /usr/bin/ytcast --overwrite /usr/bin/ytcast-player "$(makepkg --packagelist | grep -v -- -debug-)"
