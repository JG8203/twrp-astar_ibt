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
   subsystem at a time, recording failures in `lineage/bringup.md`.

On macOS with Podman, the stock system image can be extracted without writing
to it:

```sh
CONTAINER_ENGINE=podman ./lineage/extract-stock-image.sh \
  RQ713_INET_U70X_20260926_184544/partitions/nandd.img
```

The helper uses Ubuntu's `debugfs` inside a disposable container and places
the copied userspace under `lineage/vendor/softwinner/astar_ibt/proprietary`.

The complete stock dump in the repository is the restore source. No partition
image is modified by the bring-up tooling.
