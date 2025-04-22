#!/bin/bash
#
# SPDX-License-Identifier: Apache-2.0
#

DEBUG=0
if [[ ${DEBUG} != 0 ]]; then
    log="/dev/tty"
else
    log="/dev/null"
fi

# --- Source check ---
if [[ -z "${SRC}" ]] && [[ -z "${1}" ]]; then
    echo "Missing source"
    exit 1
elif [[ -z "${SRC}" ]]; then
    echo "Using '${1}' as source"
    SRC="${1}"
fi

# --- Determine output directory ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GMS_ROOT="$(dirname "$SCRIPT_DIR")"
OUT_DIR="${GMS_ROOT}/custom-gms/proprietary"
mkdir -p "$OUT_DIR"

# --- Temporary working directory ---
TMPDIR=$(mktemp -d)

# --- Locate the APEX file ---
if [[ -f "${SRC}/system/apex/com.google.android.extservices.apex" ]]; then
    APEX_PATH="${SRC}/system/apex/com.google.android.extservices.apex"
elif [[ -f "${SRC}/system/system/apex/com.google.android.extservices.apex" ]]; then
    APEX_PATH="${SRC}/system/system/apex/com.google.android.extservices.apex"
else
    echo "APEX file not found in expected locations!"
    exit 1
fi

# --- Unpack the APEX ---
apktool d "${APEX_PATH}" -o "${TMPDIR}/out" > "${log}"
7z e "${TMPDIR}/out/unknown/original_apex" -o"${TMPDIR}/extracted_apex" > "${log}"
7z e "${TMPDIR}/extracted_apex/apex_payload.img" -o"${TMPDIR}" > "${log}"

# --- Prepare GoogleExtServices folder inside proprietary/ ---
TARGET_DIR="$OUT_DIR/GoogleExtServices"
mkdir -p "$TARGET_DIR"

# --- Copy APK and XML into this single folder ---
cp "${TMPDIR}/GoogleExtServices.apk" "$TARGET_DIR/"
cp "${TMPDIR}/privapp_allowlist_com.google.android.ext.services.xml" "$TARGET_DIR/"

# --- Create Android.bp in the same folder ---
cat > "$TARGET_DIR/Android.bp" <<EOL
android_app_import {
    name: "GoogleExtServices",
    owner: "gms",
    apk: "GoogleExtServices.apk",
    overrides: ["ExtServices"],
    preprocessed: true,
    presigned: true,
    dex_preopt: {
        enabled: false,
    },
    privileged: true,
}
EOL

cat > "$TARGET_DIR/setup.mk" <<'EOF'
#!/bin/bash
# Generate a static setup-custom-gms.mk for GoogleExtServices

# GoogleExtServices
PRODUCT_COPY_FILES += \
    vendor/gms/custom-gms/proprietary/GoogleExtServices/privapp_allowlist_com.google.android.ext.services.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/privapp_allowlist_com.google.android.ext.services.xml

PRODUCT_PACKAGES += \
    GoogleExtServices

EOF

chmod +x "$TARGET_DIR/setup.mk"

# --- Clean temporary directory ---
rm -rf "$TMPDIR"

# --- Update proprietary-files-GoogleExtServices.txt ---
PROP_FILE="$SCRIPT_DIR/proprietary-files-GoogleExtServices.txt"
if [[ -f "$PROP_FILE" ]]; then
    file1="GoogleExtServices/GoogleExtServices.apk"
    file2="GoogleExtServices/privapp_allowlist_com.google.android.ext.services.xml"

    hash1=$(echo "$file1" | sha1sum | awk '{print $1}')
    hash2=$(echo "$file2" | sha1sum | awk '{print $1}')

    echo "Updating $file1 with hash $hash1"
    echo "Updating $file2 with hash $hash2"

    if grep -q "$file1" "$PROP_FILE"; then
        sed -i "s#${file1}.*#${file1};OVERRIDES=ExtServices;PRESIGNED|${hash1}#" "$PROP_FILE"
    else
        echo "${file1};OVERRIDES=ExtServices;PRESIGNED|${hash1}" >> "$PROP_FILE"
    fi

    if grep -q "$file2" "$PROP_FILE"; then
        sed -i "s#${file2}.*#${file2}|${hash2}#" "$PROP_FILE"
    else
        echo "${file2}|${hash2}" >> "$PROP_FILE"
    fi
fi

echo "GoogleExtServices extraction complete!"
echo "Files, Android.bp, and setup.mk created in $TARGET_DIR"
