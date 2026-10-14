# Configurações — checklist de conclusão

Auditoria e correções do módulo **Configurações** (out/2026).  
Critérios de laudo PDF continuam em [`LAUDO_ACEITE_CHECKLIST.md`](LAUDO_ACEITE_CHECKLIST.md).

## Main (entrada no app)

- Rota: `Routes.configuracoes` → [`lib/screens/configuracoes/configuracoes_screen.dart`](lib/screens/configuracoes/configuracoes_screen.dart)
- Navegação: lista **Regulagens** → FAB **+** → **Configuração**
- Bootstrap: [`lib/main.dart`](lib/main.dart) → [`lib/app.dart`](lib/app.dart) (`ConfiguracoesProvider.load()` na abertura)

## Implementação (código) — feito

- [x] Perfil não é sobrescrito ao mudar tema/cor/marca sem salvar (`_perfilDivergeDoSalvo` + `forcePerfil` no sync)
- [x] Botão **Salvar perfil** logo abaixo dos campos de perfil
- [x] Pré-visualização de logo e fundo atualiza ao trocar imagem (`imageCacheEpoch` / `ValueKey`)
- [x] iOS: `NSCameraUsageDescription` e `NSPhotoLibraryUsageDescription` em `ios/Runner/Info.plist`
- [x] macOS: sandbox `files.user-selected.read-only` e `device.camera` nos entitlements
- [x] Cor personalizada: hex aplicado ao tocar **Usar cor** (`seletor_cor_marca_dialog.dart`)
- [x] Backup `.zip` inclui `marca_perfil/logo_marca.jpg` e `fundo_cabecalho.jpg`; import restaura
- [x] **Apagar todos os dados** remove logo e fundo no disco
- [x] Testes: `test/configuracoes_tema_test.dart`, `test/services/storage_marca_backup_test.dart`

## QA manual (dispositivo) — pendente

- [ ] Preencher perfil, mudar tema/cor, **Salvar perfil** — valores persistem após reabrir Configurações
- [ ] Trocar logo duas vezes — miniatura e pré-visualização do cabeçalho acompanham
- [ ] iPhone: **Câmera** no fundo do cabeçalho abre sem crash
- [ ] Mac: **Importar backup** e escolher logo/galeria funcionam no sandbox
- [ ] Exportar backup em um aparelho, importar em outro — logo e fundo aparecem no PDF

## Gate técnico

- [ ] `./tool/validar.sh` passou (rodar antes do próximo IPA)
- [x] `flutter test test/configuracoes_tema_test.dart test/services/storage_marca_backup_test.dart` passando na sessão da auditoria

_Registro: após QA manual, preencher data e build em `AGENTIPA.md`._
