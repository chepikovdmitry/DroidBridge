# DroidBridge

[English](README.md) · [Русский](README.ru.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português (Brasil)](README.pt-BR.md) · [日本語](README.ja.md) · [简体中文](README.zh-Hans.md)

DroidBridge is a native macOS app for transferring files and folders between a Mac and an Android device over USB (MTP). It provides a two-pane browser, optional photo thumbnails and a transfer queue.

![DroidBridge file browser with Mac and Android panes and transfer progress](docs/screenshots/droidbridge-browser.png)

## Download

We recommend building DroidBridge from source using the instructions below.

The [ready-built disk image](https://github.com/chepikaudzmitry/DroidBridge/releases/tag/v0.2.0) supports Apple Silicon and macOS 26 or later. Open it and drag DroidBridge to Applications. The build uses an ad hoc signature and has no Apple notarization. macOS may block the first launch. If you trust the download, follow [Apple’s first-launch instructions](https://support.apple.com/en-us/102445).

The release also includes checksums and the corresponding source for the bundled libraries. See [distribution and license details](docs/distribution.md).

## Build and run

You need macOS 26 or later. The build has been tested on Apple Silicon.

1. Install the full Xcode app from the [Mac App Store](https://apps.apple.com/app/xcode/id497799835) or [Apple Developer Downloads](https://developer.apple.com/download/all/). Choose Xcode 26 or later with a macOS 26 or newer SDK. Open Xcode once and complete its first-launch setup.

2. In Terminal, check the selected Xcode and SDK. If Terminal is using the standalone Command Line Tools or an older Xcode, select the full Xcode app first. Adjust the path if you installed Xcode elsewhere.

   ```sh
   # Only if you need to select Xcode
   sudo xcode-select --switch /Applications/Xcode.app
   xcodebuild -version
   xcrun --sdk macosx --show-sdk-version
   ```

3. If Homebrew is missing, run the installer from [brew.sh](https://brew.sh/). Follow its **Next steps** to add Homebrew to your shell, then check that `brew --version` works.

   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

4. Clone the repository and build the app. If you downloaded a ZIP, extract it and open its folder in Terminal, then start at `brew install`.

   ```sh
   git clone https://github.com/chepikaudzmitry/DroidBridge.git
   cd DroidBridge
   brew install libmtp pkgconf
   ./Scripts/build-app.sh -c release
   open .build/DroidBridge.app
   ```

The app is built locally at `.build/DroidBridge.app` and uses the Homebrew libraries installed on that Mac.

## Connect and copy

1. Unlock Android, connect it with a USB data cable, and choose **File transfer** in the phone’s USB options. Allow access if prompted. Close other apps that are using the same MTP device. USB debugging is unnecessary.
2. The left pane shows the Mac. Click **Choose Folder** (⌘O) to set the local source or destination. The right pane shows Android storage. Double-click a folder to open it, click the up arrow to go back one level, and click a column heading to sort. Use the refresh button (⌘R) to reload the lists.
3. Select files or folders. Click **←** to copy from Android to the Mac, or **→** to copy from the Mac to Android. You can also drag the selection into the destination pane.
4. The **Transfer Queue** keeps the current item and its progress at the top. Open the queue to see pending and completed items. If a file already exists on the Mac, choose **Skip** or **Keep Both**.
5. Use **Previews** in the Android pane to load thumbnails for visible photos and videos.

## Language

Click the gear in the main window or press ⌘, to open **Settings**. Choose one of eight interface languages or follow the system language. The change takes effect immediately. English is the fallback.

![DroidBridge settings with a language selector and version number](docs/screenshots/droidbridge-settings.png)

## Troubleshooting

- **Phone missing.** Unlock the phone, select File transfer (MTP), and try a USB data cable connected directly to the Mac. Quit other MTP apps, reconnect the phone, and press Refresh (⌘R).
- **Storage unavailable.** On affected Samsung phones, switch to Photo transfer (PTP), then back to File transfer (MTP) and allow access if prompted.
- **Transfer stalled or interrupted.** Check the cable, free space on the destination, and any pending name conflict in the transfer queue. Reconnect and refresh if needed. After a failed upload, check the phone's target folder for a partial file before retrying.

[Report a bug](https://github.com/chepikaudzmitry/DroidBridge/issues/new?template=bug-report.yml) · [Report a vulnerability](SECURITY.md) · [Changelog](CHANGELOG.md)

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

## License

DroidBridge source code is released under the [MIT License](LICENSE). The [libmtp dependency](https://formulae.brew.sh/formula/libmtp) is licensed separately under LGPL-2.1-or-later.
