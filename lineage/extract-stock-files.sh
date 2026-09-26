#!/usr/bin/env bash
set -euo pipefail

# Extract stock Android files after mounting nandd.img read-only. The script
# deliberately copies only userspace/vendor inputs; it never writes to the
# partition image or the NAND backup directory.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_DIR="${1:-}"
DEST="$ROOT/vendor/softwinner/astar_ibt/proprietary"

if [ -z "$SYSTEM_DIR" ] || [ ! -d "$SYSTEM_DIR" ]; then
    echo "usage: $0 /path/to/read-only/mounted/system" >&2
    exit 2
fi

mkdir -p "$DEST"

for dir in bin etc framework lib media usr vendor xbin; do
    if [ -d "$SYSTEM_DIR/$dir" ]; then
        mkdir -p "$DEST/$dir"
        cp -a "$SYSTEM_DIR/$dir/." "$DEST/$dir/"
    fi
done

printf 'Extracted stock userspace files to %s\n' "$DEST"
printf 'Review and reduce the copied set before generating proprietary-files.txt.\n'
