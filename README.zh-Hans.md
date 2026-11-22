# DroidBridge

[English](README.md) · [Русский](README.ru.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português (Brasil)](README.pt-BR.md) · [日本語](README.ja.md) · [简体中文](README.zh-Hans.md)

DroidBridge 是一款 macOS 原生应用，可通过 USB（MTP）在 Mac 和 Android 设备之间传输文件和文件夹。它提供双栏文件浏览器、可选的照片缩略图和传输队列。

## 构建和运行

需要 macOS 26、带有 macOS 26 SDK 的 Xcode 和 Homebrew。本地构建使用 Mac 上已安装的 Homebrew 库。项目已在 Apple Silicon 上测试。

```sh
brew install libmtp pkgconf
./Scripts/build-app.sh -c release
open .build/DroidBridge.app
```

## 连接和复制

解锁 Android 设备，使用支持数据传输的 USB 线连接，然后在 USB 设置中选择**文件传输**。如果系统提示授权，请允许访问。关闭其他正在使用同一 MTP 设备的应用。无需开启 USB 调试。

双击打开文件夹。按 ⌘O 选择 Mac 上的文件夹，按 ⌘R 刷新列表。使用两栏之间的箭头或拖放来传输选中的项目。如遇重名，可以跳过该项目或另存为重命名的副本。

## 语言

打开 **DroidBridge → 设置**（⌘,）选择语言或使用系统语言。没有对应的语言时将使用英语。

## 测试和 USB 诊断

```sh
swift build
swift test
.build/debug/droidbridge-usb --help
```
