# Validação — Ordem de Aplicação

> **Onde vive:** `lib/domain/ordem_aplicacao/validar_ordem.dart`  
> **Quem consome:** botão Salvar e cards de alerta na tela  
> **Origem:** `validarFormulario()` da referência React

## Função

```dart
List<String> validarOrdem(OrdemAplicacao ordem, {required Map<String, double> estoquePorProdutoId})
```

Retorna lista vazia se válida. Ordem das mensagens:

1. `Informe o cliente.`
2. `Informe o talhão.`
3. `Informe uma área a aplicar válida.` — quando `areaAplicar <= 0`
4. `Informe o alvo.`
5. `Adicione pelo menos um produto.`
6. Para cada produto com `reservarEstoque == true` e `quantidadeTotal > estoque`:
   `Estoque insuficiente para {nomeProduto}.`

Fazenda é exigida na prática pelo seletor em cascata (sem fazenda não há talhão). Não duplicar mensagem de fazenda se o talhão já cobre o caso.

## Estoque

`estoquePorProdutoId` vem do catálogo local. Produto sem chave = estoque `0` quando a reserva está marcada.

Baixa real de estoque só ocorre no save se:

- `reservarEstoque` no item, ou
- execução com “Dar saída do estoque ao concluir” e status `concluida`

A reserva no save subtrai `quantidadeTotal` do catálogo. Persistência 100% local.
