# DroidBridge USB Prototype Implementation Plan

**Goal.** Detect an Android phone, browse folders by object ID, and copy one file in either direction.

**Architecture.** A SwiftPM executable opens one uncached MTP session per command. The libmtp adapter owns the C session and streams file descriptors. A Swift core publishes verified downloads atomically.

**Tech stack.** Swift 6, SwiftPM, Darwin, libmtp via Homebrew.

**Spec.** `docs/superpowers/specs/2026-11-22-droidbridge-design.md`

## Local downloads

- [x] Test that `DownloadFile.write(to:expectedBytes:transfer:)` publishes the exact bytes on success.
- [x] Test that reported success with a short write and a thrown transfer error both leave the destination and temporary file absent.
- [x] Test that a file created at the destination during the transfer survives unchanged.
- [x] Implement the operation with a uniquely created sibling file, `fstat`, and exclusive rename. Run `swift test`.

## MTP commands

- [x] Implement `devices`, `storages`, `ls STORAGE [FOLDER]`, `pull OBJECT DESTINATION`, and `push SOURCE STORAGE FOLDER` in `Sources/DroidBridgeUSB`. Accept decimal or hexadecimal IDs and `root` as a folder.
- [x] Implement uncached folder listing and descriptor-based transfers using `Sources/CLibMTP`. Check for name conflicts before upload. After a failed upload report that the phone can retain a partial file.
- [x] Document launch and hardware verification in `README.md`.
- [x] Build and test. Check help, invalid IDs, and the response when no MTP interface is available.
- [x] On Samsung in MTP mode, find `Download`, copy a 1 MiB file with a Cyrillic name in both directions, verify SHA-256, and confirm a repeat upload rejects the name conflict.
- [x] Copy a 4,294,971,392-byte file in both directions on Samsung and verify SHA-256.
- [x] Cancel a 32 MiB download after transfer starts, verify that the local destination is absent, and verify the next MTP command still succeeds.
- [x] Disconnect the USB cable during a 2 GiB upload. DroidBridge returned status 1 and reported that the phone might retain a partial file.

On the test Samsung, toggling the USB mode restored a session that stopped reporting storage to both DroidBridge and Homebrew's `mtp-detect` (libmtp 1.1.23). Immediate cancellation via the libmtp callback stalled for more than 60 seconds. The prototype now lets an in-flight USB operation finish and discards a cancelled download locally. After a physical disconnect during upload, switching USB mode restored access to `Download` and confirmed that Samsung discarded the incomplete upload. Physical disconnect during download remains unverified.
