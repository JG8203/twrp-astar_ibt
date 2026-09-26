#!/usr/bin/env python3
"""
Verify a built TWRP recovery image for the iNet / Allwinner RQ-713 (astar_ibt).

Checks that the image matches the boot layout used by the stock firmware:

    magic          ANDROID!
    header ver.    0
    kernel addr    0x40008000  (base 0x40000000 + offset 0x8000)
    ramdisk addr   0x41000000  (+ offset 0x01000000)
    tags addr      0x40000100  (+ offset 0x00000100)
    page size      2048
    cmdline        empty       (u-boot "boota" supplies the real one)
    size           <= 33554432 bytes (recovery partition / nandf)

It also decompresses the ramdisk and makes sure the files TWRP needs are in it.

Exit code 0 = image looks bootable on the device, 1 = problems found.
"""

import argparse
import gzip
import hashlib
import lzma
import os
import struct
import sys

EXPECTED = {
    "header_version": 0,
    "kernel_addr": 0x40008000,
    "ramdisk_addr": 0x41000000,
    "tags_addr": 0x40000100,
    "page_size": 2048,
    "partition_size": 33554432,
}

REQUIRED_RAMDISK_FILES = [
    "init.recovery.sun8i.rc",
    "etc/twrp.fstab",
    "etc/recovery.fstab",
    "disp.ko",
    "lcd.ko",
    "nand.ko",
    "gslX680new.ko",
    "sw-device.ko",
    "sunxi-keyboard.ko",
    "sbin/recovery",
]


def parse_header(data):
    if data[:8] != b"ANDROID!":
        raise ValueError("not an Android boot image (bad magic)")
    (kernel_size, kernel_addr, ramdisk_size, ramdisk_addr,
     second_size, second_addr, tags_addr, page_size, header_version,
     os_version) = struct.unpack("<10I", data[8:48])
    name = data[48:64].rstrip(b"\x00").decode(errors="replace")
    cmdline = data[64:576].rstrip(b"\x00").decode(errors="replace")
    img_id = data[576:608]
    return {
        "kernel_size": kernel_size, "kernel_addr": kernel_addr,
        "ramdisk_size": ramdisk_size, "ramdisk_addr": ramdisk_addr,
        "second_size": second_size, "second_addr": second_addr,
        "tags_addr": tags_addr, "page_size": page_size,
        "header_version": header_version, "os_version": os_version,
        "name": name, "cmdline": cmdline, "id": img_id,
    }


def read_part(f, size, page_size):
    if size == 0:
        return b""
    data = f.read(size)
    if len(data) != size:
        raise ValueError("truncated image")
    pad = (page_size - (size % page_size)) % page_size
    if pad:
        f.read(pad)
    return data


def decompress_ramdisk(data):
    if data[:2] == b"\x1f\x8b":
        return gzip.decompress(data)
    if data[:6] == b"\xfd7zXZ\x00":
        return lzma.decompress(data)
    return data


def cpio_names(cpio):
    names = []
    pos = 0
    n = len(cpio)
    while pos + 110 <= n:
        if cpio[pos:pos + 6] != b"070701":
            break
        fields = [int(cpio[pos + 6 + i * 8:pos + 14 + i * 8], 16) for i in range(13)]
        filesize = fields[6]
        namesize = fields[11]
        name = cpio[pos + 110:pos + 110 + namesize - 1].decode(errors="replace")
        names.append(name.lstrip("./"))
        if name == "TRAILER!!!":
            break
        data_off = pos + 110 + namesize
        data_off += (4 - (data_off % 4)) % 4
        pos = data_off + filesize
        pos += (4 - (pos % 4)) % 4
    return names


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("image")
    ap.add_argument("--fix-cmdline", action="store_true",
                    help="zero the header cmdline field if it is not empty")
    args = ap.parse_args()

    data = bytearray(open(args.image, "rb").read())
    hdr = parse_header(data)
    problems = []

    for key in ("header_version", "kernel_addr", "ramdisk_addr", "tags_addr",
                "page_size"):
        if hdr[key] != EXPECTED[key]:
            problems.append(f"{key}: got {hdr[key]!r}, expected {EXPECTED[key]!r}")

    if hdr["second_size"] != 0:
        problems.append(f"second stage present ({hdr['second_size']} bytes), stock has none")

    cmdline_fixed = False
    if hdr["cmdline"]:
        if args.fix_cmdline:
            data[64:576] = b"\x00" * 512
            hdr["cmdline"] = ""
            cmdline_fixed = True
            print("cmdline field zeroed (u-boot supplies the cmdline at boot)")
        else:
            problems.append(f"cmdline is not empty: {hdr['cmdline']!r}")

    print(f"image            : {args.image}")
    print(f"size             : {len(data)} bytes "
          f"(partition {EXPECTED['partition_size']})")
    print(f"kernel           : {hdr['kernel_size']} bytes @ 0x{hdr['kernel_addr']:08x}")
    print(f"ramdisk          : {hdr['ramdisk_size']} bytes @ 0x{hdr['ramdisk_addr']:08x}")
    print(f"page size        : {hdr['page_size']}")
    print(f"cmdline          : {hdr['cmdline']!r}")
    print(f"header id        : {hdr['id'].hex()}")
    print(f"sha256           : {hashlib.sha256(data).hexdigest()}")

    if len(data) > EXPECTED["partition_size"]:
        problems.append(f"image ({len(data)}) does not fit the recovery partition "
                        f"({EXPECTED['partition_size']})")

    # ramdisk contents
    with open(args.image, "rb") as f:
        f.seek(EXPECTED["page_size"])
        f.read(hdr["kernel_size"])
        pad = (EXPECTED["page_size"] - (hdr["kernel_size"] % EXPECTED["page_size"])) % EXPECTED["page_size"]
        f.read(pad)
        ramdisk = read_part(f, hdr["ramdisk_size"], EXPECTED["page_size"])

    try:
        cpio = decompress_ramdisk(ramdisk)
        names = set(cpio_names(cpio))
    except Exception as exc:  # noqa: BLE001
        problems.append(f"could not parse ramdisk: {exc}")
        names = set()

    print(f"ramdisk entries  : {len(names)}")
    for needed in REQUIRED_RAMDISK_FILES:
        if needed not in names:
            problems.append(f"missing in ramdisk: {needed}")
    if "sbin/recovery" in names:
        print("recovery binary  : present")

    if cmdline_fixed:
        open(args.image, "wb").write(data)
        print("image rewritten with empty cmdline")

    if problems:
        print("\nPROBLEMS:")
        for p in problems:
            print(f"  - {p}")
        return 1

    print("\nOK: image matches the RQ-713 boot layout and contains what TWRP needs.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
