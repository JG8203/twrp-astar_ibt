# TWRP port for the iNet / Allwinner RQ-713 (`astar_ibt`, A33 / sun8i)

This directory contains a complete TWRP device tree and build tooling for the
white-label Allwinner A33 tablet dumped in
`RQ713_INET_U70X_20260926_184544/`. The dump itself was **not modified**.

## Device

| Item | Value |
| --- | --- |
| Model | RQ-713 (iNet / white-label Allwinner A33 tablet) |
| Board / device | `astar-ibt` / `astar_ibt`, `sun8i` |
| SoC | Allwinner A33 (4x Cortex-A7, NEON), 512 MB RAM |
| Android | **6.0.1** (`MOB30R`, SDK 23, `eng`/test-keys build, `ro.secure=0`) |
| Kernel | 3.4.39 SMP PREEMPT, build 2017-04-19 (`inet-soft31@superFAE03`) |
| Display | 1024x600 (from `bootlogo.bmp`), mdpi (`ro.sf.lcd_density=160`) |
| Touch | GSLX680 (`gslX680new.ko`) |
| Storage | 8 GB NAND: `nanda`..`nandn`, ext4 `/system` `/data(UDISK)` `/cache` |
| Wi-Fi | Realtek RTL8723CS (not used by TWRP) |
| Bootloader | Allwinner u-boot (with `boota` and `fastboot` commands) |

> The tablet is commonly remembered as KitKat-era hardware, but this firmware
> is Marshmallow: `ro.build.version.release=6.0.1`, `sdk=23`,
> `ro.build.fingerprint=Allwinner/astar_ibt/astar-ibt:6.0.1/MOB30R/20170801`,
> plus 6.0-only features in the fstab (`metadata` partition, `encryptable=`).
> The `twrp-6.0` build platform is therefore the correct base.

## What gets built

TWRP **3.7.0_9** (TeamWin `android-9.0` recovery source) built on the AOSP
6.0.1_r74 platform from TWRP's official minimal manifest
(`minimal-manifest-twrp/platform_manifest_twrp_omni`, branch `twrp-6.0`),
using the stock kernel and stock kernel modules from the dump.

```
device/softwinner/astar_ibt/   complete TWRP device tree (see its README)
tools/bootimg.py               unpack/inspect Android boot images from the dump
tools/verify_recovery.py       sanity-check a built recovery.img
build_twrp.sh                  one-shot Linux build script
docker/Dockerfile, build.sh    reproducible Ubuntu 20.04 build environment
work/                          scratch (unpacked stock images) - not part of the port
out/                           build output (created by build_twrp.sh)
```

## Building

Recovery builds need an x86_64 Linux host (the prebuilt AOSP toolchains are
Linux binaries). Everything else you need is in this repo.

### Option A - Docker / Podman (easiest; also usable from this Mac)

```sh
./docker/build.sh                    # picks docker or podman automatically
CONTAINER_ENGINE=podman ./docker/build.sh
```

Builds an Ubuntu 20.04 image with JDK 8 + Python 2 + `repo`, syncs the TWRP
minimal tree (~10-15 GB), builds `recoveryimage`, copies the result to
`out/twrp-astar_ibt-recovery.img` and verifies it. Note: on Apple Silicon the
x86_64 toolchains run under emulation and a full build is impractically slow -
prefer a native x86_64 Linux machine.

### Option B - GitHub Actions (no Linux machine needed)

Push this directory to a GitHub repository (`.gitignore` keeps the multi-GB
dump and `out/` out of git) and either push to `main`/`master`, or run the
**Build TWRP (RQ-713 / astar_ibt)** workflow manually from the Actions tab.
The workflow frees runner disk space, builds the `docker/` image, syncs the
TWRP minimal manifest, runs `build_twrp.sh`, verifies the header/layout and
uploads the `twrp-astar_ibt-recovery` artifact (image + SHA256SUMS).

Download the artifact from the run page and continue at "Flashing" below.
On a private repo the build consumes ~2-3 h of the free 2,000 Actions
minutes/month; public repos are unlimited.

### Option C - native Ubuntu 20.04 / 22.04

```sh
# deps
sudo apt-get install openjdk-8-jdk git gnupg flex bison gperf build-essential \
  zip curl zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 \
  lib32ncurses-dev x11proto-core-dev libx11-dev lib32z1-dev ccache \
  libgl1-mesa-dev libxml2-utils xsltproc unzip python2 python3 bc libssl-dev
# repo tool
curl https://storage.googleapis.com/git-repo-downloads/repo | sudo tee /usr/local/bin/repo >/dev/null
sudo chmod a+x /usr/local/bin/repo

BUILD_DIR=$HOME/twrp-build ./build_twrp.sh
```

Expect roughly 1-3 hours for the first build (4+ cores recommended) and
~30 GB of disk for source + output. `out/twrp-astar_ibt-recovery.img` is the
flashable image; `tools/verify_recovery.py` checks that its header matches the
stock boot layout (kernel `0x40008000`, ramdisk `0x41000000`, tags
`0x40000100`, page 2048, empty cmdline, fits the 32 MiB recovery partition) and
that the ramdisk contains the TWRP binary, fstab and all six stock modules.

## Flashing

Only the **recovery** partition (`nandf`) is written. Keep the dump safe: it
is your full stock restore image.

### From the booted stock system (eng build -> root adb works)

```sh
adb root
adb push out/twrp-astar_ibt-recovery.img /data/local/tmp/twrp.img
adb shell "dd if=/data/local/tmp/twrp.img of=/dev/block/nandf bs=1048576"
adb shell "dd if=/dev/block/nandf bs=1048576 count=32" > /tmp/readback.img
cmp -n "$(stat -f %z out/twrp-astar_ibt-recovery.img)" \
        out/twrp-astar_ibt-recovery.img /tmp/readback.img   # macOS stat
adb reboot recovery
```

### Fastboot (alternative, if you can enter it)

u-boot's env defines `boot_fastboot=fastboot`, so from u-boot fastboot mode:
`fastboot flash recovery out/twrp-astar_ibt-recovery.img`.

### Keep stock from re-flashing recovery

The stock system ships `install-recovery.sh`, `recovery-from-boot.p` and
`recovery-resource.dat` ("flash_recovery" service in init). Its `applypatch`
verifies the stock recovery checksum and should abort harmlessly once TWRP is
installed, but to be deterministic, boot TWRP once, mount **System** (rw) and
delete/rename `/system/recovery-from-boot.p` (or
`/system/bin/install-recovery.sh`). Then reboot Android normally and verify
TWRP is still there via `adb reboot recovery`.

## Testing checklist

1. TWRP UI on a 1024x600 screen (`landscape_mdpi`), no red/blue swap.
2. Touch works (gslX680new), hardware keys (Vol +/-, Power) as fallback.
3. Mount: `/system` (ext4), `/data` (UDISK), `/cache`, MicroSD, USB OTG.
4. Make a full backup (Boot, System, Data, Cache) to the MicroSD.
5. Flash a simple zip, restore the backup, verify `/system` integrity.
6. `adb shell` inside TWRP (uses the kernel's legacy `/dev/android_adb`
   gadget - stock recovery does the same).
7. Reboot to recovery from TWRP menu and from Android.

### If something is wrong

* **Colors swapped** -> TWRP auto-detects the fb format, but the sunxi driver
  can lie: uncomment `TARGET_RECOVERY_PIXEL_FORMAT := "BGRA_8888"` in
  `BoardConfig.mk` and rebuild (incremental, ~5-10 min).
* **Black screen** -> check that `disp.ko`/`lcd.ko` loaded (`dmesg` on the
  UART console, or re-verify the ramdisk contents).
* **Touch dead** -> `gslX680new.ko` load order (after `sw-device.ko`) or a
  missing `ctp` sys_config supplied by u-boot.

## Restoring the stock recovery

```sh
adb root
adb push RQ713_INET_U70X_20260926_184544/partitions/nandf.img /data/local/tmp/stock-recovery.img
adb shell "dd if=/data/local/tmp/stock-recovery.img of=/dev/block/nandf bs=1048576"
```

The dump's `hashes/SHA256SUMS.txt` covers every partition image; the stock
recovery (`nandf.img`) SHA-256 is
`20d48d915d15829e24561f0c8de2bcfaca4edfac4cb71ec1767fd9df824e86a7`.

## Known limitations / notes

* NAND-only device, no eMMC, no GPT; `/dev/block/nanda..nandn` are used
  directly. F2FS is not available in this kernel - keep ext4/vfat.
* The stock system is unencrypted; TWRP crypto/FDE is not enabled. If you
  enable full-disk encryption later, TWRP will not be able to decrypt it.
* 512 MB RAM: TWRP 3.7 is heavier than the stock recovery. Backing up the
  2 GB `/system` over slow NAND takes a while; be patient.
* `bootloader` (boot logo FAT), `logger`, `private` and `misc` are listed in
  the fstab with `backup=0`; do not format `bootloader`.
* The port was assembled from the dump alone and has not been boot-tested on
  hardware. The stock recovery image in the dump is the safety net.

## Provenance

Every binary in the device tree comes from the stock dump:

* `kernel` = kernel segment of `nandc.img`/`nandf.img` (identical SHA-256).
* `disp.ko`, `lcd.ko`, `nand.ko`, `gslX680new.ko`, `sw-device.ko`,
  `sunxi-keyboard.ko` = files from the stock recovery ramdisk.
* Hashes: `device/softwinner/astar_ibt/BLOBS.sha256`.

Reference device trees for sibling `astar_ibt` tablets (Woxter QX120,
Glee 10.1) were used as cross-checks for the TWRP flags and module set; the
exact partition layout, kernel, modules and 1024x600 panel here come from this
dump.
