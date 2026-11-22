# DroidBridge

[English](README.md) · [Русский](README.ru.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português (Brasil)](README.pt-BR.md) · [日本語](README.ja.md) · [简体中文](README.zh-Hans.md)

DroidBridge 是一款 macOS 原生应用，可通过 USB（MTP）在 Mac 和 Android 设备之间传输文件和文件夹。它提供双栏文件浏览器、可选的照片缩略图和传输队列。

![DroidBridge 文件浏览窗口，显示 Mac 和 Android 两栏及传输进度](docs/screenshots/droidbridge-browser.png)

## 构建和运行

需要 macOS 26 或更高版本。已在 Apple Silicon 上验证构建。

1. 从 [Mac App Store](https://apps.apple.com/app/xcode/id497799835) 或 [Apple Developer Downloads](https://developer.apple.com/download/all/) 安装完整的 Xcode。使用自带 macOS 26 或更高版本 SDK 的 Xcode 26 或更高版本。打开一次 Xcode，并完成首次启动设置。

2. 在终端中检查当前选用的 Xcode 和 SDK。如果终端使用独立的命令行工具或旧版 Xcode，请先切换到完整应用。如果 Xcode 安装在别处，请调整路径。

   ```sh
   # Only if you need to select Xcode
   sudo xcode-select --switch /Applications/Xcode.app
   xcodebuild -version
   xcrun --sdk macosx --show-sdk-version
   ```

3. 如果未安装 Homebrew，请运行 [brew.sh](https://brew.sh/) 上的安装程序。按 **Next steps** 提示将 Homebrew 添加到 shell，然后通过 `brew --version` 验证。

   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

4. 克隆仓库并构建应用。如果下载的是 ZIP，请解压，在终端中打开项目目录，然后从 `brew install` 开始执行。

   ```sh
   git clone https://github.com/chepikovdmitry/DroidBridge.git
   cd DroidBridge
   brew install libmtp pkgconf
   ./Scripts/build-app.sh -c release
   open .build/DroidBridge.app
   ```

应用将生成在 `.build/DroidBridge.app`，使用该 Mac 上已安装的 Homebrew 库。

## 连接和复制

1. 解锁 Android 设备，用支持数据传输的 USB 线连接，然后在 USB 设置中选择**文件传输**。如果系统提示授权，请允许访问，并关闭其他正在使用同一 MTP 设备的应用。无需开启 USB 调试。
2. 左侧是 Mac。点击**选择文件夹**（⌘O）指定本地源目录或目标目录。右侧是 Android。双击打开文件夹，点击向上箭头返回上一级，点击列标题排序。按 ⌘R 刷新列表。
3. 选择文件或文件夹。点击 **←** 从 Android 复制到 Mac，点击 **→** 从 Mac 复制到 Android，也可将选中的项目拖到目标栏。
4. **传输队列**顶部显示当前项目和进度。展开队列可查看待传输和已完成的项目。如果 Mac 上已有同名文件，可选择跳过或保留重命名的副本。
5. 打开 Android 栏的预览可显示可见照片和视频的缩略图。

## 语言

点击齿轮图标或按 ⌘, 打开**设置**。选择八种语言之一，或跟随系统语言。更改立即生效，没有对应语言时会使用英语。

![DroidBridge 设置窗口，显示语言选项和版本](docs/screenshots/droidbridge-settings.png)

## 测试和 USB 诊断

```sh
swift build
swift test
.build/debug/droidbridge-usb --help
```
