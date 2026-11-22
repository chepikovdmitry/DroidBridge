#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
swift build --product DroidBridge "$@"
binary_dir="$(swift build --show-bin-path "$@")"
bundle="$PWD/.build/DroidBridge.app"
mkdir -p "$bundle/Contents/MacOS" "$bundle/Contents/Resources"
staged_binary="$(mktemp "$bundle/Contents/MacOS/.DroidBridge.XXXXXX")"
trap 'rm -f "$staged_binary"' EXIT
cp -p "$binary_dir/DroidBridge" "$staged_binary"
mv -f "$staged_binary" "$bundle/Contents/MacOS/DroidBridge"
cp Resources/DroidBridge.icns "$bundle/Contents/Resources/DroidBridge.icns"
cat > "$bundle/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key><string>app.droidbridge.desktop</string>
    <key>CFBundleName</key><string>DroidBridge</string>
    <key>CFBundleDisplayName</key><string>DroidBridge</string>
    <key>CFBundleExecutable</key><string>DroidBridge</string>
    <key>CFBundleIconFile</key><string>DroidBridge.icns</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>CFBundleShortVersionString</key><string>0.1.0</string>
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
