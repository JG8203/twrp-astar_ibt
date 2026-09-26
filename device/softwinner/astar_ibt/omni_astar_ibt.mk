# Inherit device configuration.
$(call inherit-product, device/softwinner/astar_ibt/astar_ibt.mk)

# Device identifier. This must come after all inclusions.
PRODUCT_DEVICE := astar_ibt
PRODUCT_NAME := omni_astar_ibt
PRODUCT_BRAND := Allwinner
PRODUCT_MODEL := RQ-713
PRODUCT_MANUFACTURER := iNet
