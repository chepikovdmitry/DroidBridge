# DroidBridge

[English](README.md) · [Русский](README.ru.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português (Brasil)](README.pt-BR.md) · [日本語](README.ja.md) · [简体中文](README.zh-Hans.md)

DroidBridge ist eine native macOS-App zum Übertragen von Dateien und Ordnern zwischen einem Mac und einem Android-Gerät über USB (MTP). Die App bietet eine Dateiansicht mit zwei Bereichen, optionale Fotovorschauen und eine Transferwarteschlange.

![DroidBridge-Dateiansicht mit Mac- und Android-Bereichen sowie Transferfortschritt](docs/screenshots/droidbridge-browser.png)

## Herunterladen

Wir empfehlen, DroidBridge nach der folgenden Anleitung aus dem Quellcode zu bauen.

Das [Festplattenimage](https://github.com/chepikovdmitry/DroidBridge/releases/tag/v0.2.0) ist für Apple Silicon und macOS 26 oder neuer gedacht. Öffne es und ziehe DroidBridge in den Ordner Programme. Der Build ist ad hoc signiert und von Apple nicht notarisiert. macOS kann den ersten Start blockieren. Wenn du dem Download vertraust, folge der [Anleitung von Apple](https://support.apple.com/en-us/102445).

Der Release enthält auch Prüfsummen und den Quellcode der enthaltenen Bibliotheken. Siehe [Vertrieb und Lizenzen](docs/distribution.md).

## Bauen und starten

Du benötigst macOS 26 oder neuer. Der Build wurde auf Apple Silicon getestet.

1. Installiere die vollständige Xcode-App aus dem [Mac App Store](https://apps.apple.com/app/xcode/id497799835) oder über [Apple Developer Downloads](https://developer.apple.com/download/all/). Verwende Xcode 26 oder neuer mit dem macOS-26-SDK oder neuer. Öffne Xcode einmal und schließe die Ersteinrichtung ab.

2. Prüfe im Terminal das aktive Xcode und den SDK-Stand. Falls das Terminal nur die separaten Command Line Tools oder ein älteres Xcode verwendet, wähle zuerst die vollständige App aus. Passe bei Bedarf den Pfad an.

   ```sh
   # Only if you need to select Xcode
   sudo xcode-select --switch /Applications/Xcode.app
   xcodebuild -version
   xcrun --sdk macosx --show-sdk-version
   ```

3. Falls Homebrew fehlt, verwende den Installer von [brew.sh](https://brew.sh/). Folge den Hinweisen unter **Next steps**, um Homebrew in der Shell verfügbar zu machen, und prüfe es mit `brew --version`.

   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

4. Klone das Repository und baue die App. Wenn du eine ZIP-Datei heruntergeladen hast, entpacke sie, öffne den Projektordner im Terminal und beginne mit `brew install`.

   ```sh
   git clone https://github.com/chepikovdmitry/DroidBridge.git
   cd DroidBridge
   brew install libmtp pkgconf
   ./Scripts/build-app.sh -c release
   open .build/DroidBridge.app
   ```

Die App erscheint unter `.build/DroidBridge.app` und verwendet die auf diesem Mac installierten Homebrew-Bibliotheken.

## Verbinden und kopieren

1. Entsperre Android, verbinde das Gerät über ein USB-Datenkabel und wähle **Dateiübertragung**. Erlaube den Zugriff, wenn du danach gefragt wirst. Schließe andere Apps, die dasselbe MTP-Gerät verwenden. USB-Debugging ist nicht erforderlich.
2. Links siehst du den Mac. Mit **Ordner wählen** (⌘O) legst du die lokale Quelle oder das Ziel fest. Rechts siehst du Android. Öffne Ordner per Doppelklick, gehe per Pfeil nach oben und sortiere durch Klick auf einen Spaltenkopf. Mit ⌘R aktualisierst du die Listen.
3. Markiere Dateien oder Ordner. Klicke auf **←** für Android zum Mac oder auf **→** für Mac zu Android. Du kannst die Auswahl auch in den Zielbereich ziehen.
4. Die **Übertragungswarteschlange** zeigt den laufenden Transfer mit Fortschritt oben an. Klappe sie auf, um anstehende und abgeschlossene Transfers zu sehen. Falls eine Datei auf dem Mac bereits vorhanden ist, überspringe sie oder behalte eine umbenannte Kopie.
5. Aktiviere die Vorschau im Android-Bereich für Miniaturansichten sichtbarer Fotos und Videos.

## Sprache

Klicke auf das Zahnrad oder drücke ⌘, für die **Einstellungen**. Wähle eine der acht Sprachen oder die Systemsprache. Die Änderung gilt sofort. Als Ausweichsprache dient Englisch.

![DroidBridge-Einstellungen mit Sprachauswahl und Versionsnummer](docs/screenshots/droidbridge-settings.png)

## Tests und USB-Diagnose

```sh
swift build
swift test
.build/debug/droidbridge-usb --help
```

## Lizenz

Der Quellcode von DroidBridge steht unter der [MIT-Lizenz](LICENSE). Für die [Abhängigkeit libmtp](https://formulae.brew.sh/formula/libmtp) gilt separat LGPL-2.1-or-later.
