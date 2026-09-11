# Prompts do agente — regras gerais + contratos do Ponta Verde

Fonte da verdade: `AGENTS.md` (raiz) e este arquivo.

---

## REGRA-CHECKLIST-1 — Sempre um checklist de conclusão em %

Toda resposta que **encerra** trabalho (implementação, review, IPA/APK, auditoria)
termina com o checklist de `.agent/MODELO_CHECKLIST.md`. Sem o bloco, a tarefa
não foi encerrada.

Regras:

- Itens da lista escolhida têm o **mesmo peso**. `% = feitos / aplicáveis × 100` (inteiro).
- **100%** só com todos os itens aplicáveis feitos. Não arredondar para cima. Não omitir item aberto.
- Código que vai para o app: 100% exige `mergedAt` na `main`. Auto-merge pendente **não** é 100%.
- IPA/APK pedido como “gerar”: 100% = arquivo físico + inspeção + registro em `AGENTIPA.md`. TestFlight/Play só entram se foram pedidos.
- Título obrigatório: `## Checklist de conclusão — <N>%`

Formato:

```
## Checklist de conclusão — <N>%

- [x] item feito
- [ ] item aberto

Falta: <impedimento, ou “nada — 100%.”>
```

---

## REGRA-ENTREGA-1 — Toda correção precisa chegar na main (no app)

Vale para qualquer prompt executado neste repositório (bug fix, feature, doc, ajuste
de layout), não só para o tema abaixo.

Nunca considerar uma tarefa concluída com o código parado numa branch de feature
(cursor/...). Commit + push numa branch é só o meio do caminho — a correção só está
no aplicativo depois do merge na main remota.

Checklist obrigatório antes de encerrar QUALQUER resposta que tenha alterado código:

```
# 1) validar
./tool/validar.sh

# 2) commit por arquivo + push da branch (executor)
git push -u origin <branch>

# 3) supervisor: PR + revisor + auto-merge rebase (nunca push em main)
#    O revisor é o subagente agrocalc-revisor — nunca o mesmo que implementou.
gh pr merge --auto --rebase

# 4) encerramento honesto — mergedAt ou "pendente de CI", nunca fingir entrega
gh pr view <n> --json state,mergedAt,mergeStateStatus,autoMergeRequest,url
```

Se não houver mergedAt, a tarefa não está pronta. Texto obrigatório se o auto-merge estiver armado: **auto-merge armado, pendente de CI — ainda não está na main.**

Se `gh` não autenticar ou não houver proteção de branch/CI: criar o PR mesmo assim, **não** dar push na `main`, e declarar o bloqueio com a URL do PR.

Trilha IPA / APK: `AGENTIPA.md` · `.agent/MODELO_REGISTRO_BUILD.md` · `scripts/upload_testflight.sh`. Não marcar 100% só com testes verdes, IPA/APK no disco ou `flutter build` local. IPA no disco ≠ TestFlight. APK no disco ≠ Play Store. TestFlight enviado ≠ na App Store.

---

## Prompt — Pipeline da barra (REGRA-CALC-BARRA-1)

Verdade operacional (contrato atual)

Cadeia obrigatória — não recalcular a fórmula no widget:

```
formulário (vazão, km/h, espaçamento cm)
  → calcularLitroMinIdeal          (Cálculo 01)
  → calcularPercentualPonta        (Cálculo 02)
  ├→ classificarPonta              (Cálculo 03)  Ideal / Irregular / Desgaste / Pendente
  └→ agregarTolerancia             (Cálculo 04)  entreTolerancias / acimaMin
  → perda + custo + recomendarTroca (Cálculo 05)
```

UI chama `CalcUtils` (`lib/core/utils/calculo_utils.dart`). Fórmulas vivem só em `lib/domain/calculos/`. Spec em `CALCULOS/`. Teste em `test/domain/calculos/` + `test/calculo_utils_test.dart`.

Limiares padrão (também em `Configuracoes`):

| Limiar | Valor | Regra |
|---|---|---|
| irregular | `< 100` | exclusivo no 100 |
| ideal | `100 … 105` | 105 exato ainda é Ideal |
| desgaste | `> 105` | exclusivo no 105 |
| entre tolerâncias | `100,5 … 104,99` | inclusivo nos dois |
| acima min | `>= 100,5` | inclui desgaste |

`null` ≠ `0`: ponta não medida (`null`) = Pendente; medição `0` = Irregular. Fonte: INDEX dos cálculos, não o snippet antigo de `calc_classificacao_status.md` que trata `percentual <= 0` como Pendente.

Plantadeira (fora de `CALCULOS/`):

```
larguraUtil = nLinhas × espacamentoLinhasM
rendimento  = (larguraUtil × velocidade × eficiencia/100) / 10
```

Proibido:

- Copiar fórmula para `pontas_table.dart` / `regulagem_screen.dart` em vez de chamar `CalcUtils`
- Mudar constante 600, limiar 105/100/100.5/104.99 ou a regra `perda só se percentual > 100` sem atualizar spec + teste no mesmo PR
- Introduzir login, HTTP ou sync em nuvem (v1 congelada — PRD §2)

Antes de tocar `lib/domain/calculos/`:

```
./tool/validar.sh
```

Validação extra se a mudança for de fórmula:

```
flutter test test/domain/calculos/ test/calculo_utils_test.dart
```

---

## Prompt — IPA / APK (REGRA-IPA-1)

Status operacional — ler o **último** bloco em `AGENTIPA.md` antes de gerar outro. `pubspec.yaml` é a versão do código (`1.0.0+10` no índice atual). Agente: `agrocalc-ipa`. Modelo do diário: `.agent/MODELO_REGISTRO_BUILD.md`.

**IPA** = iOS (TestFlight / App Store). **APK** = Android (instalar no celular). **AAB** = Play Store, só se o usuário pedir.

Contrato fechado iOS (não reabrir sem nota em AGENTIPA):

| Item | Valor |
|---|---|
| Bundle ID | `com.pontaverde.app` |
| Team | `BA2BU25B78` |
| MinimumOSVersion | **15.0** (erro 90068 se voltar a 13) |
| Purpose strings | **nenhuma** `*UsageDescription` (erro 90683) |
| Podfile | `::PICKER_MEDIA = false` e `::PICKER_AUDIO = false` **no topo**, com `::` |
| Export | `--export-options-plist=ios/ExportOptions.plist` |
| IPA físico | `build/ios/ipa/pontaverde.ipa` |
| Inspeção | `./tool/inspecionar_ipa.sh` |

Android hoje: `applicationId` = `com.example.agrocalc`; release assina com debug. APK: `build/app/outputs/flutter-apk/app-release.apk`. Inspeção: `./tool/inspecionar_apk.sh`.

Todo IPA/APK gerado **registra bloco no final de `AGENTIPA.md` no mesmo turno**. Um IPA só é “entregue” com `.ipa` físico **e** payload validado. Archive sem `.ipa` não conta. Disco sem upload não está no TestFlight / Play.

Proibido:

- Encerrar o turno de build sem o bloco em `AGENTIPA.md`
- Reenviar o mesmo `CFBundleVersion` já registrado no App Store Connect
- Remover as constantes `::PICKER_*` (volta DKImagePickerController)
- Baixar `IPHONEOS_DEPLOYMENT_TARGET` abaixo de 15.0
- Marcar TestFlight como enviado sem `scripts/upload_testflight.sh` ter concluído o upload
- Trocar `applicationId` / keystore Android no meio de um pedido só de APK, salvo o usuário pedir loja

Validação antes do `flutter build ipa` / `apk`:

```
./tool/validar.sh
```
