#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_DIR="${1:-}"
if [ -z "$SYSTEM_DIR" ] || [ ! -d "$SYSTEM_DIR" ]; then
    echo "usage: $0 /path/to/extracted/system" >&2
    exit 2
fi
python3 - "$ROOT" "$SYSTEM_DIR" <<'PYTHON'
import hashlib
import os
from pathlib import Path
import shutil
import sys
import tempfile
root = Path(sys.argv[1]) / 'vendor/softwinner/astar_ibt'
source = Path(sys.argv[2]).resolve()
hashes = dict(line.split('  ', 1)[::-1] for line in
              (root / 'BLOBS.sha256').read_text().splitlines())
# Check every input before replacing any existing blob.
for name, expected in hashes.items():
    path = source / name
    if path.is_symlink() or not path.is_file():
        raise SystemExit(f'Missing regular stock file: {name}')
    if hashlib.sha256(path.read_bytes()).hexdigest() != expected:
        raise SystemExit(f'Stock hash mismatch: {name}')
for name in hashes:
    destination = root / 'proprietary' / name
    destination.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(dir=destination.parent)
    os.close(fd)
    try:
        shutil.copy2(source / name, temporary)
        os.replace(temporary, destination)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)
print(f'Installed {len(hashes)} verified stock vendor files')
PYTHON
python3 "$ROOT/verify_vendor.py"
