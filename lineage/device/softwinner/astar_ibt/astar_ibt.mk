LOCAL_PATH := device/softwinner/astar_ibt

$(call inherit-product, $(SRC_TARGET_DIR)/product/aosp_base_telephony.mk)
$(call inherit-product, vendor/softwinner/astar_ibt/astar_ibt-vendor.mk)

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/fstab.sun8i:root/fstab.sun8i \
    $(LOCAL_PATH)/rootdir/init.recovery.sun8i.rc:root/init.recovery.sun8i.rc \
    $(LOCAL_PATH)/rootdir/init.sun8i.rc:root/init.sun8i.rc \
    $(LOCAL_PATH)/rootdir/init.sun8i.usb.rc:root/init.sun8i.usb.rc \
    $(LOCAL_PATH)/rootdir/init.sensors.rc:root/init.sensors.rc \
    $(LOCAL_PATH)/rootdir/init.sun8i.common.rc:root/init.sun8i.common.rc \
    $(LOCAL_PATH)/rootdir/init.common.rc:root/init.common.rc \
    $(LOCAL_PATH)/rootdir/ueventd.sun8i.rc:root/ueventd.sun8i.rc \
    $(LOCAL_PATH)/rootdir/disp.ko:root/disp.ko \
    $(LOCAL_PATH)/rootdir/lcd.ko:root/lcd.ko \
    $(LOCAL_PATH)/rootdir/nand.ko:root/nand.ko \
    $(LOCAL_PATH)/rootdir/gslX680new.ko:root/gslX680new.ko \
    $(LOCAL_PATH)/rootdir/sw-device.ko:root/sw-device.ko \
    $(LOCAL_PATH)/rootdir/sunxi-keyboard.ko:root/sunxi-keyboard.ko


PRODUCT_PROPERTY_OVERRIDES += \
    ro.hardware=sun8i \
    ro.board.platform=astar \
    ro.sf.lcd_density=160 \
    wifi.interface=wlan0 \
    ro.opengles.version=131072

PRODUCT_AAPT_CONFIG := normal mdpi
PRODUCT_AAPT_PREF_CONFIG := mdpi
