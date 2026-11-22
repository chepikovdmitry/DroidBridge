# DroidBridge

[English](README.md) · [Русский](README.ru.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português (Brasil)](README.pt-BR.md) · [日本語](README.ja.md) · [简体中文](README.zh-Hans.md)

DroidBridge es una aplicación nativa de macOS para transferir archivos y carpetas entre un Mac y un dispositivo Android por USB (MTP). Incluye un explorador de dos paneles, miniaturas de fotos opcionales y una cola de transferencias.

## Compilación y ejecución

Necesitas macOS 26, Xcode con el SDK de macOS 26 y Homebrew. La compilación local usa las bibliotecas de Homebrew instaladas en tu Mac. El proyecto se ha probado en Apple Silicon.

```sh
brew install libmtp pkgconf
./Scripts/build-app.sh -c release
open .build/DroidBridge.app
```

## Conexión y copia

Desbloquea el dispositivo Android, conéctalo con un cable USB de datos y selecciona **Transferencia de archivos** en las opciones USB. Autoriza el acceso si se solicita. Cierra las demás aplicaciones que usen el mismo dispositivo MTP. No hace falta activar la depuración USB.

Haz doble clic para abrir una carpeta. Usa ⌘O para elegir una carpeta del Mac y ⌘R para actualizar. Transfiere la selección con las flechas entre los paneles o arrastrándola. Si un nombre ya está en uso, puedes omitir el elemento o conservar una copia con otro nombre.

## Idioma

Abre **DroidBridge → Ajustes** (⌘,) para elegir un idioma o usar el del sistema. El idioma de respaldo es el inglés.

## Pruebas y diagnóstico USB

```sh
swift build
swift test
.build/debug/droidbridge-usb --help
```
