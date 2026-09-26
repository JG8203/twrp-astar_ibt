#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT/build/lineage-13.0}"
JOBS="${JOBS:-$(nproc 2>/dev/null || sysctl -n hw.ncpu)}"
MANIFEST_URL="https://github.com/LineageOS/android.git"
MANIFEST_BRANCH="lineage-13.0"
DEVICE_PATH="device/softwinner/astar_ibt"

for tool in repo git python3; do
    command -v "$tool" >/dev/null 2>&1 || {
        echo "error: '$tool' is required" >&2
        exit 1
    }
done

if [ "$(uname -s)" != Linux ]; then
    echo "error: LineageOS builds require a Linux host or the project Docker environment" >&2
    exit 1
fi

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

if [ ! -d .repo ]; then
    repo init -u "$MANIFEST_URL" -b "$MANIFEST_BRANCH" --depth=1
fi

repo sync -c -j"$JOBS" --force-sync --no-clone-bundle --no-tags

rm -rf "$DEVICE_PATH"
mkdir -p "$(dirname "$DEVICE_PATH")"
cp -a "$ROOT/device/softwinner/astar_ibt" "$DEVICE_PATH"

if [ ! -d vendor/softwinner/astar_ibt/proprietary ]; then
    echo "error: stock proprietary files are missing" >&2
    echo "       mount nandd.img read-only and run lineage/extract-stock-files.sh" >&2
    exit 1
fi

set +eu
source build/envsetup.sh
lunch lineage_astar_ibt-eng
set -eu

make -j"$JOBS" bootimage recoveryimage
