#!/usr/bin/env bash
#
# Local verification script for OpenWrt build (WSL2 Ubuntu 20.04)
# Project is located at E:\Project\OpenWrt (mounted as /mnt/e/Project/OpenWrt)
# Run this script from that folder.
#
# Usage:
#   ./verify-local.sh            # single-thread, verbose (good for first run)
#   ./verify-local.sh -j4        # multi-thread compile
#
set -e

JOBS=1
while [ $# -gt 0 ]; do
  case "$1" in
    -j*) JOBS="${1#-j}"; shift ;;
    *) shift ;;
  esac
done
[ -z "$JOBS" ] && JOBS=1

SRC_DIR="$HOME/openwrt-verify"
REPO_BRANCH="${REPO_BRANCH:-openwrt-24.10}"
REPO_URL="https://github.com/openwrt/openwrt"

PROJ_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "==> Project dir: $PROJ_DIR"
echo "==> Source dir: $SRC_DIR"
echo "==> Branch: $REPO_BRANCH"

# 1. Clone into a clean ext4 home dir (avoids Windows/NTFS path issues)
if [ -d "$SRC_DIR" ]; then
  echo "==> Removing existing $SRC_DIR"
  rm -rf "$SRC_DIR"
fi
git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" "$SRC_DIR"
cd "$SRC_DIR"

# 2. Apply feeds.conf from project folder
if [ -f "$PROJ_DIR/feeds.conf" ]; then
  cp "$PROJ_DIR/feeds.conf" feeds.conf
fi

# 3. diy-part1 (if present)
if [ -x "$PROJ_DIR/diy-part1.sh" ]; then
  echo "==> Running diy-part1.sh"
  "$PROJ_DIR/diy-part1.sh"
fi

# 4. Update & install feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 5. Apply .config and expand defaults
cp "$PROJ_DIR/.config" .config
make defconfig

# 6. diy-part2 (if present)
if [ -x "$PROJ_DIR/diy-part2.sh" ]; then
  echo "==> Running diy-part2.sh"
  "$PROJ_DIR/diy-part2.sh"
fi

# 7. Download sources
make download -j"$(nproc)"

# 8. Compile
if [ "$JOBS" = "1" ]; then
  make -j1 V=s
else
  make -j"$JOBS" V=s || make -j1 V=s
fi

# 9. Show result
echo "==> Build output:"
ls -lh bin/targets/ramips/mt7620/ 2>/dev/null || echo "No output found!"
