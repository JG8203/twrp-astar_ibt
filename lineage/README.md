# LineageOS 13 bring-up for the RQ-713

This directory tracks the Android 6.0 / LineageOS 13 port for the iNet RQ-713
(`astar_ibt`). It is intentionally separate from the TWRP device tree while
the product, vendor blobs, and init/SELinux policy are being adapted.

## Hardware baseline

- Allwinner A33 / `sun8i`, ARMv7 Cortex-A7, 512 MiB RAM
- Android 6.0.1 stock system (`MOB30R`, SDK 23)
- Linux 3.4.39 kernel and legacy Allwinner NAND driver
- 1024x600 landscape mdpi display
- RTL8723CS Wi-Fi, optional data-only RIL on `/dev/ttyUSB2`
- NAND partitions: 16 MiB boot, 32 MiB recovery, 2 GiB system, 4.3 GiB data

## Current strategy

LineageOS 13 is the first target because its Android 6 framework matches the
stock vendor interface. The stock kernel remains prebuilt initially; replacing
it is out of scope until a concrete driver or framework requirement forces a
change. The first image will ship without GApps to leave room for the 512 MiB
memory device.

## Bring-up order

1. Create the Lineage product/device makefiles from the working TWRP tree.
2. Extract `/system` and vendor libraries from `nandd.img`, preserving hashes
   and licensing/provenance information.
3. Recreate stock init imports, fstab, permissions, Wi-Fi, audio, camera, and
   RIL configuration under Lineage 13's init and SELinux rules.
4. Build a bootable eng image and test display, touch, NAND mounts, USB/ADB,
   and recovery reboot on the tablet.
5. Add Wi-Fi, audio, camera, Bluetooth, suspend, and low-memory tuning one
   subsystem at a time, recording failures in `device/softwinner/astar_ibt/bringup.md`.

Extract the stock system read-only using native `debugfs` (on macOS, install
with `brew install e2fsprogs`) or an available container engine:

```sh
./lineage/extract-stock-image.sh \
  RQ713_INET_U70X_20260926_184544/partitions/nandd.img
```

The helper prefers native `debugfs`; set `CONTAINER_ENGINE=podman` or `docker`
to force container extraction. It installs only the 155 hash-pinned hardware
inputs under `lineage/vendor/softwinner/astar_ibt/proprietary`. Ownership
warnings from unprivileged `debugfs` on macOS are expected; the script checks
extracted contents and hashes before accepting the result.

The complete stock dump in the repository is the restore source. No partition
image is modified by the bring-up tooling.

## GitHub Actions build

The manually dispatched **Build LineageOS 13 (astar_ibt)** workflow builds the
upstream `cm-13.0` branch on an x86-64 Linux runner using the Java 8/Python 2
container. The lunch target is `cm_astar_ibt-eng`. It produces boot, system,
and recovery images; these are experimental and have not been boot-tested.

Create the reduced vendor archive locally with:

```sh
python3 lineage/vendor_archive.py pack out/lineage-vendor.tar.gz
```

Supply its HTTPS download URL as the workflow's `vendor_url` input (or as the
repository secret `LINEAGE_VENDOR_URL`). The archive installer accepts exactly
the files pinned in `BLOBS.sha256`, verifies all hashes before extraction, and
rejects extra entries. Archive URLs are passed as environment variables rather
than interpolated into shell commands.

The workflow checks for at least 80 GiB of free disk before syncing and uses two
compile jobs. This is a starting resource budget, not a guarantee that the full
build will fit. It uploads the build log even if compilation fails; successful
runs also upload images and checksums. A successful compile still requires
boot-layout inspection and hardware testing before the port is usable.
