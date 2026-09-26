# TWRP device tree: iNet / Allwinner RQ-713 (`astar_ibt`)

This tree was generated from a full stock partition dump of the RQ-713
(Allwinner A33 / sun8i, Android 6.0.1, kernel 3.4.39). It is meant to be built
with the official TWRP minimal manifest, branch `twrp-6.0`
(see the top-level `README.md`).

## Layout

```
BoardConfig.mk           - kernel/partition/TWRP settings for this tablet
astar_ibt.mk             - shared product config (kernel, ro.hardware)
omni_astar_ibt.mk        - product entry (lunch omni_astar_ibt-eng)
AndroidProducts.mk
vendorsetup.sh
kernel                   - stock zImage (from the dump, boot == recovery kernel)
sepolicy/module.te       - lets init insmod() the recovery modules
recovery/root/
    init.recovery.sun8i.rc   - insmods display/touch/nand modules at init
    ueventd.sun8i.rc         - sunxi device node permissions
    etc/twrp.fstab           - partition table for TWRP
    disp.ko lcd.ko nand.ko gslX680new.ko sw-device.ko sunxi-keyboard.ko
```

## Why these choices

* **Stock kernel** (`TARGET_PREBUILT_KERNEL`): the dump's boot and recovery
  images contain the byte-identical kernel, so the stock kernel is known to
  drive this exact panel, touch controller and NAND.
* **Stock modules**: `disp.ko`/`lcd.ko` bring up the 1024x600 panel, `nand.ko`
  exposes `/dev/block/nanda..nandn`, `gslX680new.ko` is the touchscreen
  (the stock recovery never loaded it; TWRP does), `sw-device.ko` and
  `sunxi-keyboard.ko` are required by the others.
* **`/dev/block/nandX` in the fstab**: the `/dev/block/by-name/*` symlinks are
  created by Allwinner's own init from the `partitions=` cmdline; the AOSP
  init/recovery that TWRP uses does not create them.
* **Empty kernel cmdline**: the stock images carry none either; u-boot's
  `boota` supplies `disp_para`, `ion_cma_list`, `androidboot.hardware=sun8i`,
  `partitions=`, ... at boot. `tools/verify_recovery.py --fix-cmdline`
  guarantees this stays empty.
* **`TW_THEME := landscape_mdpi`**: the panel is 1024x600 at 160 dpi.
* **No `TARGET_RECOVERY_PIXEL_FORMAT`**: TWRP 3.7's fbdev backend reads the
  format out of `fb_var_screeninfo` at runtime. The define only exists as a
  byte-swap workaround; set it to `"BGRA_8888"` (uncommented in
  `BoardConfig.mk`) if the UI shows swapped red/blue.

## Blob provenance

`BLOBS.sha256` lists the kernel and module hashes. The source images are in
`RQ713_INET_U70X_20260926_184544/partitions/`; the dump's own
`hashes/SHA256SUMS.txt` still verifies.
