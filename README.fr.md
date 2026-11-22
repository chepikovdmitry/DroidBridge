# DroidBridge

[English](README.md) · [Русский](README.ru.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português (Brasil)](README.pt-BR.md) · [日本語](README.ja.md) · [简体中文](README.zh-Hans.md)

DroidBridge est une application native pour macOS qui transfère des fichiers et des dossiers entre un Mac et un appareil Android par USB (MTP). Elle propose un navigateur à deux volets, des miniatures de photos facultatives et une file de transferts.

![Navigateur DroidBridge avec les volets Mac et Android et la progression du transfert](docs/screenshots/droidbridge-browser.png)

## Compilation et lancement

Il faut macOS 26 ou une version ultérieure. La compilation a été testée sur Apple Silicon.

1. Installez l’application Xcode complète depuis le [Mac App Store](https://apps.apple.com/app/xcode/id497799835) ou [Apple Developer Downloads](https://developer.apple.com/download/all/). Choisissez Xcode 26 ou une version ultérieure, avec un SDK macOS 26 ou plus récent. Ouvrez Xcode une fois et terminez sa configuration initiale.

2. Vérifiez la version de Xcode et le SDK actifs dans Terminal. Si Terminal utilise uniquement les outils en ligne de commande ou un ancien Xcode, sélectionnez d’abord l’application complète. Adaptez le chemin si nécessaire.

   ```sh
   # Only if you need to select Xcode
   sudo xcode-select --switch /Applications/Xcode.app
   xcodebuild -version
   xcrun --sdk macosx --show-sdk-version
   ```

3. Si Homebrew est absent, lancez l’installateur depuis [brew.sh](https://brew.sh/). Suivez les instructions **Next steps** pour ajouter Homebrew au shell, puis vérifiez avec `brew --version`.

   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

4. Clonez le dépôt et compilez l’application. Si vous avez téléchargé un ZIP, décompressez-le, ouvrez son dossier dans Terminal et commencez par `brew install`.

   ```sh
   git clone https://github.com/chepikovdmitry/DroidBridge.git
   cd DroidBridge
   brew install libmtp pkgconf
   ./Scripts/build-app.sh -c release
   open .build/DroidBridge.app
   ```

L’application est créée dans `.build/DroidBridge.app` et utilise les bibliothèques Homebrew installées sur ce Mac.

## Connexion et copie

1. Déverrouillez Android, branchez-le avec un câble USB de données et choisissez **Transfert de fichiers** dans les options USB. Autorisez l’accès si nécessaire. Fermez les autres applications qui utilisent le même appareil MTP. Le débogage USB est inutile.
2. Le volet gauche affiche les fichiers du Mac. Cliquez sur **Choisir un dossier** (⌘O) pour définir la source ou la destination locale. Le volet droit affiche Android. Double-cliquez pour ouvrir un dossier, utilisez la flèche vers le haut pour remonter et cliquez sur un en-tête de colonne pour trier. Actualisez les listes avec ⌘R.
3. Sélectionnez des fichiers ou dossiers. Cliquez sur **←** pour copier depuis Android vers le Mac ou sur **→** pour l’inverse. Vous pouvez aussi faire glisser la sélection vers le volet de destination.
4. La **File de transfert** garde l’élément en cours et sa progression en haut. Dépliez-la pour retrouver les transferts en attente et terminés. Si un fichier existe déjà sur le Mac, ignorez-le ou conservez une copie renommée.
5. Activez les aperçus dans le volet Android pour afficher les miniatures des photos et vidéos visibles.

## Langue

Cliquez sur l’engrenage ou appuyez sur ⌘, pour ouvrir les **Réglages**. Choisissez une des huit langues ou la langue du système. Le changement est immédiat. La langue de secours est l’anglais.

![Réglages de DroidBridge avec le choix de la langue et le numéro de version](docs/screenshots/droidbridge-settings.png)

## Tests et diagnostic USB

```sh
swift build
swift test
.build/debug/droidbridge-usb --help
```
