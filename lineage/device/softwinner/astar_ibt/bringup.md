# Bring-up status

## Initial target

LineageOS 13 (`android-6.0`) with the stock 3.4.39 kernel. The first image is
an eng/userdebug build without GApps.

## Current evidence

- Stock kernel/modules and 155 vendor inputs are present and hash-pinned.
- Native read-only extraction from the NAND system backup has been tested.
- GitHub Actions completed the initial CM13 source sync.
- The first run failed at product discovery. The tree now uses `lineage.mk`,
  matching CM13's device discovery rule, with an explicit product alias.
- Compilation, image validation, SELinux adaptation, and hardware testing are
  still outstanding. No bootable Lineage image has been demonstrated.

## Hardware gates

1. Boot to launcher and obtain ADB.
2. Verify display, touch, NAND mounts, USB, and reboot-to-recovery.
3. Verify Wi-Fi and audio.
4. Investigate camera, Bluetooth, RIL, video acceleration, and suspend.

Every failed gate should include the captured `logcat`, `dmesg`, and kernel
version before changing the device tree.
