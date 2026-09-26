#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="${1:-}"
ENGINE="${CONTAINER_ENGINE:-podman}"

if [ -z "$IMAGE" ] || [ ! -f "$IMAGE" ]; then
    echo "usage: $0 /path/to/nandd.img" >&2
    exit 2
fi
DEBUGFS="${DEBUGFS:-$(command -v debugfs || true)}"
if [ -z "$DEBUGFS" ] && command -v brew >/dev/null 2>&1; then
    candidate="$(brew --prefix)/opt/e2fsprogs/sbin/debugfs"
    if [ -x "$candidate" ]; then DEBUGFS="$candidate"; fi
fi

IMAGE="$(cd "$(dirname "$IMAGE")" && pwd)/$(basename "$IMAGE")"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/astar-system.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

if [ -n "$DEBUGFS" ] && [ -z "${CONTAINER_ENGINE:-}" ]; then
    echo "==> Extracting ext4 read-only with $DEBUGFS"
    # debugfs opens read-only unless -w is specified. Work inside the temporary
    # directory so its command language never receives an interpolated path.
    (cd "$TMP_DIR" && "$DEBUGFS" -R 'rdump / .' "$IMAGE")
else
    command -v "$ENGINE" >/dev/null 2>&1 || {
        echo "error: install e2fsprogs (debugfs) or configure CONTAINER_ENGINE" >&2
        exit 1
    }
    echo "==> Extracting ext4 read-only with $ENGINE"
    "$ENGINE" run --rm \
        -v "$IMAGE:/input/nandd.img:ro" \
        -v "$TMP_DIR:/extract" \
        ubuntu:20.04 bash -ceu '
            export DEBIAN_FRONTEND=noninteractive
            apt-get update -qq
            apt-get install -y -qq --no-install-recommends e2fsprogs >/dev/null
            debugfs -R "rdump / /extract" /input/nandd.img
        '
fi

# debugfs can return success after command errors. Require expected contents.
test -f "$TMP_DIR/build.prop"
test -f "$TMP_DIR/vendor/modules/mali.ko"
"$ROOT/extract-stock-files.sh" "$TMP_DIR"
python3 "$ROOT/verify_vendor.py"
