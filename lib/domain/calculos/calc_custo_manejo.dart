import '../../models/custo_manejo.dart';

double calcularTotalProdutoManejo({
  required double dose,
  required double valorUnitario,
}) {
  if (dose <= 0 || valorUnitario <= 0) return 0;
  return dose * valorUnitario;
}

double calcularTotalAplicacaoManejo(AplicacaoManejo aplicacao) {
  return aplicacao.produtos.fold<double>(
    0,
    (s, p) =>
        s +
        calcularTotalProdutoManejo(
          dose: p.dose,
          valorUnitario: p.valorUnitario,
        ),
  );
}

double calcularTotalManejo(CustoManejo custo) {
  return custo.aplicacoes.fold<double>(
    0,
    (s, a) => s + calcularTotalAplicacaoManejo(a),
  );
}

bool produtoManejoTemDados(ProdutoManejo produto) {
  return produto.nome.trim().isNotEmpty ||
      produto.dose > 0 ||
      produto.valorUnitario > 0;
}

bool produtoManejoValidoParaCalculo(ProdutoManejo produto) {
  if (produto.nome.trim().isEmpty) {
    return produto.dose <= 0 && produto.valorUnitario <= 0;
  }
  return true;
}

/// Retorna mensagem de erro ou null se pode salvar.
String? validarCustoManejoParaSalvar(CustoManejo custo) {
  if (custo.nome.trim().isEmpty) {
    return 'Informe o nome do custo de manejo.';
  }

  var produtosContabilizados = 0;
  for (final aplicacao in custo.aplicacoes) {
    for (final produto in aplicacao.produtos) {
      if (!produtoManejoValidoParaCalculo(produto)) {
        return 'Preencha o nome do produto quando informar dose ou valor.';
      }
      if (produto.nome.trim().isNotEmpty &&
          (produto.dose > 0 || produto.valorUnitario > 0)) {
        produtosContabilizados++;
      }
    }
  }

  if (produtosContabilizados == 0) {
    return 'Adicione pelo menos um produto com nome, dose e valor.';
  }

  final total = calcularTotalManejo(custo);
  if (total <= 0) {
    return 'O total do manejo deve ser maior que zero.';
  }

  return null;
}
