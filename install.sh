#!/usr/bin/env bash
# Install, update or reinstall ytcast on Arch Linux.
# Note: the PKGBUILD builds from GitHub, so only pushed commits are installed.
set -euo pipefail
cd "$(dirname "$0")"
git pull --ff-only
makepkg -sif   # -s deps, -i install, -f rebuild even if the version is unchanged
