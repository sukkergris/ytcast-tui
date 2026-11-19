#!/usr/bin/env bash
# Developer install: copy the local bin/ (incl. uncommitted changes) over the installed files.
# Needs python-pychromecast and yt-dlp (sudo pacman -S python-pychromecast yt-dlp). ./install.sh puts the packaged version back.
set -euo pipefail
cd "$(dirname "$0")"
sudo install -vDm755 bin/ytcast /usr/bin/ytcast
sudo install -vDm755 bin/ytcast-player /usr/bin/ytcast-player
