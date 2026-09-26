# Bring-up status

## Initial target

LineageOS 13 (`android-6.0`) with the stock 3.4.39 kernel. The first image is
an eng/userdebug build without GApps.

## Required before the first build

- Copy the TWRP `BoardConfig.mk` into this tree and replace recovery-only
  variables with the Lineage boot-image settings.
- Add the stock kernel and a complete `Android.mk`/`AndroidProducts.mk` device
  registration.
- Extract `/system` proprietary files from `nandd.img` and generate a checked-in
  `proprietary-files.txt` with SHA-256 hashes.
- Add rootdir files from `work/stock-boot-ramdisk`, then adapt paths and SELinux
  labels to LineageOS 13.

## Hardware gates

1. Boot to launcher and obtain ADB.
2. Verify display, touch, NAND mounts, USB, and reboot-to-recovery.
3. Verify Wi-Fi and audio.
4. Investigate camera, Bluetooth, RIL, video acceleration, and suspend.

Every failed gate should include the captured `logcat`, `dmesg`, and kernel
version before changing the device tree.
