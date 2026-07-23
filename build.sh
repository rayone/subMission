#!/bin/bash
set -euo pipefail

VERSION="1"

APP="subMission"
BUNDLE="${APP}.app"
CONTENTS="${BUNDLE}/Contents"
MACOS_DIR="${CONTENTS}/MacOS"
RES_DIR="${CONTENTS}/Resources"
ENTITLEMENTS="Resources/subMission.entitlements"

# --- Icon generation ---
generate_icons() {
    local src="$1" name="$2"
    if [ ! -f "$src" ]; then
        echo "  ⚠ Icon source not found: $src (skipping)"
        return 0
    fi
    local iconset=".build/${name}.iconset"
    mkdir -p "$iconset"
    for size in 16 32 64 128 256 512 1024; do
        case $size in
            16)   sips -z 16 16 "$src" --out "$iconset/icon_16x16.png" >/dev/null ;;
            32)   sips -z 32 32 "$src" --out "$iconset/icon_16x16@2x.png" >/dev/null
                  sips -z 32 32 "$src" --out "$iconset/icon_32x32.png" >/dev/null ;;
            64)   sips -z 64 64 "$src" --out "$iconset/icon_32x32@2x.png" >/dev/null ;;
            128)  sips -z 128 128 "$src" --out "$iconset/icon_128x128.png" >/dev/null ;;
            256)  sips -z 256 256 "$src" --out "$iconset/icon_128x128@2x.png" >/dev/null
                  sips -z 256 256 "$src" --out "$iconset/icon_256x256.png" >/dev/null ;;
            512)  sips -z 512 512 "$src" --out "$iconset/icon_256x256@2x.png" >/dev/null
                  sips -z 512 512 "$src" --out "$iconset/icon_512x512.png" >/dev/null ;;
            1024) sips -z 1024 1024 "$src" --out "$iconset/icon_512x512@2x.png" >/dev/null ;;
        esac
    done
    iconutil --convert icns -o ".build/${name}.icns" "$iconset"
    echo "  ✓ ${name}.icns"
}

# --- Build ---
build_release() {
    echo "Building ${APP} v${VERSION}..."
    swift build -c release 2>&1 | tail -3
    echo "  ✓ Compiled"
}

# --- Bundle ---
assemble_bundle() {
    echo "Assembling ${BUNDLE}..."
    rm -rf "$BUNDLE"
    mkdir -p "$MACOS_DIR" "$RES_DIR"

    # Binary
    cp ".build/release/${APP}" "$MACOS_DIR/"
    strip "$MACOS_DIR/${APP}"
    echo "  ✓ Binary (stripped)"

    # Info.plist with version injected
    sed "s/CFBundleVersion<\/key>[^<]*<string>[^<]*/CFBundleVersion<\/key>\n\t<string>${VERSION}/" \
        Resources/Info.plist | \
    sed "s/CFBundleShortVersionString<\/key>[^<]*<string>[^<]*/CFBundleShortVersionString<\/key>\n\t<string>${VERSION}/" \
        > "$CONTENTS/Info.plist"
    echo "  ✓ Info.plist (v${VERSION})"

    # Icons (optional — only if source PNGs exist)
    echo "  Icons:"
    generate_icons "icon dark.png" "AppIconDark"
    generate_icons "icon light.png" "AppIconLight"
    if [ -f ".build/AppIconDark.icns" ]; then
        cp ".build/AppIconDark.icns" "$RES_DIR/AppIconDark.icns"
        cp ".build/AppIconDark.icns" "$RES_DIR/AppIcon.icns"
    fi
    if [ -f ".build/AppIconLight.icns" ]; then
        cp ".build/AppIconLight.icns" "$RES_DIR/AppIconLight.icns"
    fi

    # Sign
    codesign --force --deep --sign - --entitlements "$ENTITLEMENTS" "$BUNDLE"
    echo "  ✓ Signed (ad-hoc)"
    echo "Built: ${BUNDLE}"
}

# --- DMG ---
create_dmg() {
    echo "Creating ${APP}.dmg..."
    rm -rf release_dmg_folder "${APP}.dmg"
    mkdir release_dmg_folder
    cp -R "${BUNDLE}" release_dmg_folder/
    ln -s /Applications release_dmg_folder/Applications
    hdiutil create -volname "$APP" -srcfolder release_dmg_folder -ov -format UDZO "${APP}.dmg"
    rm -rf release_dmg_folder
    echo "  ✓ ${APP}.dmg"
    echo "  SHA256: $(shasum -a 256 "${APP}.dmg" | cut -d' ' -f1)"
}

# --- Main ---
case "${1:-build}" in
    build)
        build_release
        ;;
    release)
        build_release
        assemble_bundle
        ;;
    dmg)
        build_release
        assemble_bundle
        create_dmg
        ;;
    clean)
        swift package clean
        rm -rf "$BUNDLE" .build "${APP}.dmg"
        echo "Cleaned."
        ;;
    version)
        echo "v${VERSION}"
        ;;
    *)
        echo "Usage: bash build.sh [build|release|dmg|clean|version]"
        exit 1
        ;;
esac
