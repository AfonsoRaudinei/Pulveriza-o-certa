enum AlvoAplicacao {
  sugadores,
  mastigadores,
  folhaLarga,
  folhaFina,
  doenca,
  carenciaNutricional,
  inseto,
  ervaDaninha,
}

extension AlvoAplicacaoX on AlvoAplicacao {
  String get label {
    switch (this) {
      case AlvoAplicacao.sugadores:
        return 'Sugadores';
      case AlvoAplicacao.mastigadores:
        return 'Mastigadores';
      case AlvoAplicacao.folhaLarga:
        return 'Folha larga';
      case AlvoAplicacao.folhaFina:
        return 'Folha fina';
      case AlvoAplicacao.doenca:
        return 'Doença';
      case AlvoAplicacao.carenciaNutricional:
        return 'Carência nutricional';
      case AlvoAplicacao.inseto:
        return 'Inseto';
      case AlvoAplicacao.ervaDaninha:
        return 'Erva daninha';
    }
  }
}

enum StatusOrdem { aberta, executando, concluida, cancelada }

extension StatusOrdemX on StatusOrdem {
  String get label {
    switch (this) {
      case StatusOrdem.aberta:
        return 'Aberta';
      case StatusOrdem.executando:
        return 'Executando';
      case StatusOrdem.concluida:
        return 'Concluída';
      case StatusOrdem.cancelada:
        return 'Cancelada';
    }
  }
}
