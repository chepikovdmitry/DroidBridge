# DroidBridge

[English](README.md) · [Русский](README.ru.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português (Brasil)](README.pt-BR.md) · [日本語](README.ja.md) · [简体中文](README.zh-Hans.md)

DroidBridge é um aplicativo nativo para macOS que transfere arquivos e pastas entre um Mac e um dispositivo Android por USB (MTP). Ele oferece um navegador com dois painéis, miniaturas opcionais de fotos e uma fila de transferências.

![Navegador do DroidBridge com painéis do Mac e do Android e progresso da transferência](docs/screenshots/droidbridge-browser.png)

## Download

Recomendamos compilar o DroidBridge a partir do código-fonte seguindo as instruções abaixo.

A [imagem de disco](https://github.com/chepikovdmitry/DroidBridge/releases/tag/v0.2.0) é para Apple Silicon e macOS 26 ou posterior. Abra a imagem e arraste o DroidBridge para Aplicativos. A compilação tem assinatura ad hoc e não tem notarização da Apple. O macOS pode bloquear a primeira abertura. Se você confia no download, siga as [instruções da Apple](https://support.apple.com/en-us/102445).

A versão também inclui somas de verificação e o código-fonte das bibliotecas incluídas. Veja os [detalhes de distribuição e licenças](docs/distribution.md).

## Compilar e executar

Você precisa do macOS 26 ou posterior. A compilação foi testada no Apple Silicon.

1. Instale o aplicativo completo do Xcode pela [Mac App Store](https://apps.apple.com/app/xcode/id497799835) ou pelo [Apple Developer Downloads](https://developer.apple.com/download/all/). Use o Xcode 26 ou posterior com SDK do macOS 26 ou mais recente. Abra o Xcode uma vez e conclua a configuração inicial.

2. Confira no Terminal quais Xcode e SDK estão ativos. Se o Terminal estiver usando as ferramentas de linha de comando avulsas ou um Xcode antigo, selecione primeiro o aplicativo completo. Ajuste o caminho se necessário.

   ```sh
   # Only if you need to select Xcode
   sudo xcode-select --switch /Applications/Xcode.app
   xcodebuild -version
   xcrun --sdk macosx --show-sdk-version
   ```

3. Se o Homebrew ainda não estiver instalado, execute o instalador de [brew.sh](https://brew.sh/). Siga as instruções em **Next steps** para adicionar o Homebrew ao shell e verifique com `brew --version`.

   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

4. Clone o repositório e compile o aplicativo. Se baixou um ZIP, extraia-o, abra a pasta do projeto no Terminal e comece com `brew install`.

   ```sh
   git clone https://github.com/chepikovdmitry/DroidBridge.git
   cd DroidBridge
   brew install libmtp pkgconf
   ./Scripts/build-app.sh -c release
   open .build/DroidBridge.app
   ```

O aplicativo será criado em `.build/DroidBridge.app` e usará as bibliotecas do Homebrew instaladas nesse Mac.

## Conectar e copiar

1. Desbloqueie o Android, conecte-o com um cabo USB de dados e selecione **Transferência de arquivos** nas opções de USB. Permita o acesso se solicitado. Feche outros aplicativos que usem o mesmo dispositivo MTP. A depuração USB não é necessária.
2. O painel esquerdo mostra o Mac. Clique em **Escolher pasta** (⌘O) para definir a origem ou o destino local. O painel direito mostra o Android. Clique duas vezes para abrir uma pasta, use a seta para cima para subir um nível e clique no cabeçalho de uma coluna para ordenar. Use ⌘R para atualizar as listas.
3. Selecione arquivos ou pastas. Clique em **←** para copiar do Android para o Mac ou em **→** para copiar na direção oposta. Você também pode arrastar a seleção para o painel de destino.
4. A **Fila de transferências** mantém a transferência atual e o progresso no topo. Abra a fila para ver as transferências pendentes e concluídas. Se o arquivo já existir no Mac, ignore-o ou mantenha uma cópia com outro nome.
5. Ative as prévias no painel do Android para ver miniaturas de fotos e vídeos visíveis.

## Idioma

Clique na engrenagem ou pressione ⌘, para abrir os **Ajustes**. Escolha um dos oito idiomas ou o idioma do sistema. A alteração é imediata. O inglês é o idioma de reserva.

![Ajustes do DroidBridge com seletor de idioma e número da versão](docs/screenshots/droidbridge-settings.png)

## Solução de problemas

- **O telefone não aparece.** Desbloqueie o telefone, selecione Transferência de arquivos (MTP) e ligue o cabo de dados diretamente ao Mac. Feche outros apps MTP, reconecte o telefone e pressione ⌘R.
- **O armazenamento está indisponível.** Nos aparelhos Samsung afetados, mude para Transferência de fotos (PTP), depois volte para Transferência de arquivos (MTP). Permita o acesso se solicitado.
- **A transferência travou ou foi interrompida.** Confira o cabo, o espaço livre no destino e os conflitos de nomes na fila. Reconecte e atualize se necessário. Se a cópia para o telefone falhou, procure um arquivo parcial na pasta de destino antes de tentar novamente.

[Relatar um erro](https://github.com/chepikovdmitry/DroidBridge/issues/new?template=bug-report.yml) · [Relatar uma vulnerabilidade](SECURITY.md) · [Histórico de alterações](CHANGELOG.md)

## Testes e diagnóstico USB

```sh
swift build
swift test
.build/debug/droidbridge-usb --help
```

## Licença

O código do DroidBridge é distribuído sob a [licença MIT](LICENSE). A [dependência libmtp](https://formulae.brew.sh/formula/libmtp) tem licença própria, LGPL-2.1-or-later.
