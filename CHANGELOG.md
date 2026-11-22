# Changelog

## Unreleased

- Added a bug report form, security reporting instructions, and troubleshooting steps in the README.
- Added automated Swift tests and app bundle verification on macOS 26 and Apple Silicon.

## [0.2.0](https://github.com/chepikovdmitry/DroidBridge/releases/tag/v0.2.0) — 2026-11-23

First packaged preview for macOS 26 or later on Apple Silicon.

- Browse files on Mac and Android side by side and copy files or folders in either direction over USB MTP.
- View thumbnails for visible Android photos and videos and track the current transfer in the queue.
- Choose one of eight interface languages or follow the system language in Settings.
- Download a DMG with libmtp and libusb bundled. The release includes checksums and source for the included libraries.

### Known limitations

- The prebuilt preview is for Apple Silicon and uses an ad hoc signature without Apple notarization. macOS may block the initial launch.
- MTP behavior varies by device. A failed upload may leave a partial file on the phone. Reconnect and check the destination before retrying.
