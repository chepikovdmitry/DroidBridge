#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
source Scripts/version.env

release_name="DroidBridge-$DROIDBRIDGE_VERSION-macOS-arm64"
output="$PWD/.build/distribution"
cache="$PWD/.build/release-sources"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

if [[ "$(uname -m)" != arm64 ]]; then
    printf '%s\n' "Build this release with native Apple Silicon tools." >&2
    exit 1
fi

mtp_prefix="$(brew --prefix libmtp)"
usb_prefix="$(brew --prefix libusb)"
mtp_version=1.1.23
usb_version=1.0.30
mtp_archive="libmtp-$mtp_version.tar.gz"
usb_archive="libusb-$usb_version.tar.bz2"

check_library_version() {
    local library="$1" expected="$2" actual
    actual="$(pkg-config --modversion "$library")"
    if [[ "$actual" != "$expected" ]]; then
        printf 'Expected %s %s for this release, found %s\n' "$library" "$expected" "$actual" >&2
        exit 1
    fi
}
export PKG_CONFIG_PATH="$mtp_prefix/lib/pkgconfig:$usb_prefix/lib/pkgconfig"
check_library_version libmtp "$mtp_version"
check_library_version libusb-1.0 "$usb_version"

mkdir -p "$output" "$cache"
fetch_source() {
    local archive="$1" url="$2" sha256="$3"
    if [[ ! -f "$cache/$archive" ]]; then
        curl -fsSL --retry 2 "$url" -o "$work/$archive"
        printf '%s  %s\n' "$sha256" "$work/$archive" | shasum -a 256 --check
        mv "$work/$archive" "$cache/$archive"
    fi
    printf '%s  %s\n' "$sha256" "$cache/$archive" | shasum -a 256 --check
}
fetch_source "$mtp_archive" \
    "https://downloads.sourceforge.net/project/libmtp/libmtp/$mtp_version/$mtp_archive" \
    74a2b6e8cb4a0304e95b995496ea3ac644c29371649b892b856e22f12a0bdeed
fetch_source "$usb_archive" \
    "https://github.com/libusb/libusb/releases/download/v$usb_version/$usb_archive" \
    fea36f34f9156400209595e300840767ab1a385ede1dc7ee893015aea9c6dbaf
fetch_source Homebrew-formula-license.txt \
    https://raw.githubusercontent.com/Homebrew/homebrew-core/main/LICENSE.txt \
    f80329e58613ad669c0e73cb132d8060b9b2c55e339c73848068e4d1567f4627

# Build from the same Git snapshot shipped as corresponding source.
revision="$(git rev-parse HEAD)"
project="$work/source/DroidBridge"
mkdir -p "$project"
git archive "$revision" | tar -xf - -C "$project"
mkdir "$work/disk"
app="$work/disk/DroidBridge.app"
(
    cd "$project"
    DROIDBRIDGE_APP_OUTPUT="$app" ./Scripts/build-app.sh -c release --scratch-path "$work/build"
)

frameworks="$app/Contents/Frameworks"
mkdir -p "$frameworks"
mtp_dylib="$mtp_prefix/lib/libmtp.9.dylib"
usb_dylib="$usb_prefix/lib/libusb-1.0.0.dylib"
cp "$mtp_dylib" "$usb_dylib" "$frameworks/"
chmod u+w "$frameworks/libmtp.9.dylib" "$frameworks/libusb-1.0.0.dylib"
executable="$app/Contents/MacOS/DroidBridge"
install_name_tool -change "$mtp_dylib" \
    '@executable_path/../Frameworks/libmtp.9.dylib' "$executable"
install_name_tool -id '@loader_path/libmtp.9.dylib' \
    -change "$usb_dylib" '@loader_path/libusb-1.0.0.dylib' "$frameworks/libmtp.9.dylib"
install_name_tool -id '@loader_path/libusb-1.0.0.dylib' "$frameworks/libusb-1.0.0.dylib"

for file in "$executable" "$frameworks/libmtp.9.dylib" "$frameworks/libusb-1.0.0.dylib"; do
    [[ "$(lipo -archs "$file")" == arm64 ]]
    otool -L "$file" | awk 'NR > 1 && $1 !~ /^(@|\/usr\/lib\/|\/System\/Library\/)/ { print; failed = 1 } END { exit failed }'
done
otool -L "$executable" | grep -F '@executable_path/../Frameworks/libmtp.9.dylib'
otool -L "$frameworks/libmtp.9.dylib" | grep -F '@loader_path/libusb-1.0.0.dylib'

notices="$work/disk/Licenses"
mkdir -p "$notices/libmtp" "$notices/libusb"
cp "$project/LICENSE" "$notices/DroidBridge-MIT.txt"
cp "$project/docs/distribution.md" "$notices/README.md"
cp "$mtp_prefix/COPYING" "$mtp_prefix/AUTHORS" "$notices/libmtp/"
cp "$usb_prefix/COPYING" "$usb_prefix/AUTHORS" "$notices/libusb/"
for file in AUTHORS COPYING; do
    tar -xOf "$cache/$mtp_archive" "libmtp-$mtp_version/$file" | cmp - "$notices/libmtp/$file"
    tar -xOf "$cache/$usb_archive" "libusb-$usb_version/$file" | cmp - "$notices/libusb/$file"
done
ditto "$notices" "$app/Contents/Resources/Licenses"
codesign --force --sign - "$frameworks/libmtp.9.dylib" "$frameworks/libusb-1.0.0.dylib"
codesign --force --sign - "$app"
codesign --verify --strict --deep "$app"
ln -s /Applications "$work/disk/Applications"

third_party="$work/source/ThirdParty"
mkdir "$third_party"
cp "$cache/$mtp_archive" "$cache/$usb_archive" "$cache/Homebrew-formula-license.txt" "$third_party/"
cp "$mtp_prefix/.brew/libmtp.rb" "$usb_prefix/.brew/libusb.rb" "$third_party/"
cp "$project/docs/distribution.md" "$work/source/README.md"
printf '%s\n' "$revision" > "$work/source/DROIDBRIDGE-COMMIT"
dmg="$release_name.dmg"
source_zip="$release_name-corresponding-source.zip"
hdiutil create -quiet -srcfolder "$work/disk" -volname DroidBridge -format UDZO "$work/$dmg"
ditto -c -k --keepParent "$work/source" "$work/$source_zip"
(
    cd "$work"
    shasum -a 256 "$dmg" "$source_zip" > SHA256SUMS.txt
)
mv -f "$work/$dmg" "$work/$source_zip" "$work/SHA256SUMS.txt" "$output/"
printf '%s\n' "$output/$dmg" "$output/$source_zip" "$output/SHA256SUMS.txt"
