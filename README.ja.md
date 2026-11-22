# DroidBridge

[English](README.md) · [Русский](README.ru.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português (Brasil)](README.pt-BR.md) · [日本語](README.ja.md) · [简体中文](README.zh-Hans.md)

DroidBridge は、Mac と Android デバイス間で USB（MTP）経由でファイルやフォルダを転送する macOS ネイティブアプリです。2 ペインのファイルブラウザ、写真のサムネイル表示、転送キューを備えています。

## ビルドと起動

macOS 26、macOS 26 SDK を含む Xcode、Homebrew が必要です。ローカルビルドでは Mac にインストール済みの Homebrew ライブラリを使用します。Apple Silicon で動作確認済みです。

```sh
brew install libmtp pkgconf
./Scripts/build-app.sh -c release
open .build/DroidBridge.app
```

## 接続とコピー

Android デバイスのロックを解除して、データ転送対応の USB ケーブルで接続し、USB 設定で **ファイル転送** を選択します。確認画面が表示された場合はアクセスを許可します。同じ MTP デバイスを使用しているほかのアプリは終了してください。USB デバッグは不要です。

フォルダを開くにはダブルクリックします。⌘O で Mac のフォルダを選び、⌘R で一覧を更新します。選択した項目は、ペイン間の矢印またはドラッグ＆ドロップで転送できます。同じ名前がある場合は、スキップするか別名のコピーを保存できます。

## 言語

**DroidBridge → 設定**（⌘,）で言語を選択するか、システムの言語を使用できます。対応する言語が見つからない場合は英語が使われます。

## テストと USB 診断

```sh
swift build
swift test
.build/debug/droidbridge-usb --help
```
