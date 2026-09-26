#!/usr/bin/env bash
#
# Build TWRP 3.7.0_9 for the iNet / Allwinner RQ-713 (astar_ibt, A33/sun8i).
#
# The build uses the official TWRP minimal manifest (twrp-6.0 branch = AOSP
# 6.0.1_r74 platform, which is the right base for this kernel 3.4.39 device).
#
# Requirements (Linux x86_64, not macOS):
#   - Ubuntu 20.04 or 22.04 (or the provided docker/Dockerfile)
#   - ~40 GB free disk, 4 GB+ RAM, repo, git, JDK 8, python2, python3
#   - gcc-multilib, g++-multilib, lib32ncurses-dev, libgl1-mesa-dev, ...
#
# Usage:
#   ./build_twrp.sh                 # build with default paths
#   BUILD_DIR=/ssd/twrp ./build_twrp.sh
#   JOBS=8 ./build_twrp.sh
#
# The finished image is copied to ./out/twrp-astar_ibt-recovery.img
# and verified against the stock boot layout automatically.
#

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT/build/twrp-6.0}"
OUT_DIR="${OUT_DIR:-$ROOT/out}"
JOBS="${JOBS:-$(nproc)}"
MANIFEST_URL="https://github.com/minimal-manifest-twrp/platform_manifest_twrp_omni.git"
MANIFEST_BRANCH="twrp-6.0"
DEVICE_PATH="device/softwinner/astar_ibt"

log() { printf '\n==> %s\n' "$*"; }

for tool in repo git python3 curl; do
    command -v "$tool" >/dev/null 2>&1 || {
        echo "error: '$tool' is required but was not found in PATH" >&2
        echo "       (see docker/Dockerfile for a ready-made environment)" >&2
        exit 1
    }
done

if [ "$(uname -s)" != "Linux" ]; then
    echo "error: recovery builds require Linux x86_64 (the prebuilt toolchains are Linux binaries)." >&2
    echo "       Use docker/build.sh from macOS or build on a Linux machine." >&2
    exit 1
fi

mkdir -p "$BUILD_DIR" "$OUT_DIR"
cd "$BUILD_DIR"

if [ ! -d .repo ]; then
    log "Initialising TWRP minimal manifest ($MANIFEST_BRANCH)"
    repo init -u "$MANIFEST_URL" -b "$MANIFEST_BRANCH" --depth=1
fi

log "Syncing source tree (this downloads ~10-15 GB on first run)"
repo sync -c -j"$JOBS" --force-sync --no-clone-bundle --no-tags

log "Installing device tree into $DEVICE_PATH"
rm -rf "$DEVICE_PATH"
mkdir -p "$(dirname "$DEVICE_PATH")"
cp -a "$ROOT/device/softwinner/astar_ibt" "$DEVICE_PATH"

log "Building recovery image (-j$JOBS)"
# envsetup.sh/lunch predate `set -u` discipline: run them without it.
set +eu
# shellcheck disable=SC1091
source build/envsetup.sh
lunch "omni_astar_ibt-eng"
set -eu
if [ "${TARGET_PRODUCT:-}" != "omni_astar_ibt" ]; then
    echo "error: lunch omni_astar_ibt-eng failed (TARGET_PRODUCT='${TARGET_PRODUCT:-}')" >&2
    exit 1
fi
make -j"$JOBS" recoveryimage

BUILT_IMG="out/target/product/astar_ibt/recovery.img"
FINAL_IMG="$OUT_DIR/twrp-astar_ibt-recovery.img"

if [ ! -f "$BUILT_IMG" ]; then
    echo "error: build finished but $BUILT_IMG was not produced" >&2
    exit 1
fi

cp -f "$BUILT_IMG" "$FINAL_IMG"
log "Verifying $FINAL_IMG"
python3 "$ROOT/tools/verify_recovery.py" --fix-cmdline "$FINAL_IMG"

log "Done: $FINAL_IMG"
echo
echo "Flash it from a rooted (eng) stock system with:"
echo "    adb root"
echo "    adb push $(basename "$FINAL_IMG") /data/local/tmp/"
echo "    adb shell dd if=/data/local/tmp/$(basename "$FINAL_IMG") of=/dev/block/nandf"
