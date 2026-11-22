# DroidBridge

[English](README.md) · [Русский](README.ru.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português (Brasil)](README.pt-BR.md) · [日本語](README.ja.md) · [简体中文](README.zh-Hans.md)

DroidBridge is a native macOS app for transferring files and folders between a Mac and an Android device over USB (MTP). It provides a two-pane browser, optional photo thumbnails and a transfer queue.

## Build and run

You need macOS 26, Xcode with the macOS 26 SDK and Homebrew. Local builds use the Homebrew libraries installed on your Mac. The project has been tested on Apple Silicon.

```sh
brew install libmtp pkgconf
./Scripts/build-app.sh -c release
open .build/DroidBridge.app
```

## Connect and copy

Unlock your Android device, connect it with a USB data cable and select **File transfer** in its USB options. Allow access if prompted. Close any other app using the same MTP device. USB debugging is unnecessary.

Double-click to open a folder. Use ⌘O to choose a Mac folder and ⌘R to refresh. Transfer the selected items using the arrows between the panes or by dragging them. If a name is already in use, you can skip the item or keep a renamed copy.

## Language

Open **DroidBridge → Settings** (⌘,) to choose a language or use the system language. English is the fallback.

## Tests and USB diagnostic tool

```sh
swift build
swift test
.build/debug/droidbridge-usb --help
```

### Test with a phone

Connect one Android device in File transfer mode and close DroidBridge before running the USB diagnostic tool. Use the storage ID printed by `storages` and the folder ID printed by the first `ls` command. The IDs below are examples. Look up the IDs again after reconnecting.

```sh
.build/debug/droidbridge-usb devices
.build/debug/droidbridge-usb storages
.build/debug/droidbridge-usb ls 65537
.build/debug/droidbridge-usb ls 65537 42
```

To test a round trip, use a unique filename and replace `123` with the object ID printed by `push`. The two checksums should match.

```sh
printf 'DroidBridge USB check\n' > droidbridge-usb-check.txt
.build/debug/droidbridge-usb push droidbridge-usb-check.txt 65537 42
.build/debug/droidbridge-usb pull 123 droidbridge-usb-returned.txt
shasum -a 256 droidbridge-usb-check.txt droidbridge-usb-returned.txt
```

For more coverage, repeat with a filename containing Unicode and a file larger than 4 GiB. Test Ctrl+C and a cable disconnect in both directions. On Ctrl+C, a download lets the USB exchange finish and removes the temporary file. An upload already underway is allowed to finish. Immediate cancellation through libmtp left the MTP session unresponsive on the Samsung test device.

Failed downloads remove the temporary copy and preserve an existing destination file. A failed upload may leave a partial file on the phone. Reconnect and refresh the destination folder to check its contents before retrying. If the Samsung is detected over USB but its storage is unavailable, try switching from Photo transfer back to File transfer.
