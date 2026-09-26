#
# BoardConfig.mk
#
# TWRP device configuration for the iNet / Allwinner RQ-713 tablet
# (board "astar-ibt", SoC Allwinner A33 / sun8i, kernel 3.4.39).
#
# Everything here was derived from a full stock dump
# (RQ713_INET_U70X_20260926_184544) - see README.md for details.
#

LOCAL_PATH := device/softwinner/astar_ibt

USE_CAMERA_STUB := false

# ---------------------------------------------------------------------------
# Architecture
# ---------------------------------------------------------------------------
TARGET_ARCH := arm
TARGET_NO_BOOTLOADER := true
TARGET_BOARD_PLATFORM := astar
TARGET_CPU_ABI := armeabi-v7a
TARGET_CPU_ABI2 := armeabi
TARGET_CPU_SMP := true
TARGET_CPU_VARIANT := cortex-a7
TARGET_ARCH_VARIANT := armv7-a-neon
TARGET_BOOTLOADER_BOARD_NAME := astar_ibt

# The twrp-6.0 minimal manifest expects this to be tolerated.
ALLOW_MISSING_DEPENDENCIES := true

TARGET_GLOBAL_CFLAGS += -mtune=cortex-a7 -mfpu=neon -mfloat-abi=softfp
TARGET_GLOBAL_CPPFLAGS += -mtune=cortex-a7 -mfpu=neon -mfloat-abi=softfp

# ---------------------------------------------------------------------------
# Kernel - stock Allwinner zImage taken from the dump (boot and recovery
# images contain the byte-identical kernel).
# ---------------------------------------------------------------------------
BOARD_KERNEL_BASE := 0x40000000
BOARD_KERNEL_PAGESIZE := 2048
# Leave BOARD_KERNEL_CMDLINE undefined on purpose: the stock images carry an
# empty cmdline and u-boot's "boota" builds the real one (disp_para,
# ion_cma_list, androidboot.*, ...) at boot time.
BOARD_MKBOOTIMG_ARGS := --kernel_offset 0x00008000 --ramdisk_offset 0x01000000 --tags_offset 0x00000100
TARGET_PREBUILT_KERNEL := $(LOCAL_PATH)/kernel

# ---------------------------------------------------------------------------
# Partitions (sizes in bytes, read from the stock dump)
# ---------------------------------------------------------------------------
BOARD_FLASH_BLOCK_SIZE := 4096
BOARD_BOOTIMAGE_PARTITION_SIZE := 16777216      # nandc
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 33554432  # nandf
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 2147483648  # nandd
BOARD_USERDATAIMAGE_PARTITION_SIZE := 4592762880
BOARD_CACHEIMAGE_PARTITION_SIZE := 805306368
BOARD_HAS_LARGE_FILESYSTEM := true
TARGET_USERIMAGES_USE_EXT4 := true

# ---------------------------------------------------------------------------
# Recovery / TWRP
# ---------------------------------------------------------------------------
TARGET_RECOVERY_FSTAB := $(LOCAL_PATH)/recovery/root/etc/twrp.fstab

# No TARGET_RECOVERY_PIXEL_FORMAT needed: TWRP's fbdev backend auto-detects the
# framebuffer layout from fb_var_screeninfo (the sunxi disp fb reports
# red.offset=16 -> BGRA_8888). The define is only a byte-swap workaround; if
# the UI ever shows swapped red/blue, uncomment the next line and rebuild:
# TARGET_RECOVERY_PIXEL_FORMAT := "BGRA_8888"

TW_THEME := landscape_mdpi
TW_DEVICE_VERSION := RQ713-1

TW_NO_REBOOT_BOOTLOADER := true
TW_EXCLUDE_TWRPAPP := true
TW_BRIGHTNESS_PATH := /sys/devices/virtual/disp/disp/attr/lcdbl
TW_MAX_BRIGHTNESS := 255

RECOVERY_SDCARD_ON_DATA := true
BOARD_TOUCH_RECOVERY := true
BOARD_HAS_NO_SELECT_BUTTON := true
BOARD_SUPPRESS_SECURE_ERASE := true
BOARD_SUPPRESS_EMMC_WIPE := true

# ---------------------------------------------------------------------------
# SELinux - stock recovery is permissive but init still needs sys_module
# to insmod the display/touch/nand modules.
# ---------------------------------------------------------------------------
BOARD_SEPOLICY_DIRS += $(LOCAL_PATH)/sepolicy
BOARD_SEPOLICY_UNION += module.te
