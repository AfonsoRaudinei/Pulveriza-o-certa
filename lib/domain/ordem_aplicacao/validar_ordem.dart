import 'ordem_aplicacao.dart';

/// Valida a ordem antes de salvar. Lista vazia = válida.
List<String> validarOrdem(
  OrdemAplicacao ordem, {
  required Map<String, double> estoquePorProdutoId,
}) {
  final erros = <String>[];
  if (ordem.clienteNome.trim().isEmpty) {
    erros.add('Informe o cliente.');
  }
  if (ordem.talhaoNome.trim().isEmpty) {
    erros.add('Informe o talhão.');
  }
  if (ordem.areaAplicar <= 0) {
    erros.add('Informe uma área a aplicar válida.');
  }
  if (ordem.alvo == null) {
    erros.add('Informe o alvo.');
  }
  if (ordem.produtos.isEmpty) {
    erros.add('Adicione pelo menos um produto.');
  }
  for (final produto in ordem.produtos) {
    if (!produto.reservarEstoque) continue;
    final estoque = estoquePorProdutoId[produto.produtoId] ?? 0;
    final quantidade = produto.quantidadeTotal(ordem.areaAplicar);
    if (quantidade > estoque) {
      erros.add('Estoque insuficiente para ${produto.nomeProduto}.');
    }
  }
  return erros;
}
