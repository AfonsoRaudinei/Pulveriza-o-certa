# Índice do Ponta Verde

Leia **só** a linha da tarefa. Não abra PRD, AGENTIPA ou CALCULOS inteiro sem necessidade.

## Tarefa → abrir estes arquivos

| Se a tarefa for… | Abrir (nesta ordem) | Não abrir |
|---|---|---|
| Fórmula / % / status / tolerância / R$ | `CALCULOS/calculos_barra_pontas_INDEX.md` → o `CALCULOS/calc_*.md` certo → `lib/domain/calculos/` → `test/domain/calculos/` | PRD, AGENTIPA, `docs/` |
| Tela de regulagem / tabela de pontas | `lib/screens/regulagem/` + `.agent/CONTRATO_REGULAGEM.md` + `lib/core/utils/calculo_utils.dart` | `ios/`, AGENTIPA |
| Gráfico "Vazão por ponta" (tela + laudo) | `lib/core/charts/vazao_chart_data.dart` → `lib/screens/regulagem/widgets/grafico_vazao_pontas.dart` + `_paintChart` em `lib/services/regulagem_pdf_service.dart` + `.agent/CONTRATO_REGULAGEM.md` | `CALCULOS/` |
| Ordem de aplicação / ProgressiveStepCard | `docs/ordem_aplicacao/INDEX.md` → spec da tela → `lib/domain/ordem_aplicacao/` → `lib/screens/ordem_aplicacao/` → `lib/widgets/progressive_step_card.dart` | `CALCULOS/` (barra), AGENTIPA |
| Plantadeira (largura / rendimento) | `lib/core/utils/calculo_utils.dart` (`calcularLarguraUtil`, `calcularRendimentoOperacional`) + `regulagem_screen.dart` | `CALCULOS/` (é só pulverizador) |
| Limites / backup JSON | `lib/models/configuracoes.dart` + `lib/screens/configuracoes/` + `lib/screens/regulagem/regulagem_screen.dart` (campos inline) + `lib/services/storage_service.dart` | |
| Histórico | `lib/screens/historico/historico_screen.dart` + `lib/providers/regulagens_provider.dart` | |
| Tema / cores / badge | `lib/theme.dart` + `lib/widgets/status_badge.dart` | |
| IPA / APK / TestFlight | `AGENTIPA.md` (último bloco) + `.agent/MODELO_REGISTRO_BUILD.md` + `.cursor/agents/agrocalc-ipa.md` + `ios/` ou `android/` | `CALCULOS/` |
| Ficha da loja / privacidade | `STORE.md` + `docs/` | `lib/` |
| Produto / escopo v1 | `PONTA VERDE PRD.md` (seções 1–3) | resto do PRD até precisar |
| Teste | `test/domain/calculos/` + `test/calculo_utils_test.dart` + `test/app_smoke_test.dart` | |

## Mapa do código

```
lib/
  main.dart, app.dart, routes.dart, theme.dart
  domain/calculos/     ← fórmulas da barra
  domain/ordem_aplicacao/  ← ordem (dose×área, totais, validação)
  core/utils/calculo_utils.dart  ← fachada usada pela UI de regulagem
  core/charts/vazao_chart_data.dart  ← dados do gráfico (tela + PDF)
  core/extensions/double_extension.dart  ← toMoeda / toPercent / toLitroMin
  core/constants/app_constants.dart  ← nome "Ponta Verde"
  models/regulagem.dart, models/configuracoes.dart, models/cadastro_local.dart
  providers/           ← estado (Provider)
  services/storage_service.dart  ← SharedPreferences + backup JSON
  screens/home, regulagem, historico, configuracoes, ordem_aplicacao
  widgets/status_badge.dart, app_button.dart, progressive_step_card.dart,
  widgets/card_zona_atencao.dart
```

Rotas: `/home`, `/regulagem`, `/ordens`, `/ordem-aplicacao`. **Não existe login.**

## Specs de cálculo

| # | Spec | Dart | Teste |
|---|---|---|---|
| 01 | `CALCULOS/calc_litro_min_ideal.md` | `calc_litro_min_ideal.dart` | `test/domain/calculos/calc_litro_min_ideal_test.dart` |
| 02 | `CALCULOS/calc_percentual_ponta.md` | `calc_percentual_ponta.dart` | `calc_percentual_ponta_test.dart` |
| 03 | `CALCULOS/calc_classificacao_status.md` | `calc_classificacao_status.dart` | `calc_classificacao_status_test.dart` |
| 04 | `CALCULOS/calc_tolerancia_ponta.md` | `calc_tolerancia_ponta.dart` | `calc_tolerancia_ponta_test.dart` |
| 05 | `CALCULOS/calc_analise_economica.md` | `calc_analise_economica.dart` | `calc_analise_economica_test.dart` |
| 06 | `CALCULOS/calc_perda_zona_atencao.md` | `calc_perda_zona_atencao.dart` | `calc_perda_zona_atencao_test.dart` |

Barrel: `lib/domain/calculos/calculos_barra.dart`.

Pipeline: vazão/velocidade/espaçamento → L/min ideal → % por ponta → status **e** tolerância → perda R$ / troca.

## Constantes de produto

- App: Ponta Verde · package: `agrocalc` · versão em `pubspec.yaml` (`1.0.0+10` na data deste índice)
- iOS: `com.pontaverde.app` · Team `BA2BU25B78` · mínimo iOS **15.0**
- Persistência: `agro_regulagens` / `agro_configuracoes` / `agro_ordens_aplicacao` / `agro_cadastros`
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
