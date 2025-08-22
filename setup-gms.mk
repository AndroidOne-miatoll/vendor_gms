# Inherit partner-gms
$(call inherit-product, vendor/gms/partner-gms/partner-gms-vendor.mk)

# Build custom-gms
$(call inherit-product, vendor/gms/custom-gms/setup-custom-gms.mk)

