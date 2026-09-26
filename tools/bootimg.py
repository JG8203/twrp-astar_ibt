#!/usr/bin/env python3
"""Minimal Android boot image (v0/v1/v2) unpack/pack for Allwinner A33 dumps."""
import argparse, gzip, io, lzma, os, struct, sys

MAGICS = {b"ANDROID!": "v0+", b"BOOT": "vendor"}

def rd(f, n):
    d = f.read(n)
    if len(d) != n:
        raise EOFError
    return d

def unpack(path, outdir):
    with open(path, "rb") as f:
        magic = rd(f, 8)
        if magic != b"ANDROID!":
            raise SystemExit(f"{path}: not an Android boot image ({magic!r})")
        fields = struct.unpack("<10I", rd(f, 40))
        (kernel_size, kernel_addr, ramdisk_size, ramdisk_addr,
         second_size, second_addr, tags_addr, page_size, header_version, os_version) = fields
        name = rd(f, 16).rstrip(b"\x00").decode(errors="replace")
        cmdline = rd(f, 512).rstrip(b"\x00").decode(errors="replace")
        img_id = rd(f, 32)
        extra = rd(f, 1024 - 8 - 40 - 16 - 512 - 32) if header_version >= 1 else b""
        dt_size = 0
        if header_version >= 1:
            dt_size = struct.unpack("<I", extra[:4])[0]
        print(f"magic=ANDROID! header_version={header_version}")
        print(f"kernel  size={kernel_size} addr=0x{kernel_addr:08x}")
        print(f"ramdisk size={ramdisk_size} addr=0x{ramdisk_addr:08x}")
        print(f"second  size={second_size} addr=0x{second_addr:08x}")
        print(f"tags_addr=0x{tags_addr:08x} page_size={page_size} os_version=0x{os_version:08x}")
        print(f"dt_size={dt_size}")
        print(f"name={name!r}")
        print(f"cmdline={cmdline!r}")
        print(f"id={img_id.hex()}")

        # seek to end of header page(s)
        header_len = 8 + 40 + 16 + 512 + 32 + len(extra)
        pad = (page_size - (header_len % page_size)) % page_size
        if pad:
            rd(f, pad)

        def read_part(size):
            if size == 0:
                return b""
            data = rd(f, size)
            pad = (page_size - (size % page_size)) % page_size
            if pad:
                rd(f, pad)
            return data

        os.makedirs(outdir, exist_ok=True)
        kernel = read_part(kernel_size)
        ramdisk = read_part(ramdisk_size)
        second = read_part(second_size)
        dt = read_part(dt_size) if dt_size else b""

        open(os.path.join(outdir, "kernel"), "wb").write(kernel)
        open(os.path.join(outdir, "ramdisk"), "wb").write(ramdisk)
        if second:
            open(os.path.join(outdir, "second"), "wb").write(second)
        if dt:
            open(os.path.join(outdir, "dt"), "wb").write(dt)
        open(os.path.join(outdir, "cmdline.txt"), "w").write(cmdline)
        import json
        json.dump({
            "kernel_addr": kernel_addr, "ramdisk_addr": ramdisk_addr,
            "second_addr": second_addr, "tags_addr": tags_addr,
            "page_size": page_size, "name": name, "cmdline": cmdline,
            "os_version": os_version, "header_version": header_version,
            "id": img_id.hex(),
        }, open(os.path.join(outdir, "bootimg.json"), "w"), indent=2)

        # detect ramdisk compression
        head = ramdisk[:8]
        comp = "unknown"
        for magic, c in ((b"\x1f\x8b", "gzip"), (b"\x28\xb5\x2f\xfd", "zstd"),
                         (b"\x04\x22\x4d\x18", "lz4"), (b"\xfd7zXZ", "xz"),
                         (b"\x5d\x00\x00", "lzma"), (b"BZh", "bzip2")):
            if head.startswith(magic):
                comp = c
        print(f"ramdisk compression: {comp}")
        if comp == "gzip":
            data = gzip.decompress(ramdisk)
        elif comp == "lz4":
            data = None
            print("NOTE: lz4 ramdisk, extract manually")
        elif comp == "xz":
            data = lzma.decompress(ramdisk)
        else:
            data = ramdisk if comp == "unknown" else None
        if data is not None and data[:2] == b"\x1f\x8b":
            data = gzip.decompress(data)
        if data is not None:
            open(os.path.join(outdir, "ramdisk.cpio"), "wb").write(data)
            print(f"ramdisk.cpio: {len(data)} bytes")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    ap.add_argument("outdir")
    a = ap.parse_args()
    unpack(a.image, a.outdir)

if __name__ == "__main__":
    main()
