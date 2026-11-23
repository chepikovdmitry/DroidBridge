# DroidBridge

[English](README.md) · [Русский](README.ru.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português (Brasil)](README.pt-BR.md) · [日本語](README.ja.md) · [简体中文](README.zh-Hans.md)

DroidBridge は、Mac と Android デバイス間で USB（MTP）経由でファイルやフォルダを転送する macOS ネイティブアプリです。2 ペインのファイルブラウザ、写真のサムネイル表示、転送キューを備えています。

![Mac と Android のペインと転送の進行状況を表示する DroidBridge](docs/screenshots/droidbridge-browser.png)

## ダウンロード

以下の手順に従い、DroidBridge をソースからビルドすることをおすすめします。

[ディスクイメージ](https://github.com/chepikaudzmitry/DroidBridge/releases/tag/v0.2.0)は Apple Silicon と macOS 26 以降に対応しています。イメージを開いて DroidBridge を「アプリケーション」にドラッグしてください。このビルドは ad hoc 署名を使用しており、Apple の公証は受けていません。macOS が初回起動をブロックする場合があります。ダウンロード元を信頼できる場合は [Apple の手順](https://support.apple.com/en-us/102445)を参照してください。

リリースにはチェックサムと同梱ライブラリのソースコードも含まれます。[配布条件とライセンス](docs/distribution.md)を参照してください。

## ビルドと起動

macOS 26 以降が必要です。Apple Silicon でビルドを確認済みです。

1. [Mac App Store](https://apps.apple.com/app/xcode/id497799835) または [Apple Developer Downloads](https://developer.apple.com/download/all/) から Xcode 本体をインストールします。macOS 26 以降の SDK を含む Xcode 26 以降を使用してください。Xcode を一度開き、初回設定を完了します。

2. ターミナルで有効な Xcode と SDK を確認します。単体の Command Line Tools や古い Xcode が選択されている場合は、先に Xcode 本体に切り替えます。別の場所にインストールした場合はパスを変更してください。

   ```sh
   # Only if you need to select Xcode
   sudo xcode-select --switch /Applications/Xcode.app
   xcodebuild -version
   xcrun --sdk macosx --show-sdk-version
   ```

3. Homebrew がない場合は [brew.sh](https://brew.sh/) のインストーラーを実行します。**Next steps** に従ってシェルから Homebrew を利用できるようにし、`brew --version` で確認します。

   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

4. リポジトリをクローンしてビルドします。ZIP をダウンロードした場合は展開し、ターミナルでそのフォルダを開いて `brew install` から実行します。

   ```sh
   git clone https://github.com/chepikaudzmitry/DroidBridge.git
   cd DroidBridge
   brew install libmtp pkgconf
   ./Scripts/build-app.sh -c release
   open .build/DroidBridge.app
   ```

アプリは `.build/DroidBridge.app` に作成され、その Mac にインストールされた Homebrew ライブラリを使用します。

## 接続とコピー

1. Android のロックを解除し、データ転送対応の USB ケーブルで接続して、USB 設定で **ファイル転送** を選びます。確認画面が表示された場合はアクセスを許可し、同じ MTP デバイスを使うほかのアプリを終了します。USB デバッグは不要です。
2. 左側は Mac です。フォルダ選択ボタン（⌘O）でローカルの転送元または転送先を指定します。右側は Android です。ダブルクリックでフォルダを開き、上向き矢印で上の階層へ移動し、列の見出しをクリックして並べ替えます。⌘R で一覧を更新します。
3. ファイルやフォルダを選択します。**←** で Android から Mac に、**→** で Mac から Android にコピーします。選択した項目を宛先のペインにドラッグすることもできます。
4. **転送キュー**の上部に転送中の項目と進行状況が表示されます。キューを開くと待機中・完了済みの転送を確認できます。Mac に同名のファイルがある場合は、スキップするか別名のコピーを残します。
5. Android ペインのプレビューを有効にすると、表示範囲内の写真と動画のサムネイルが表示されます。

## 言語

歯車アイコンまたは ⌘, で**設定**を開きます。8 つの言語から選ぶか、システムの言語を使います。変更はすぐに反映され、対応する言語が見つからない場合は英語が使われます。

![言語の選択とバージョン番号を表示する DroidBridge の設定](docs/screenshots/droidbridge-settings.png)

## トラブルシューティング

- **端末が表示されない場合.** 端末のロックを解除してファイル転送（MTP）を選び、データ転送対応ケーブルを Mac に直接つなぎます。他の MTP アプリを閉じ、端末を接続し直して ⌘R を押します。
- **ストレージを開けない場合.** 該当する Samsung の端末では、写真転送（PTP）に切り替えてからファイル転送（MTP）に戻し、確認が表示されたらアクセスを許可します。
- **転送が止まった場合.** ケーブル、転送先の空き容量、およびキューに保留中の同名ファイルの確認がないかを調べます。必要に応じて再接続して更新します。端末へのコピーが失敗した場合は、再試行前に転送先に途中までのファイルが残っていないか確認します。

[不具合を報告](https://github.com/chepikaudzmitry/DroidBridge/issues/new?template=bug-report.yml) · [脆弱性を報告](SECURITY.md) · [変更履歴](CHANGELOG.md)

## テストと USB 診断

```sh
swift build
swift test
.build/debug/droidbridge-usb --help
```

## ライセンス

DroidBridge のソースコードは [MIT ライセンス](LICENSE)で公開されています。依存ライブラリの [libmtp](https://formulae.brew.sh/formula/libmtp) には別途 LGPL-2.1-or-later が適用されます。
