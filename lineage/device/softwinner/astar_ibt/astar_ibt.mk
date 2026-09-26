LOCAL_PATH := device/softwinner/astar_ibt

$(call inherit-product, $(SRC_TARGET_DIR)/product/aosp_base_telephony.mk)

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/fstab.sun8i:root/fstab.sun8i \
    $(LOCAL_PATH)/rootdir/init.recovery.sun8i.rc:root/init.recovery.sun8i.rc

PRODUCT_PROPERTY_OVERRIDES += \
    ro.hardware=sun8i \
    ro.board.platform=astar \
    ro.sf.lcd_density=160 \
    wifi.interface=wlan0 \
    ro.opengles.version=131072

PRODUCT_AAPT_CONFIG := normal mdpi
PRODUCT_AAPT_PREF_CONFIG := mdpi
