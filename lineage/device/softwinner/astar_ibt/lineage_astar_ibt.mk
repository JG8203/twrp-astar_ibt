$(call inherit-product, device/softwinner/astar_ibt/astar_ibt.mk)
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

PRODUCT_NAME := lineage_astar_ibt
PRODUCT_DEVICE := astar_ibt
PRODUCT_BRAND := Allwinner
PRODUCT_MODEL := RQ-713
PRODUCT_MANUFACTURER := iNet
PRODUCT_RELEASE_NAME := RQ-713

PRODUCT_CHARACTERISTICS := tablet

# Keep the first bring-up free of GApps and other optional packages.
$(call inherit-product, $(SRC_TARGET_DIR)/product/low_ram.mk)
