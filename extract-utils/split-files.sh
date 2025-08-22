#!/bin/bash

# Usage check
if [ -z "$1" ]; then
    echo "Usage: $0 <PATH_TO_DUMP_FOLDER>"
    exit 1
fi

DUMP_DIR="$1"

# Determine directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # extract-utils
GMS_ROOT="$(dirname "$SCRIPT_DIR")"                          # root gms folder
CUSTOM_GMS_DIR="$GMS_ROOT/custom-gms"
PROP_FILE="$SCRIPT_DIR/proprietary-files-splited.txt"
PROPRIETARY_DIR="$CUSTOM_GMS_DIR/proprietary"
OUTPUT_BP="$CUSTOM_GMS_DIR/Android.bp"
SETUP_MK="$CUSTOM_GMS_DIR/setup-custom-gms.mk"

# Check proprietary-files-splited.txt exists
if [ ! -f "$PROP_FILE" ]; then
    echo "Error: $PROP_FILE not found in $SCRIPT_DIR"
    exit 1
fi

# Create custom-gms/proprietary folder
mkdir -p "$PROPRIETARY_DIR"

# Clear Android.bp and setup-custom-gms.mk
echo "// Auto-generated Android.bp for proprietary APKs" > "$OUTPUT_BP"
echo "" >> "$OUTPUT_BP"
echo "# Build custom-gms" > "$SETUP_MK"
echo "PRODUCT_PACKAGES += \\" >> "$SETUP_MK"

APK_NAMES=()

# Loop through proprietary-files-splited.txt
while IFS= read -r line; do
    [[ -z "$line" ]] && continue

    # Extract APK path before semicolon
    apk_path="${line%%;*}"
    full_apk="$DUMP_DIR/$apk_path"

    if [ ! -f "$full_apk" ]; then
        echo "Warning: APK not found -> $full_apk"
        continue
    fi

    # Get APK base name
    base="$(basename "$full_apk" .apk)"
    APK_NAMES+=("$base")

    # Make target folder in proprietary/
    target_folder="$PROPRIETARY_DIR/$base"
    mkdir -p "$target_folder"

    # Split APK into 50MB chunks
    split -b 50M --numeric-suffixes=0 --suffix-length=2 "$full_apk" "$target_folder/$base.apk"

    echo "Split done for $base"

    # Determine flags based on original path
    PRIVILEGED="false"
    PRODUCT_SPECIFIC="false"
    SYSTEM_EXT_SPECIFIC="false"

    case "$apk_path" in
        product/priv-app/*)
            PRIVILEGED="true"
            PRODUCT_SPECIFIC="true"
            ;;
        product/app/*)
            PRODUCT_SPECIFIC="true"
            ;;
        system/priv-app/*)
            PRIVILEGED="true"
            ;;
        system/app/*)
            ;;
        system_ext/priv-app/*)
            PRIVILEGED="true"
            SYSTEM_EXT_SPECIFIC="true"
            ;;
        system_ext/app/*)
            SYSTEM_EXT_SPECIFIC="true"
            ;;
    esac

    # Use relative path for Android.bp
    relative_path="proprietary/$base"

    # Append to Android.bp
    cat >> "$OUTPUT_BP" <<EOL

genrule {
    name: "merge_$base",
    srcs: [
        "$relative_path/*.apk*",
    ],
    out: ["$base.apk"],
    cmd: "cat \$(in) > \$(out)",
}

android_app_import {
    name: "$base",
    owner: "gms",
    apk: ":merge_$base",
    preprocessed: true,
    presigned: true,
    dex_preopt: {
        enabled: false,
    },
    privileged: $PRIVILEGED,
    product_specific: $PRODUCT_SPECIFIC,
    system_ext_specific: $SYSTEM_EXT_SPECIFIC,
}
EOL

done < "$PROP_FILE"

# Generate setup-custom-gms.mk dynamically
LAST_INDEX=$((${#APK_NAMES[@]} - 1))
for i in "${!APK_NAMES[@]}"; do
    if [ "$i" -eq "$LAST_INDEX" ]; then
        echo -e "\t${APK_NAMES[$i]}" >> "$SETUP_MK"
    else
        echo -e "\t${APK_NAMES[$i]} \\" >> "$SETUP_MK"
    fi
done

echo "All APKs have been split."
echo "Android.bp generated at $OUTPUT_BP"
echo "setup-custom-gms.mk generated at $SETUP_MK"
