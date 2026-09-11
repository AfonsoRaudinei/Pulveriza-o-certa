# Tela — Lista de Ordens de Aplicação

> **Rota:** `/ordens`  
> **Arquivo:** `lib/screens/ordem_aplicacao/ordens_aplicacao_list_page.dart`  
> **Referência visual:** cards de `HistoricoScreen` (`_RegulagemCard`)

## Layout do card

- Cantos `AppRadius.lg`, fundo `surface`, borda `border`
- Título (negrito): nome do cliente
- Subtítulo cinza: `fazenda • talhão`
- Duas pills (`Chip`): status da ordem + data
- Linha de resumo: `{n} produtos — {áreaAplicar} ha • {alvo}`

Tap abre edição. FAB ou botão no AppBar: nova ordem.

Empty state: “Nenhuma ordem ainda. Crie a primeira!”

Exclusão: mesmo padrão do histórico (confirmação + SnackBar Desfazer 4 s).

## Entrada no app

Dashboard (aba Início): botão secundário **Nova Ordem de Aplicação** (não substitui Nova Regulagem) e atalho “Ver ordens”. Sem quarta aba na bottom nav.
