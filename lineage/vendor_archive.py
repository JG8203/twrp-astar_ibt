#!/usr/bin/env python3
"""Pack or install only the pinned vendor inputs, without arbitrary tar extraction."""
import argparse
import hashlib
import io
import tarfile
from pathlib import Path
from verify_vendor import verify

ROOT = Path(__file__).resolve().parent / 'vendor/softwinner/astar_ibt'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('operation', choices=['pack', 'unpack'])
    parser.add_argument('archive', type=Path)
    args = parser.parse_args()
    hashes = dict(line.split('  ', 1)[::-1] for line in
                  (ROOT / 'BLOBS.sha256').read_text().splitlines())
    if args.operation == 'pack':
        verify(ROOT)
        args.archive.parent.mkdir(parents=True, exist_ok=True)
        with tarfile.open(args.archive, 'w:gz') as archive:
            for name in sorted(hashes):
                source = ROOT / 'proprietary' / name
                data = source.read_bytes()
                info = tarfile.TarInfo(name)
                info.size = len(data)
                info.mode = 0o755 if source.stat().st_mode & 0o111 else 0o644
                archive.addfile(info, io.BytesIO(data))
    else:
        with tarfile.open(args.archive, 'r:gz') as archive:
            members = archive.getmembers()
            if len(members) != len(hashes) or {m.name for m in members} != set(hashes):
                raise ValueError('archive does not match pinned vendor manifest')
            # Validate the complete archive before writing any files.
            for member in members:
                if not member.isfile() or member.size > 64 * 1024 * 1024:
                    raise ValueError(f'invalid entry: {member.name}')
                if hashlib.sha256(archive.extractfile(member).read()).hexdigest() != hashes[member.name]:
                    raise ValueError(f'hash mismatch: {member.name}')
            for member in members:
                destination = ROOT / 'proprietary' / member.name
                destination.parent.mkdir(parents=True, exist_ok=True)
                destination.write_bytes(archive.extractfile(member).read())
                destination.chmod(0o755 if member.mode & 0o111 else 0o644)
        verify(ROOT)
    print(f'{args.operation}: {len(hashes)} verified vendor files')


if __name__ == '__main__':
    main()
