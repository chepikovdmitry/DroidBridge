# DroidBridge

[English](README.md) · [Русский](README.ru.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português (Brasil)](README.pt-BR.md) · [日本語](README.ja.md) · [简体中文](README.zh-Hans.md)

DroidBridge est une application native pour macOS qui transfère des fichiers et des dossiers entre un Mac et un appareil Android par USB (MTP). Elle propose un navigateur à deux volets, des miniatures de photos facultatives et une file de transferts.

## Compilation et lancement

Il faut macOS 26, Xcode avec le SDK macOS 26 et Homebrew. La compilation locale utilise les bibliothèques Homebrew installées sur votre Mac. Le projet a été testé sur Apple Silicon.

```sh
brew install libmtp pkgconf
./Scripts/build-app.sh -c release
open .build/DroidBridge.app
```

## Connexion et copie

Déverrouillez l’appareil Android, branchez-le avec un câble USB de données et sélectionnez **Transfert de fichiers** dans ses paramètres USB. Autorisez l’accès si nécessaire. Fermez les autres applications qui utilisent le même appareil MTP. Le débogage USB est facultatif.

Double-cliquez pour ouvrir un dossier. Utilisez ⌘O pour choisir un dossier sur le Mac et ⌘R pour actualiser les listes. Transférez la sélection avec les flèches entre les volets ou par glisser-déposer. Si un nom est déjà utilisé, vous pouvez ignorer l’élément ou conserver une copie renommée.

## Langue

Ouvrez **DroidBridge → Réglages** (⌘,) pour choisir une langue ou utiliser celle du système. La langue de secours est l’anglais.

## Tests et diagnostic USB

```sh
swift build
swift test
.build/debug/droidbridge-usb --help
```
