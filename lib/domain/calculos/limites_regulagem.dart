/// Limites de classificação gravados no laudo (snapshot).
///
/// Alterar os limites globais depois não muda laudos que já carregam estes
/// valores. A validação exige `limiteEntupido <= 100 <= limiteDesgaste`.
class LimitesRegulagem {
  const LimitesRegulagem({
    required this.limiteEntupido,
    required this.limiteDesgaste,
  });

  static const padrao = LimitesRegulagem(
    limiteEntupido: 97,
    limiteDesgaste: 105,
  );

  final double limiteEntupido;
  final double limiteDesgaste;

  /// Ideal só existe quando há intervalo abaixo de 100%.
  bool get temZonaIdeal => limiteEntupido < 100;

  /// Atenção só existe quando o limite de desgaste fica acima de 100%.
  bool get temZonaAtencao => limiteDesgaste > 100;

  String get faixaEntupida => '< ${_formatarPercentual(limiteEntupido)}%';

  String get faixaIdeal => '${_formatarPercentual(limiteEntupido)}–100%';

  String get faixaAtencao => '100–${_formatarPercentual(limiteDesgaste)}%';

  String get faixaDesgaste => '> ${_formatarPercentual(limiteDesgaste)}%';

  String get linhaCabecalho =>
      'Limites: entupida $faixaEntupida · desgaste $faixaDesgaste';

  ResultadoValidacaoLimites validar() => validarLimitesRegulagem(
        limiteEntupido: limiteEntupido,
        limiteDesgaste: limiteDesgaste,
      );
}

class ResultadoValidacaoLimites {
  const ResultadoValidacaoLimites({
    required this.valido,
    this.mensagem,
  });

  final bool valido;
  final String? mensagem;
}

ResultadoValidacaoLimites validarLimitesRegulagem({
  required double limiteEntupido,
  required double limiteDesgaste,
}) {
  if (limiteEntupido <= 0 || limiteDesgaste <= 0) {
    return const ResultadoValidacaoLimites(
      valido: false,
      mensagem: 'Informe os limites de regulagem.',
    );
  }
  if (limiteEntupido > 100 || limiteDesgaste < 100) {
    return const ResultadoValidacaoLimites(
      valido: false,
      mensagem: 'Limite entupida deve ser ≤ 100% e limite desgaste ≥ 100%.',
    );
  }
  return const ResultadoValidacaoLimites(valido: true);
}

String formatarLimitePercentual(double valor) => _formatarPercentual(valor);

String _formatarPercentual(double valor) {
  if (valor == valor.roundToDouble()) return valor.toStringAsFixed(0);
  final umaCasa = (valor * 10).roundToDouble() / 10;
  if (umaCasa == valor || (valor - umaCasa).abs() < 0.0001) {
    return valor.toStringAsFixed(1);
  }
  return valor.toStringAsFixed(2);
}
