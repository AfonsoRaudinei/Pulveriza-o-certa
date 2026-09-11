# AGENTIPA — Ponta Verde

Registro operacional de builds iOS. Um IPA só deve ser marcado como entregue
quando existir arquivo `.ipa` físico e o `CFBundleVersion` interno for validado.

## Build 2 — 2026-08-12 22:00:33 -03

- Versão solicitada: `1.0.0+2`
- Bundle ID: `com.pontaverde.app`
- Team ID configurado: `BA2BU25B78`
- Comando usado:
  `flutter build ipa --release --build-name 1.0.0 --build-number 2 --export-options-plist=ios/ExportOptions.plist`
- Resultado do archive: `build/ios/archive/Runner.xcarchive`
- Tamanho do archive: `171M`
- `CFBundleShortVersionString` no archive: `1.0.0`
- `CFBundleVersion` no archive: `2`
- Testes antes do build: `flutter test --reporter compact` passou
- Analyzer antes do build: `flutter analyze` sem issues
- Resultado do IPA: não entregue
- Bloqueio:
  - `error: exportArchive No Accounts`
  - `error: exportArchive No profiles for 'com.pontaverde.app' were found`
- Observação do Flutter: launch image ainda usa placeholder padrão.

### Status

Archive build `2` validado. IPA físico build `2` não foi gerado porque o
ambiente local não possui conta/profile de assinatura para export App Store.

## Build 3 — 2026-09-10 20:43 -03

- Versão solicitada: `1.0.0+3`
- Bundle ID: `com.pontaverde.app`
- Team ID configurado: `BA2BU25B78`
- Comando usado:
  `flutter build ipa --release --build-name 1.0.0 --build-number 3 --export-options-plist=ios/ExportOptions.plist`
- Preparação: `flutter clean` + `flutter pub get` + `pod install`
- Testes antes do build: `flutter test --reporter compact` — `All tests passed!` (36 testes)
- Analyzer antes do build: `flutter analyze` — `No issues found!`
- Assinatura: automática, cert `Apple Distribution: RAUDINEI AFONSO SILVA PEREIRA (BA2BU25B78)` presente no keychain
- Resultado do archive: `build/ios/archive/Runner.xcarchive` (178.5 MB)
- Resultado do IPA: **entregue** — `build/ios/ipa/pontaverde.ipa` (23.6 MB / 23393888 bytes)
- Validação do IPA (`Payload/Runner.app/Info.plist`):
  - `CFBundleShortVersionString`: `1.0.0`
  - `CFBundleVersion`: `3`
  - `CFBundleIdentifier`: `com.pontaverde.app`
  - `MinimumOSVersion`: `13.0`
- Observação do Flutter: launch image ainda usa placeholder padrão (não bloqueia o
  export; bloqueia revisão da App Store).

### Status

IPA físico build `3` gerado e validado. Rejeitado no upload: erro `90068`
(`MinimumOSVersion` 13.0 < 15.0 exigido a partir da primavera de 2027).

## Build 4 — 2026-09-10 20:58 -03

- Versão solicitada: `1.0.0+4`
- Motivo: correção do erro `90068` do Build 3 — deployment target elevado de
  `13.0` para `15.0` em `ios/Runner.xcodeproj/project.pbxproj` (3 configs) e
  `platform :ios, '15.0'` habilitado em `ios/Podfile`.
- Comando usado:
  `flutter build ipa --release --build-name 1.0.0 --build-number 4 --export-options-plist=ios/ExportOptions.plist`
- Preparação: `rm -rf ios/Pods ios/Podfile.lock` + `flutter clean` + `flutter pub get` + `pod install`
- Resultado do archive: `build/ios/archive/Runner.xcarchive` (178.5 MB)
- Resultado do IPA: **entregue** — `build/ios/ipa/pontaverde.ipa` (23.5 MB / 23386439 bytes)
- Validação do IPA (`Payload/Runner.app/Info.plist`):
  - `CFBundleShortVersionString`: `1.0.0`
  - `CFBundleVersion`: `4`
  - `MinimumOSVersion`: `15.0`
- Deployment Target confirmado pelo Flutter: `15.0`
- Observação do Flutter: launch image ainda usa placeholder padrão.

### Status

IPA físico build `4` gerado e validado com `MinimumOSVersion` 15.0. Enviado ao
App Store Connect, mas o **processamento falhou** com o erro `90683: Missing
purpose string in Info.plist` (`NSPhotoLibraryUsageDescription`). Builds 3 e 4
ficaram com status "Falha" no TestFlight e nunca ficaram disponíveis para teste.

## Build 5 — 2026-09-10 21:30 -03

- Versão solicitada: `1.0.0+5`
- Motivo: correção do erro `90683` dos builds 3 e 4. O plugin `file_picker`
  arrastava o pod `DKImagePickerController` (APIs de Fototeca/Câmera), forçando
  purpose strings. O app só seleciona documentos (`FileType.custom`, backup JSON
  em `lib/services/storage_service.dart`), então os seletores de mídia e áudio
  foram desativados.
- Alteração: `ios/Podfile` — adicionado no topo
  `::PICKER_MEDIA = false` / `::PICKER_AUDIO = false` (o `::` é necessário porque
  o Podfile é `instance_eval`-ado; sem ele o `Pod.const_defined?(:PICKER_MEDIA)`
  do podspec não enxerga a constante e o `DKImagePickerController` volta a ser
  instalado).
- Preparação: `rm -rf ios/Pods ios/Podfile.lock "ios/Pods/Local Podspecs"` +
  `flutter clean` + `flutter pub get` + `pod install`
- Pods resultantes: apenas `Flutter`, `file_picker`, `share_plus`,
  `shared_preferences_foundation` (antes eram 8, com DKImagePickerController,
  DKPhotoGallery, SDWebImage, SwiftyGif).
- Comando usado:
  `flutter build ipa --release --build-name 1.0.0 --build-number 5 --export-options-plist=ios/ExportOptions.plist`
- Resultado do archive: `build/ios/archive/Runner.xcarchive` (163.3 MB, era 178.5 MB)
- Resultado do IPA: **entregue** — `build/ios/ipa/pontaverde.ipa` (21.9 MB)
- Validação do IPA (`Payload/Runner.app`):
  - `CFBundleShortVersionString`: `1.0.0`
  - `CFBundleVersion`: `5`
  - `MinimumOSVersion`: `15.0`
  - Nenhuma chave `*UsageDescription` no `Info.plist`
  - Frameworks: sem `DKImagePickerController`, sem `SDWebImage`, sem `SwiftyGif`
- Observação do Flutter: launch image ainda usa placeholder padrão.

### Status

IPA físico build `5` gerado e validado, sem referência a APIs de Fototeca.
**Não enviado** — substituído pelo Build 6 (número de build novo, para evitar
colisão com os builds 3 e 4 já registrados no App Store Connect).

## Build 6 — 2026-09-10 21:32 -03

- Versão solicitada: `1.0.0+6` (também refletida em `pubspec.yaml`)
- Motivo: build definitivo com todas as correções acumuladas dos builds 3–5.
  Número 6 escolhido porque os builds 3 e 4 já constam no App Store Connect com
  status "Falha" e o serviço rejeita reenvio do mesmo `CFBundleVersion`.
- Correções incluídas:
  - `MinimumOSVersion` 15.0 (erro `90068`) — `IPHONEOS_DEPLOYMENT_TARGET = 15.0`
    nas 3 configs de `ios/Runner.xcodeproj/project.pbxproj` + `platform :ios,
    '15.0'` em `ios/Podfile`.
  - Sem purpose strings de Fototeca (erro `90683`) — `::PICKER_MEDIA = false` /
    `::PICKER_AUDIO = false` em `ios/Podfile`.
- Validação de pré-build:
  - `flutter analyze` — `No issues found!`
  - `flutter test --reporter compact` — `All tests passed!` (36 testes)
- Preparação: `flutter clean` + `flutter pub get` + `rm -rf ios/Pods
  ios/Podfile.lock` + `pod install`
- Pods instalados: `Flutter`, `file_picker`, `share_plus`,
  `shared_preferences_foundation` (4 no total). `Podfile.lock` sem
  `DKImagePickerController` / `DKPhotoGallery` / `SDWebImage` / `SwiftyGif`.
  `file_picker` GCC defs: apenas `PICKER_DOCUMENT=1`.
- Comando usado:
  `flutter build ipa --release --build-name 1.0.0 --build-number 6 --export-options-plist=ios/ExportOptions.plist`
- Resultado do archive: `build/ios/archive/Runner.xcarchive` (163.3 MB)
- Resultado do IPA: **entregue** — `build/ios/ipa/pontaverde.ipa`
  (21.7 MB / 21757782 bytes)
- Validação do IPA (`Payload/Runner.app`):
  - `CFBundleShortVersionString`: `1.0.0`
  - `CFBundleVersion`: `6`
  - `CFBundleIdentifier`: `com.pontaverde.app`
  - `CFBundleDisplayName`: `Ponta Verde`
  - `MinimumOSVersion`: `15.0`
  - Nenhuma chave `*UsageDescription` no `Info.plist`
  - Frameworks: `App`, `Flutter`, `file_picker`, `objective_c`, `share_plus`,
    `shared_preferences_foundation` — sem `DKImagePickerController`
  - `embedded.mobileprovision`: `iOS Team Store Provisioning Profile:
    com.pontaverde.app`, `get-task-allow = false`, expira 2027-08-04
  - Assinatura: `Apple Distribution: RAUDINEI AFONSO SILVA PEREIRA (BA2BU25B78)`,
    `TeamIdentifier BA2BU25B78`
  - Método de export: `app-store-connect`
- Observação do Flutter: launch image ainda usa placeholder padrão (não bloqueia
  upload nem processamento; a revisão da App Store vai exigir a troca).

### Status

IPA físico build `6` gerado e validado integralmente. `CFBundleVersion 6` inédito
no App Store Connect, `MinimumOSVersion 15.0`, sem APIs de Fototeca e assinado com
perfil de distribuição App Store. **Não enviado** — substituído pelo Build 7, que
também resolve a pendência da launch image.

## Build 7 — 2026-09-10 21:36 -03

- Versão solicitada: `1.0.0+7`
- Motivo: mesmo conteúdo do Build 6 + correção da launch image placeholder
  (aviso do Flutter "Launch image is set to the default placeholder icon").
- Alterações:
  - `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage{,@2x,@3x}.png`
    regenerados a partir de `assets/app_icon.png` (96 / 192 / 288 px, antes eram
    placeholders 1x1).
  - `ios/Runner/Base.lproj/LaunchScreen.storyboard`: fundo alterado de branco
    puro para `#F5F7FA` (mesma cor do primeiro scaffold do app, evita flash) e
    `<image>` intrínseco ajustado para 96x96.
- Validação de pré-build:
  - `flutter analyze` — `No issues found!`
  - `flutter test --reporter compact` — `All tests passed!` (36 testes)
  - Build do Flutter **não** emitiu mais o bloco "App Icon and Launch Image
    Assets Validation" (aviso da launch image resolvido).
- Comando usado:
  `flutter build ipa --release --build-name 1.0.0 --build-number 7 --export-options-plist=ios/ExportOptions.plist`
- Resultado do archive: `build/ios/archive/Runner.xcarchive` (163.4 MB)
- Resultado do IPA: **entregue** — `build/ios/ipa/pontaverde.ipa`
  (22.0 MB / 21861529 bytes)
- Validação do IPA (`Payload/Runner.app`):
  - `CFBundleShortVersionString`: `1.0.0` · `CFBundleVersion`: `7`
  - `MinimumOSVersion`: `15.0`
  - Nenhuma chave `*UsageDescription` no `Info.plist`
  - `Assets.car` contém as renditions `LaunchImage.png` / `@2x` / `@3x`
  - `Base.lproj/LaunchScreen.storyboardc` presente
  - Frameworks sem `DKImagePickerController` / `SDWebImage` / `SwiftyGif`
  - Assinatura: `Apple Distribution: RAUDINEI AFONSO SILVA PEREIRA (BA2BU25B78)`,
    `TeamIdentifier BA2BU25B78`, perfil `iOS Team Store Provisioning Profile:
    com.pontaverde.app`

### Status

IPA físico build `7` gerado e validado. **Não enviado** — substituído pelo
Build 8, que embute a resposta de conformidade de criptografia.

## Build 8 — 2026-09-10 21:41 -03

- Versão solicitada: `1.0.0+8` (também em `pubspec.yaml`)
- Motivo: mesmo conteúdo do Build 7 + `ITSAppUsesNonExemptEncryption = false`
  adicionado ao `ios/Runner/Info.plist`. O app só usa criptografia isenta
  (HTTPS / APIs padrão do iOS; nenhuma cripto própria), então a pergunta de
  conformidade de exportação **não aparece mais** no App Store Connect / TestFlight.
- Também criado `scripts/upload_testflight.sh` (chave `M3424Q9LY2` e caminho do
  IPA já pré-preenchidos; só falta passar o Issuer ID) e entrada
  `ios/.asc_issuer_id` no `.gitignore`.
- Validação de pré-build: `flutter analyze` — `No issues found!`;
  build sem o bloco de aviso de launch image.
- Comando usado:
  `flutter build ipa --release --build-name 1.0.0 --build-number 8 --export-options-plist=ios/ExportOptions.plist`
- Resultado do archive: `build/ios/archive/Runner.xcarchive` (163.4 MB)
- Resultado do IPA: **entregue** — `build/ios/ipa/pontaverde.ipa`
  (22.0 MB / 21861565 bytes)
- Validação do IPA (`Payload/Runner.app`):
  - `CFBundleShortVersionString`: `1.0.0` · `CFBundleVersion`: `8`
  - `MinimumOSVersion`: `15.0`
  - `ITSAppUsesNonExemptEncryption`: `false`
  - Nenhuma chave `*UsageDescription`
  - `Assets.car` com renditions `LaunchImage` 1x/2x/3x + `LaunchScreen.storyboardc`
  - Frameworks sem `DKImagePickerController` / `SDWebImage` / `SwiftyGif`
  - Assinatura `Apple Distribution: RAUDINEI AFONSO SILVA PEREIRA (BA2BU25B78)`,
    perfil `iOS Team Store Provisioning Profile: com.pontaverde.app`,
    `get-task-allow = false`

### Status

IPA físico build `8` pronto. **Não enviado** — substituído pelo Build 9.

## Build 9 — 2026-09-10 21:45 -03

- Versão solicitada: `1.0.0+9` (também em `pubspec.yaml`)
- Motivo: IPA atualizado pedido pelo usuário. Conteúdo idêntico ao Build 8
  (iOS 15, sem Fototeca, launch image real, `ITSAppUsesNonExemptEncryption =
  false`); apenas `CFBundleVersion` incrementado para 9.
- Comando usado:
  `flutter build ipa --release --build-name 1.0.0 --build-number 9 --export-options-plist=ios/ExportOptions.plist`
- Resultado do IPA: **entregue** — `build/ios/ipa/pontaverde.ipa`
  (22.0 MB / 21861576 bytes)
- Validação do IPA (`Payload/Runner.app`):
  - `CFBundleShortVersionString`: `1.0.0` · `CFBundleVersion`: `9`
  - `MinimumOSVersion`: `15.0` · `ITSAppUsesNonExemptEncryption`: `false`
  - Nenhuma chave `*UsageDescription`
  - Frameworks sem `DKImagePickerController` / `SDWebImage` / `SwiftyGif`
  - Assinatura `Apple Distribution: RAUDINEI AFONSO SILVA PEREIRA (BA2BU25B78)`

### TestFlight — grupo de teste (feito via App Store Connect web)

- App: `Ponta Verde Agro` (Apple ID `6801095636`, team
  `aa2d26d4-1346-47c2-97be-9d83014aa76b`).
- Criado grupo **externo** `Teste Externo`.
- Testador adicionado: `raudyneyb@icloud.com` (Raudinei Silva Pereira).
  Status do testador: `Nenhuma compilação disponível`.
- Observado no App Store Connect: build `1.0.0 (5)` já estava enviado e
  `Concluído`, porém com aviso `Faltam dados de conformidade` (pergunta de
  criptografia) — resolvida a partir do Build 8 no `Info.plist`, mas o build 5
  ainda mostra o aviso porque foi enviado antes dessa correção.
- Builds `3` e `4` continuam com status `Falha` (erros `90068` / `90683`).

### Status

Build 9 gerado e validado. Grupo `Teste Externo` criado com o testador
`raudyneyb@icloud.com`. Para o testador receber o convite ainda falta (ação de
conta): (1) subir o build 9 — `scripts/upload_testflight.sh <ISSUER_ID>` ou
Transporter; (2) anexar o build ao grupo `Teste Externo`; (3) enviar para
Beta App Review (obrigatório para grupo externo na primeira compilação).
Alternativa mais rápida: responder a conformidade de criptografia do build 5 já
enviado e anexá-lo ao grupo.

## Auditoria de revisão Apple — 2026-09-10 22:10 -03

Revisão completa do projeto atuando como revisor Apple (ver
`/Users/raudineisilvapereira/.claude/plans/analise-todo-o-projeto-melodic-frost.md`
para o plano integral). Decisões tomadas com o usuário: app fica **só iPhone**
(`TARGETED_DEVICE_FAMILY = "1"`) e marca única **"Ponta Verde"** em todo lugar.

### Corrigido nesta sessão

- Removida a tela de login mock (`lib/screens/login/login_screen.dart`, aceitava
  qualquer credencial e exibia "Tela congelada na v1.0") e a rota `/login`.
- Removido `EntitlementService` (stub morto de monetização, sem IAP no app).
- `StorageService`: JSON de regulagens corrompido vai para quarentena
  (`agro_regulagens_corrompido_<timestamp>`) em vez de ser apagado no próximo
  salvamento; importação valida a estrutura antes de gravar; `StorageException`
  com mensagens apresentáveis.
- Feedback de erro/sucesso (SnackBar) em salvar, exportar, importar, apagar
  tudo, salvar regulagem e excluir no histórico — nenhuma operação falha mais
  em silêncio.
- Fonte Inter embutida em `assets/fonts/` (`pubspec.yaml` → `fonts:`); removida
  a dependência `google_fonts` (e `http`/`http_parser` junto). O app não tem
  mais nenhum pacote com capacidade de rede.
- `TARGETED_DEVICE_FAMILY` → `"1"` nas 3 configurações do target Runner.
- Criado e registrado `ios/Runner/PrivacyInfo.xcprivacy` (Resources build
  phase do target Runner via `xcodeproj` gem).
- `Info.plist`: `CFBundleDevelopmentRegion` → `pt-BR`, `CFBundleLocalizations`
  → `[pt-BR]`, removida a chave `UISupportedInterfaceOrientations~ipad`.
- Marca unificada em "Ponta Verde" nas strings visíveis (Dashboard, Sobre,
  `MaterialApp.title`, label do Android) — `AppConstants.appName` como fonte
  única.
- Removidos ~30 arquivos de debris de automação da raiz (continham dados
  pessoais: lista de apps do Mac do usuário, e-mail, DOM da App Store Connect)
  — movidos para fora do projeto, não versionados. **`git init` feito nesta
  sessão** — o projeto não era um repositório git até então.
- Criadas as páginas de Política de Privacidade e Suporte (`docs/*.html`,
  também publicadas como Artifacts) e `STORE.md` com o texto completo da
  ficha da loja, notas para o revisor e a mitigação da diretriz 4.3.
- Adicionados testes de fumaça (`test/app_smoke_test.dart`): boot sem rota de
  login e verificação da quarentena de dados corrompidos. 38 testes no total,
  `flutter analyze` limpo.

### Achado corrigido do meu próprio diagnóstico

A auditoria inicial apontou `path_provider` como não linkado no iOS (sem pod,
sem entrada no `GeneratedPluginRegistrant.m`). **Isso está incorreto** —
`path_provider_foundation` 2.6.0 é um plugin FFI (usa o pacote `objective_c`,
sem CocoaPod próprio) e se auto-registra via `dartPluginClass`. Confirmado
rodando no simulador iPhone 17: `Config → Exportar Dados` abre a folha de
compartilhamento normalmente.

### Ainda falta (fora do escopo desta sessão de código)

- Rodar `flutter build ipa` para gerar o **build 10** com todas as correções
  acima e enviar com `scripts/upload_testflight.sh <ISSUER_ID>`.
- Publicar as páginas de privacidade/suporte com um link público estável
  (tornar os Artifacts públicos ou publicar `docs/` no GitHub Pages) e colar
  as URLs no App Store Connect.
- Preencher a ficha da loja com o texto de `STORE.md`, tirar os screenshots de
  iPhone 6.9" e responder ao questionário de App Privacy ("Dados não
  coletados").
- Decidir e executar a mitigação da diretriz 4.3 (avaliar remover o registro
  "AgroCalc" ocioso na mesma conta).
- Itens de qualidade (P2 do plano): acessibilidade (Semantics, alternativa ao
  swipe-delete), contraste de `textTertiary`, bugs de `key`/`didUpdateWidget`
  na tabela de pontas.

## Build 10 — 2026-09-10 22:13 -03

- Versão: `1.0.0+10` (também em `pubspec.yaml`).
- Motivo: primeiro build após a correção completa dos itens P0 da auditoria
  acima — sem login mock, sem perda de histórico por JSON corrompido,
  feedback de erro em toda operação, fonte Inter embutida (sem
  `google_fonts`/`http`), `PrivacyInfo.xcprivacy`, `TARGETED_DEVICE_FAMILY =
  "1"`, `CFBundleDevelopmentRegion = pt-BR`, marca unificada "Ponta Verde".
- Comando usado:
  `flutter build ipa --release --build-name 1.0.0 --build-number 10 --export-options-plist=ios/ExportOptions.plist`
- Resultado do IPA: **entregue** — `build/ios/ipa/pontaverde.ipa` (22.5 MB).
- Validação do IPA (`Payload/Runner.app`):
  - `CFBundleShortVersionString`: `1.0.0` · `CFBundleVersion`: `10`
  - `MinimumOSVersion`: `15.0` · nenhuma chave `*UsageDescription`
  - `PrivacyInfo.xcprivacy` presente no bundle
  - Frameworks: `App`, `Flutter`, `file_picker`, `objective_c` (FFI do
    `path_provider`), `share_plus`, `shared_preferences_foundation`
  - Assinatura: `Apple Distribution: RAUDINEI AFONSO SILVA PEREIRA
    (BA2BU25B78)`, `TeamIdentifier=BA2BU25B78`
- Verificado no simulador (iPhone 17, iOS 26.2): boot direto no Dashboard sem
  tela de login, marca "Ponta Verde" em todas as telas, `Config → Exportar
  Dados` abre a folha de compartilhamento e gera o backup normalmente.

### Status

Build 10 pronto em disco, ainda **não enviado** — upload ao App Store Connect
é uma ação de conta (usa API key + Issuer ID) e fica para o usuário rodar:
`scripts/upload_testflight.sh <ISSUER_ID>` (dica de build number já corrigida
para 10). Depois do upload: anexar ao grupo `Teste Externo` e enviar para Beta
App Review. Antes do envio final para revisão, ainda faltam os artefatos de
loja listados em `STORE.md` (URLs de privacidade/suporte públicas,
screenshots de iPhone 6.9", texto da ficha, resposta ao questionário de App
Privacy) e a decisão sobre a diretriz 4.3.
