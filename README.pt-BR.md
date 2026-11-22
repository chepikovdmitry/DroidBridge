# DroidBridge

[English](README.md) · [Русский](README.ru.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português (Brasil)](README.pt-BR.md) · [日本語](README.ja.md) · [简体中文](README.zh-Hans.md)

DroidBridge é um aplicativo nativo para macOS que transfere arquivos e pastas entre um Mac e um dispositivo Android por USB (MTP). Ele oferece um navegador com dois painéis, miniaturas opcionais de fotos e uma fila de transferências.

## Compilar e executar

Você precisa do macOS 26, do Xcode com o SDK do macOS 26 e do Homebrew. A compilação local usa as bibliotecas do Homebrew instaladas no seu Mac. O projeto foi testado no Apple Silicon.

```sh
brew install libmtp pkgconf
./Scripts/build-app.sh -c release
open .build/DroidBridge.app
```

## Conectar e copiar

Desbloqueie o dispositivo Android, conecte-o com um cabo USB de dados e selecione **Transferência de arquivos** nas opções de USB. Permita o acesso se solicitado. Feche outros aplicativos que estejam usando o mesmo dispositivo MTP. A depuração USB não é necessária.

Clique duas vezes para abrir uma pasta. Use ⌘O para escolher uma pasta no Mac e ⌘R para atualizar as listas. Transfira os itens selecionados usando as setas entre os painéis ou arrastando-os. Se um nome já estiver em uso, você pode ignorar o item ou manter uma cópia renomeada.

## Idioma

Abra **DroidBridge → Ajustes** (⌘,) para escolher um idioma ou usar o idioma do sistema. O idioma de reserva é o inglês.

## Testes e diagnóstico USB

```sh
swift build
swift test
.build/debug/droidbridge-usb --help
```
