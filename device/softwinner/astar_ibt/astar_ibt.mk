#
# Copyright (C) 2012 The Android Open Source Project
#
# Shared product configuration for the RQ-713 TWRP build.
#

LOCAL_PATH := device/softwinner/astar_ibt

# Inherit from the common AOSP product configuration.
$(call inherit-product, $(SRC_TARGET_DIR)/product/aosp_base_telephony.mk)

# Inherit some common Omni/TWRP stuff.
$(call inherit-product, vendor/omni/config/common.mk)

# ro.hardware must be sun8i so that init imports init.recovery.sun8i.rc
# (the modules that bring up display/touch/nand live there).
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    ro.hardware=sun8i
