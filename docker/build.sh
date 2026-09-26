#!/usr/bin/env bash
#
# Convenience wrapper: build the RQ-713 TWRP image inside Docker.
# Works on macOS/Linux; keeps the source tree in a Docker volume-friendly dir.
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$HOME/twrp-build-astar_ibt}"

ENGINE="${CONTAINER_ENGINE:-}"
if [ -z "$ENGINE" ]; then
    if command -v docker >/dev/null 2>&1; then ENGINE=docker
    elif command -v podman >/dev/null 2>&1; then ENGINE=podman
    else echo "error: neither docker nor podman found" >&2; exit 1
    fi
fi
mkdir -p "$BUILD_DIR"

case "$(uname -m)" in
    arm64|aarch64)
        echo "warning: building the x86_64 toolchains under emulation is extremely slow." >&2
        echo "         A native x86_64 Linux machine is strongly recommended." >&2
        ;;
esac

echo "==> Building builder image with $ENGINE"
"$ENGINE" build -t twrp-astar-ibt-builder "$ROOT/docker"

RUN_ARGS=(--rm -v "$ROOT:/work" -v "$BUILD_DIR:/build" -e BUILD_DIR=/build -w /work)
# -t/-i only when attached to a terminal (GitHub Actions has no TTY)
if [ -t 0 ]; then
    RUN_ARGS+=(-it)
fi

echo "==> Building TWRP (this takes 1-3 hours on first run)"
"$ENGINE" run "${RUN_ARGS[@]}" twrp-astar-ibt-builder ./build_twrp.sh

echo "==> Done: $ROOT/out/twrp-astar_ibt-recovery.img"
