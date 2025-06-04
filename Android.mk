LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := MinimalPackage
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_TAGS := optional
LOCAL_OVERRIDES_PACKAGES += \
    TurboAdapter \
    SetupWizardPixelPrebuilt_v770520761 \
    MagicPortraitWallpapers \
    GoogleFeedback \
    Flipendo \
    TurboPrebuilt \
    TipsPrebuilt_v6.0.0.734377952 \
    PrebuiltPixelCoreServices \
    PixelSupportPrebuilt \
    HealthIntelligenceStubPrebuilt \
    AndroidAutoStubPrebuilt \
    AmbientStreaming \
    PlayAutoInstallConfig \
    MeetPrebuilt_20250518 \

LOCAL_UNINSTALLABLE_MODULE := true
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_SRC_FILES := /dev/null
include $(BUILD_PREBUILT)