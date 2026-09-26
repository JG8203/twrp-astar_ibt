$(call inherit-product, device/softwinner/astar_ibt/astar_ibt.mk)
$(call inherit-product, vendor/cm/config/common_full_tablet_wifionly.mk)

PRODUCT_NAME := cm_astar_ibt
PRODUCT_DEVICE := astar_ibt
PRODUCT_BRAND := Allwinner
PRODUCT_MODEL := RQ-713
PRODUCT_MANUFACTURER := iNet
PRODUCT_RELEASE_NAME := RQ-713

PRODUCT_CHARACTERISTICS := tablet

# Keep the first bring-up free of GApps and other optional packages.
PRODUCT_PROPERTY_OVERRIDES += ro.config.low_ram=true
