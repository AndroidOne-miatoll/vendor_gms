#!/bin/bash
# Generate a static setup-custom-gms.mk for GoogleExtServices

# GoogleExtServices
PRODUCT_COPY_FILES += \
    vendor/gms/custom-gms/proprietary/GoogleExtServices/privapp_allowlist_com.google.android.ext.services.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/privapp_allowlist_com.google.android.ext.services.xml

PRODUCT_PACKAGES += \
    GoogleExtServices

