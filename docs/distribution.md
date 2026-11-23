# DroidBridge binary distribution

The macOS disk image contains DroidBridge (MIT) and two dynamically linked
libraries. Homebrew identifies both libraries as LGPL-2.1-or-later. The
library copyright notices and license texts are in the corresponding
`libmtp/` and `libusb/` directories under `Licenses/` on the disk image
and in `DroidBridge.app/Contents/Resources/Licenses/`.

| Library | Version | Source archive | SHA-256 |
| --- | --- | --- | --- |
| [libmtp](https://libmtp.sourceforge.net/) | 1.1.23 | `libmtp-1.1.23.tar.gz` | `74a2b6e8cb4a0304e95b995496ea3ac644c29371649b892b856e22f12a0bdeed` |
| [libusb](https://libusb.info/) | 1.0.30 | `libusb-1.0.30.tar.bz2` | `fea36f34f9156400209595e300840767ab1a385ede1dc7ee893015aea9c6dbaf` |

Download the corresponding-source ZIP next to the disk image on
[GitHub Releases](https://github.com/chepikaudzmitry/DroidBridge/releases).
It contains the complete DroidBridge source for the release, the upstream
library archives in `ThirdParty/`, and the Homebrew build recipes and their
BSD 2-Clause license. The packaged dylibs were built by Homebrew
from these sources. Packaging changes their Mach-O load paths and applies
local ad hoc signatures.

## Rebuild with modified libraries

Install the build tools described in the DroidBridge README. Extract the
archives in `ThirdParty/`. To use modified libraries, edit the extracted
sources before building. Use a dedicated installation prefix and set
`PKG_CONFIG_PATH` so the app links against the libraries installed there.

```sh
prefix="$PWD/local-deps"
(
  cd ThirdParty/libusb-1.0.30
  ./configure --prefix="$prefix" --disable-dependency-tracking
  make
  make install
)
export PKG_CONFIG_PATH="$prefix/lib/pkgconfig"
(
  cd ThirdParty/libmtp-1.1.23
  ./configure --prefix="$prefix" --disable-mtpz
  make
  make install
)
cd DroidBridge
./Scripts/build-app.sh -c release
open .build/DroidBridge.app
```

You may modify the work for your own use and reverse engineer it to debug
those modifications under the terms of LGPL 2.1 section 6. The MIT license
for DroidBridge is included in the source and binary distributions.
