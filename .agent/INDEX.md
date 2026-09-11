# Índice do Ponta Verde

Leia **só** a linha da tarefa. Não abra PRD, AGENTIPA ou CALCULOS inteiro sem necessidade.

## Tarefa → abrir estes arquivos

| Se a tarefa for… | Abrir (nesta ordem) | Não abrir |
|---|---|---|
| Fórmula / % / status / tolerância / R$ | `CALCULOS/calculos_barra_pontas_INDEX.md` → o `CALCULOS/calc_*.md` certo → `lib/domain/calculos/` → `test/domain/calculos/` | PRD, AGENTIPA, `docs/` |
| Tela de regulagem / tabela de pontas | `lib/screens/regulagem/` + `.agent/CONTRATO_REGULAGEM.md` + `lib/core/utils/calculo_utils.dart` | `ios/`, AGENTIPA |
| Plantadeira (largura / rendimento) | `lib/core/utils/calculo_utils.dart` (`calcularLarguraUtil`, `calcularRendimentoOperacional`) + `regulagem_screen.dart` | `CALCULOS/` (é só pulverizador) |
| Limites / backup JSON | `lib/models/configuracoes.dart` + `lib/screens/configuracoes/` + `lib/screens/regulagem/regulagem_screen.dart` (campos inline) + `lib/services/storage_service.dart` | |
| Histórico | `lib/screens/historico/historico_screen.dart` + `lib/providers/regulagens_provider.dart` | |
| Tema / cores / badge | `lib/theme.dart` + `lib/widgets/status_badge.dart` | |
| IPA / APK / TestFlight | `AGENTIPA.md` (último bloco) + `.agent/MODELO_REGISTRO_BUILD.md` + `.cursor/agents/agrocalc-ipa.md` + `ios/` ou `android/` | `CALCULOS/` |
| Ficha da loja / privacidade | `STORE.md` + `docs/` | `lib/` |
| Produto / escopo v1 | `PONTA VERDE PRD.md` (seções 1–3) | resto do PRD até precisar |
| Teste | `test/domain/calculos/` + `test/calculo_utils_test.dart` + `test/app_smoke_test.dart` | |

## Mapa do código (26 Dart em `lib/`)

```
lib/
  main.dart, app.dart, routes.dart, theme.dart
  domain/calculos/     ← fórmulas puras (única fonte de cálculo)
  core/utils/calculo_utils.dart  ← fachada usada pela UI
  core/extensions/double_extension.dart  ← toMoeda / toPercent / toLitroMin
  core/constants/app_constants.dart  ← nome "Ponta Verde"
  models/regulagem.dart, models/configuracoes.dart
  providers/           ← estado (Provider)
  services/storage_service.dart  ← SharedPreferences + backup JSON
  screens/home, regulagem, historico, configuracoes
  widgets/status_badge.dart, app_button.dart
```

Rotas: só `/home` e `/regulagem`. **Não existe login.**

## Specs de cálculo

| # | Spec | Dart | Teste |
|---|---|---|---|
| 01 | `CALCULOS/calc_litro_min_ideal.md` | `calc_litro_min_ideal.dart` | `test/domain/calculos/calc_litro_min_ideal_test.dart` |
| 02 | `CALCULOS/calc_percentual_ponta.md` | `calc_percentual_ponta.dart` | `calc_percentual_ponta_test.dart` |
| 03 | `CALCULOS/calc_classificacao_status.md` | `calc_classificacao_status.dart` | `calc_classificacao_status_test.dart` |
| 04 | `CALCULOS/calc_tolerancia_ponta.md` | `calc_tolerancia_ponta.dart` | `calc_tolerancia_ponta_test.dart` |
| 05 | `CALCULOS/calc_analise_economica.md` | `calc_analise_economica.dart` | `calc_analise_economica_test.dart` |

Barrel: `lib/domain/calculos/calculos_barra.dart`.

Pipeline: vazão/velocidade/espaçamento → L/min ideal → % por ponta → status **e** tolerância → perda R$ / troca.

## Constantes de produto

- App: Ponta Verde · package: `agrocalc` · versão em `pubspec.yaml` (`1.0.0+10` na data deste índice)
- iOS: `com.pontaverde.app` · Team `BA2BU25B78` · mínimo iOS **15.0**
- Persistência: `agro_regulagens` / `agro_configuracoes` (ver `AppConstants`)
- Limiares padrão: desgaste 105, irregular 100, tolMin 100,5, tolMax 104,99

## Agentes

| Arquivo | Quando usar |
|---|---|
| `.cursor/agents/agrocalc-executor.md` | implementar |
| `.cursor/agents/agrocalc-revisor.md` | revisar o diff de **outro** agente |
| `.cursor/agents/agrocalc-calculos.md` | mudar ou auditar fórmula |
| `.cursor/agents/agrocalc-ipa.md` | gerar IPA e/ou APK, inspecionar, registrar em `AGENTIPA.md` |

## Validação

```
./tool/validar.sh
```

## Encerramento

Toda tarefa fechada: checklist em % (`.agent/MODELO_CHECKLIST.md`). 100% só com a lista inteira feita.
