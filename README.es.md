# DroidBridge

[English](README.md) · [Русский](README.ru.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português (Brasil)](README.pt-BR.md) · [日本語](README.ja.md) · [简体中文](README.zh-Hans.md)

DroidBridge es una aplicación nativa de macOS para transferir archivos y carpetas entre un Mac y un dispositivo Android por USB (MTP). Incluye un explorador de dos paneles, miniaturas de fotos opcionales y una cola de transferencias.

![Explorador de DroidBridge con los paneles de Mac y Android y el progreso de la transferencia](docs/screenshots/droidbridge-browser.png)

## Descargar

Recomendamos compilar DroidBridge desde el código fuente siguiendo las instrucciones de abajo.

La [imagen de disco](https://github.com/chepikovdmitry/DroidBridge/releases/tag/v0.2.0) es para Apple Silicon y macOS 26 o posterior. Ábrela y arrastra DroidBridge a Aplicaciones. La compilación tiene una firma ad hoc y carece de notarización de Apple. macOS puede bloquear el primer arranque. Si confías en la descarga, consulta las [instrucciones de Apple](https://support.apple.com/en-us/102445).

La versión incluye sumas de comprobación y el código fuente de las bibliotecas incluidas. Consulta los [detalles de distribución y licencias](docs/distribution.md).

## Compilación y ejecución

Necesitas macOS 26 o posterior. La compilación se ha probado en Apple Silicon.

1. Instala la aplicación completa de Xcode desde la [Mac App Store](https://apps.apple.com/app/xcode/id497799835) o [Apple Developer Downloads](https://developer.apple.com/download/all/). Usa Xcode 26 o posterior con el SDK de macOS 26 o posterior. Abre Xcode una vez y completa la configuración inicial.

2. Comprueba en Terminal qué Xcode y qué SDK están activos. Si se usan las herramientas de línea de comandos independientes o un Xcode antiguo, selecciona primero la aplicación completa. Adapta la ruta si la instalaste en otra ubicación.

   ```sh
   # Only if you need to select Xcode
   sudo xcode-select --switch /Applications/Xcode.app
   xcodebuild -version
   xcrun --sdk macosx --show-sdk-version
   ```

3. Si todavía no tienes Homebrew, ejecuta el instalador de [brew.sh](https://brew.sh/). Sigue los pasos de **Next steps** para añadir Homebrew a tu shell y comprueba que funciona `brew --version`.

   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

4. Clona el repositorio y compila la aplicación. Si descargaste un ZIP, extráelo, abre su carpeta en Terminal y empieza por `brew install`.

   ```sh
   git clone https://github.com/chepikovdmitry/DroidBridge.git
   cd DroidBridge
   brew install libmtp pkgconf
   ./Scripts/build-app.sh -c release
   open .build/DroidBridge.app
   ```

La aplicación se guarda en `.build/DroidBridge.app` y usa las bibliotecas de Homebrew instaladas en ese Mac.

## Conexión y copia

1. Desbloquea el dispositivo Android, conéctalo con un cable USB de datos y selecciona **Transferencia de archivos** en las opciones USB. Autoriza el acceso si se solicita y cierra otras aplicaciones que usen el dispositivo MTP. No hace falta activar la depuración USB.
2. A la izquierda están los archivos del Mac. Pulsa **Elegir carpeta** (⌘O) para definir el origen o destino local. A la derecha está Android. Haz doble clic para abrir una carpeta, usa la flecha hacia arriba para subir un nivel y pulsa un encabezado de columna para ordenar. Actualiza las listas con ⌘R.
3. Selecciona archivos o carpetas. Pulsa **←** para copiar de Android al Mac o **→** para hacerlo en sentido contrario. También puedes arrastrar la selección al panel de destino.
4. La **Cola de transferencias** mantiene el archivo actual y su progreso arriba. Despliega la cola para revisar las transferencias pendientes y terminadas. Si un archivo ya existe en el Mac, elige omitirlo o conservar una copia con otro nombre.
5. Activa **Vistas previas** en el panel de Android para ver miniaturas de fotos y videos visibles.

## Idioma

Pulsa el engranaje o ⌘, para abrir **Ajustes**. Puedes elegir entre ocho idiomas o usar el idioma del sistema. El cambio es inmediato. El idioma de respaldo es el inglés.

![Ajustes de DroidBridge con el selector de idioma y la versión](docs/screenshots/droidbridge-settings.png)

## Pruebas y diagnóstico USB

```sh
swift build
swift test
.build/debug/droidbridge-usb --help
```

## Licencia

El código de DroidBridge se publica bajo la [licencia MIT](LICENSE). La [dependencia libmtp](https://formulae.brew.sh/formula/libmtp) se licencia por separado bajo LGPL-2.1-or-later.
