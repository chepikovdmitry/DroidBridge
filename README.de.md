# DroidBridge

[English](README.md) · [Русский](README.ru.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português (Brasil)](README.pt-BR.md) · [日本語](README.ja.md) · [简体中文](README.zh-Hans.md)

DroidBridge ist eine native macOS-App zum Übertragen von Dateien und Ordnern zwischen einem Mac und einem Android-Gerät über USB (MTP). Die App bietet eine Dateiansicht mit zwei Bereichen, optionale Fotovorschauen und eine Transferwarteschlange.

## Bauen und starten

Du benötigst macOS 26, Xcode mit dem macOS-26-SDK und Homebrew. Der lokale Build verwendet die auf deinem Mac installierten Homebrew-Bibliotheken. Das Projekt wurde auf Apple Silicon getestet.

```sh
brew install libmtp pkgconf
./Scripts/build-app.sh -c release
open .build/DroidBridge.app
```

## Verbinden und kopieren

Entsperre das Android-Gerät, verbinde es mit einem USB-Datenkabel und wähle in den USB-Einstellungen **Dateiübertragung**. Erlaube den Zugriff, wenn du danach gefragt wirst. Schließe andere Apps, die dasselbe MTP-Gerät verwenden. USB-Debugging ist nicht erforderlich.

Öffne Ordner per Doppelklick. Mit ⌘O wählst du einen Mac-Ordner, mit ⌘R aktualisierst du die Listen. Übertrage die ausgewählten Elemente mit den Pfeilen zwischen den Bereichen oder per Drag-and-drop. Bei Namenskonflikten kannst du das Element überspringen oder eine umbenannte Kopie behalten.

## Sprache

Öffne **DroidBridge → Einstellungen** (⌘,), um eine Sprache auszuwählen oder die Systemsprache zu verwenden. Als Ausweichsprache dient Englisch.

## Tests und USB-Diagnose

```sh
swift build
swift test
.build/debug/droidbridge-usb --help
```
