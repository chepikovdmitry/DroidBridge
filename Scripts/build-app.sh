#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
source Scripts/version.env
swift build --product DroidBridge "$@"
binary_dir="$(swift build --show-bin-path "$@")"
bundle="${DROIDBRIDGE_APP_OUTPUT:-$PWD/.build/DroidBridge.app}"
mkdir -p "$bundle/Contents/MacOS" "$bundle/Contents/Resources"
staged_binary="$(mktemp "$bundle/Contents/MacOS/.DroidBridge.XXXXXX")"
trap 'rm -f "$staged_binary"' EXIT
cp -p "$binary_dir/DroidBridge" "$staged_binary"
mv -f "$staged_binary" "$bundle/Contents/MacOS/DroidBridge"
cp Resources/DroidBridge.icns "$bundle/Contents/Resources/DroidBridge.icns"
cp -R "$binary_dir/DroidBridge_DroidBridgeCore.bundle" "$bundle/Contents/Resources/"
cat > "$bundle/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key><string>app.droidbridge.desktop</string>
    <key>CFBundleName</key><string>DroidBridge</string>
    <key>CFBundleDisplayName</key><string>DroidBridge</string>
    <key>CFBundleDevelopmentRegion</key><string>en</string>
    <key>CFBundleLocalizations</key>
    <array>
        <string>en</string><string>ru</string><string>es</string><string>fr</string>
        <string>de</string><string>pt-BR</string><string>ja</string><string>zh-Hans</string>
    </array>
    <key>CFBundleExecutable</key><string>DroidBridge</string>
    <key>CFBundleIconFile</key><string>DroidBridge.icns</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleVersion</key><string>${DROIDBRIDGE_BUILD_NUMBER}</string>
    <key>CFBundleShortVersionString</key><string>${DROIDBRIDGE_VERSION}</string>
    <key>LSMinimumSystemVersion</key><string>26.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>UTExportedTypeDeclarations</key>
    <array><dict>
        <key>UTTypeIdentifier</key><string>app.droidbridge.selection</string>
        <key>UTTypeDescription</key><string>DroidBridge Selection</string>
        <key>UTTypeConformsTo</key><array><string>public.data</string></array>
    </dict></array>
</dict>
</plist>
PLIST
codesign --force --sign - "$bundle"
printf '%s\n' "$bundle"
