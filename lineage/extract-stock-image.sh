#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="${1:-}"
ENGINE="${CONTAINER_ENGINE:-podman}"

if [ -z "$IMAGE" ] || [ ! -f "$IMAGE" ]; then
    echo "usage: $0 /path/to/nandd.img" >&2
    exit 2
fi
command -v "$ENGINE" >/dev/null 2>&1 || {
    echo "error: container engine '$ENGINE' not found" >&2
    exit 1
}

IMAGE="$(cd "$(dirname "$IMAGE")" && pwd)/$(basename "$IMAGE")"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/astar-system.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "==> Extracting ext4 system image read-only with $ENGINE"
"$ENGINE" run --rm \
    -v "$IMAGE:/input/nandd.img:ro" \
    -v "$TMP_DIR:/extract" \
    ubuntu:20.04 \
    bash -ceu '
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq
        apt-get install -y -qq --no-install-recommends e2fsprogs >/dev/null
        debugfs -R "rdump / /extract" /input/nandd.img >/dev/null
    '

"$ROOT/extract-stock-files.sh" "$TMP_DIR"
