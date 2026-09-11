enum UnidadeDose { lHa, kgHa, mlHa, gHa, unHa, scHa }

extension UnidadeDoseX on UnidadeDose {
  String get label {
    switch (this) {
      case UnidadeDose.lHa:
        return 'L/ha';
      case UnidadeDose.kgHa:
        return 'kg/ha';
      case UnidadeDose.mlHa:
        return 'ml/ha';
      case UnidadeDose.gHa:
        return 'g/ha';
      case UnidadeDose.unHa:
        return 'un/ha';
      case UnidadeDose.scHa:
        return 'sc/ha';
    }
  }

  String get quantidadeLabel {
    switch (this) {
      case UnidadeDose.lHa:
        return 'L';
      case UnidadeDose.kgHa:
        return 'kg';
      case UnidadeDose.mlHa:
        return 'ml';
      case UnidadeDose.gHa:
        return 'g';
      case UnidadeDose.unHa:
        return 'un';
      case UnidadeDose.scHa:
        return 'sc';
    }
  }

  static UnidadeDose? fromLabel(String label) {
    for (final unidade in UnidadeDose.values) {
      if (unidade.label == label) return unidade;
    }
    return null;
  }
}

class TotalUnidade {
  const TotalUnidade({required this.unidade, required this.quantidade});

  final UnidadeDose unidade;
  final double quantidade;
}

/// Soma quantidadeTotal agrupada pela unidade da dose.
List<TotalUnidade> calcularTotaisPorUnidade(
  Iterable<({UnidadeDose unidade, double quantidadeTotal})> itens,
) {
  final mapa = <UnidadeDose, double>{};
  for (final item in itens) {
    mapa[item.unidade] = (mapa[item.unidade] ?? 0) + item.quantidadeTotal;
  }
  return UnidadeDose.values
      .where(mapa.containsKey)
      .map(
        (unidade) => TotalUnidade(unidade: unidade, quantidade: mapa[unidade]!),
      )
      .toList();
}
