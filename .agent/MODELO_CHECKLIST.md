# Modelo — checklist de conclusão

Cole no **final** da resposta que encerra o trabalho. Risque só o que foi feito de verdade. `%` = itens feitos ÷ itens da lista × 100 (inteiro, sem arredondar para cima). **100%** só com todos os itens marcados.

Escolha **uma** lista: a da tarefa. Não misture IPA com merge se o usuário só pediu IPA. Não invente item extra para “completar” 100%.

```
## Checklist de conclusão — <N>%

- [ ] …
- [ ] …

Falta: <o que impede 100%, ou “nada — 100%.”>
```

## Código (feature, bug, doc versionada)

Peso 20% cada. 100% = na `main` remota.

- [ ] Implementado
- [ ] `./tool/validar.sh` passou
- [ ] `agrocalc-revisor` APROVAR
- [ ] PR aberto
- [ ] `mergedAt` na `main`

Auto-merge armado, sem `mergedAt`: no máximo 80%. Texto: **auto-merge armado, pendente de CI — ainda não está na main.**

## IPA (pedido = gerar IPA)

Peso 25% cada. Upload só vira 5º item (20% cada) se o usuário pediu TestFlight.

- [ ] `./tool/validar.sh` passou
- [ ] `.ipa` físico em `build/ios/ipa/pontaverde.ipa`
- [ ] `./tool/inspecionar_ipa.sh` passou
- [ ] Bloco novo no final de `AGENTIPA.md`

## APK (pedido = gerar APK)

- [ ] `./tool/validar.sh` passou
- [ ] `.apk` físico em `build/app/outputs/flutter-apk/app-release.apk`
- [ ] `./tool/inspecionar_apk.sh` rodou
- [ ] Bloco novo no final de `AGENTIPA.md`

## Revisão (`agrocalc-revisor`)

- [ ] Diff contra `main` lido
- [ ] Spec aplicável conferida (se o diff toca cálculo/IPA)
- [ ] `./tool/validar.sh` conferido
- [ ] Relatório Bloqueadores / Avisos / Sugestões / Veredito

## Auditoria / só leitura (sem alterar código)

- [ ] Arquivos da linha do `.agent/INDEX.md` lidos
- [ ] Conclusão objetiva escrita
- [ ] Checklist de conclusão preenchido
