import '../../models/configuracoes.dart';

({bool entreTolerancias, bool acimaToleranciaMin}) verificarTolerancia({
  required double percentual,
  required Configuracoes configuracoes,
}) {
  final acima = percentual >= configuracoes.toleranciaMin;
  return (
    entreTolerancias: acima && percentual <= configuracoes.toleranciaMax,
    acimaToleranciaMin: acima,
  );
}

({int entreTolerancias, int acimaToleranciaMin}) agregarTolerancia({
  required Iterable<double> percentuais,
  required Configuracoes configuracoes,
}) {
  var entre = 0;
  var acima = 0;

  for (final percentual in percentuais) {
    final tolerancia = verificarTolerancia(
      percentual: percentual,
      configuracoes: configuracoes,
    );
    if (tolerancia.entreTolerancias) entre++;
    if (tolerancia.acimaToleranciaMin) acima++;
  }

  return (entreTolerancias: entre, acimaToleranciaMin: acima);
}
