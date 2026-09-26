#!/usr/bin/env python3
"""Verify vendor copy sources and hashes; this does not prove ABI compatibility."""
import hashlib
import re
from pathlib import Path


def verify(root):
    rules = (root / 'astar_ibt-vendor.mk').read_text()
    sources = re.findall(r'\$\(ASTAR_VENDOR_PATH\)/([^:\s]+):', rules)
    manifest = [line for line in (root / 'proprietary-files.txt').read_text().splitlines()
                if line and not line.startswith('#')]
    checksums = dict(line.split('  ', 1)[::-1]
                     for line in (root / 'BLOBS.sha256').read_text().splitlines())
    if len(sources) != len(set(sources)):
        raise ValueError('duplicate vendor copy sources')
    if set(sources) != set(manifest) or set(manifest) != set(checksums):
        raise ValueError('copy rules, proprietary manifest, and checksums differ')
    for name in manifest:
        if Path(name).is_absolute() or '..' in Path(name).parts:
            raise ValueError(f'unsafe manifest path: {name}')
        data = (root / 'proprietary' / name).read_bytes()
        if hashlib.sha256(data).hexdigest() != checksums[name]:
            raise ValueError(f'checksum mismatch: {name}')
    return len(manifest)


if __name__ == '__main__':
    root = Path(__file__).resolve().parent / 'vendor/softwinner/astar_ibt'
    try:
        count = verify(root)
    except (OSError, ValueError) as exc:
        raise SystemExit(f'vendor verification failed: {exc}')
    print(f'Verified {count} stock vendor inputs; runtime ABI compatibility remains untested.')
