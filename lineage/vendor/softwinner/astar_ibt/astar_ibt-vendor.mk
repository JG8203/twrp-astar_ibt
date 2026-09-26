LOCAL_PATH := vendor/softwinner/astar_ibt/proprietary

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/bin/rild:system/bin/rild \
    $(LOCAL_PATH)/bin/radiooptions:system/bin/radiooptions \
    $(LOCAL_PATH)/bin/setbtmacaddr:system/bin/setbtmacaddr \
    $(LOCAL_PATH)/bin/setmacaddr:system/bin/setmacaddr \
    $(LOCAL_PATH)/bin/wpa_supplicant:system/bin/wpa_supplicant \
    $(LOCAL_PATH)/bin/wpa_cli:system/bin/wpa_cli \
    $(LOCAL_PATH)/lib/egl/aw_version:system/lib/egl/aw_version \
    $(LOCAL_PATH)/lib/egl/egl.cfg:system/lib/egl/egl.cfg \
    $(LOCAL_PATH)/lib/egl/libGLES_mali.so:system/lib/egl/libGLES_mali.so \
    $(LOCAL_PATH)/lib/hw/audio.primary.astar.so:system/lib/hw/audio.primary.astar.so \
    $(LOCAL_PATH)/lib/hw/camera.astar.so:system/lib/hw/camera.astar.so \
    $(LOCAL_PATH)/lib/hw/gralloc.default.so:system/lib/hw/gralloc.default.so \
    $(LOCAL_PATH)/lib/hw/hwcomposer.astar.so:system/lib/hw/hwcomposer.astar.so \
    $(LOCAL_PATH)/lib/hw/lights.astar.so:system/lib/hw/lights.astar.so \
    $(LOCAL_PATH)/lib/hw/power.default.so:system/lib/hw/power.default.so \
    $(LOCAL_PATH)/lib/hw/sensors.exdroid.so:system/lib/hw/sensors.exdroid.so \
    $(LOCAL_PATH)/lib/libsoftwinner-ril-6.0.so:system/lib/libsoftwinner-ril-6.0.so \
    $(LOCAL_PATH)/lib/libOmxCore.so:system/lib/libOmxCore.so \
    $(LOCAL_PATH)/lib/libOmxVdec.so:system/lib/libOmxVdec.so \
    $(LOCAL_PATH)/lib/libOmxVenc.so:system/lib/libOmxVenc.so \
    $(LOCAL_PATH)/lib/libstagefright_yuv.so:system/lib/libstagefright_yuv.so \
    $(LOCAL_PATH)/lib/libsunxi_crypto.so:system/lib/libsunxi_crypto.so \
    $(LOCAL_PATH)/etc/camera.cfg:system/etc/camera.cfg \
    $(LOCAL_PATH)/etc/media_profiles.xml:system/etc/media_profiles.xml \
    $(LOCAL_PATH)/etc/audio_policy.conf:system/etc/audio_policy.conf \
    $(LOCAL_PATH)/etc/audio_effects.conf:system/etc/audio_effects.conf \
    $(LOCAL_PATH)/etc/wifi/wpa_supplicant.conf:system/etc/wifi/wpa_supplicant.conf \
    $(LOCAL_PATH)/etc/wifi/wpa_supplicant_overlay.conf:system/etc/wifi/wpa_supplicant_overlay.conf \
    $(LOCAL_PATH)/etc/wifi/wifi_efuse_8723cs.map:system/etc/wifi/wifi_efuse_8723cs.map

$(foreach fw,$(notdir $(wildcard $(LOCAL_PATH)/etc/firmware/rtl8723cs_*)),\
  $(eval PRODUCT_COPY_FILES += $(LOCAL_PATH)/etc/firmware/$(fw):system/etc/firmware/$(fw)))

PRODUCT_PACKAGES += astar_ibt_vendor
