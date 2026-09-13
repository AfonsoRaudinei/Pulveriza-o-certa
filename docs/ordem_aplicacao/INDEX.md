# Ordem de Aplicação — índice da spec

Módulo novo no Ponta Verde. Espelha o formulário progressivo da tela **Nova Regulagem**,
não o visual React antigo. Arquivos de referência (`OrdemAplicacaoForm.md`,
`FormularioProgressivo.md`) **não estão neste repositório** — campos e cálculos
vêm desta pasta.

Marca visível: **Ponta Verde** (nunca “AgroCalc” na UI). Offline. Sem login, HTTP ou nuvem.

## Abrir nesta ordem

| Tarefa | Spec | Dart | Teste |
|---|---|---|---|
| Widget de etapa | `widget_progressive_step_card.md` | `lib/widgets/progressive_step_card.dart` | `test/widgets/progressive_step_card_test.dart` |
| Dose × área | `calc_dose_area.md` | `lib/domain/ordem_aplicacao/calc_quantidade_total.dart` | `test/domain/ordem_aplicacao/calc_quantidade_total_test.dart` |
| Totais por unidade | `calc_totais_unidade.md` | `lib/domain/ordem_aplicacao/calc_totais_unidade.dart` | `test/domain/ordem_aplicacao/calc_totais_unidade_test.dart` |
| Validação / estoque | `validar_ordem.md` | `lib/domain/ordem_aplicacao/validar_ordem.dart` | `test/domain/ordem_aplicacao/validar_ordem_test.dart` |
| Cadastros locais | `cadastros_locais.md` | `lib/models/cadastro_local.dart` + storage | testes de cascade no validar / provider |
| Nova ordem | `tela_nova_ordem.md` | `lib/screens/ordem_aplicacao/nova_ordem_aplicacao_page.dart` | widget tests pontuais |
| Listagem | `tela_lista.md` | `lib/screens/ordem_aplicacao/ordens_aplicacao_list_page.dart` | — |

Models: `lib/domain/ordem_aplicacao/` (`ordem_aplicacao.dart`, `produto_aplicacao.dart`, `execucao_aplicacao.dart`).

## Fora de escopo deste módulo

- Backend, conta, sync
- Seletor de galeria/câmera (`*UsageDescription` continua proibido)
- Bottom navigation bar (app usa tela raiz única + FAB)
- Recalcular fórmulas da barra de pontas
