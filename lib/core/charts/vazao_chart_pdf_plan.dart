import '../../models/regulagem.dart';

/// Máximo de pontas por gráfico no laudo PDF (altere aqui se precisar).
const int maxPontasPorGraficoPdf = 20;

/// Um bloco de gráfico no PDF (título, fatia de medições e lado D/E).
class BlocoGraficoVazaoPdf {
  const BlocoGraficoVazaoPdf({
    required this.titulo,
    required this.medicoes,
    required this.lado,
    required this.indiceInicioNoLado,
    required this.mostrarLegendaMarcadores,
  });

  final String titulo;
  final List<PontaMedicao> medicoes;
  final LadoConferenciaPontas lado;
  /// Número da ponta no lado (1-based) do primeiro item do bloco.
  final int indiceInicioNoLado;
  final bool mostrarLegendaMarcadores;
}

String _nomeLado(LadoConferenciaPontas lado) {
  return lado == LadoConferenciaPontas.direita ? 'direito' : 'esquerdo';
}

String _tituloIntervalo({
  required LadoConferenciaPontas lado,
  required int indiceInicioNoLado,
  required int indiceFimNoLado,
}) {
  final ini = rotuloPonta(indiceInicioNoLado, lado);
  final fim = rotuloPonta(indiceFimNoLado, lado);
  return 'Vazão por ponta: lado ${_nomeLado(lado)} ($ini a $fim)';
}

List<List<PontaMedicao>> _dividirEmBlocosIguais(
  List<PontaMedicao> pontas,
  int maxPorBloco,
) {
  final n = pontas.length;
  if (n <= maxPorBloco) return [pontas];
  final k = (n + maxPorBloco - 1) ~/ maxPorBloco;
  final tamanho = (n / k).ceil();
  final blocos = <List<PontaMedicao>>[];
  for (var i = 0; i < n; i += tamanho) {
    final fim = i + tamanho > n ? n : i + tamanho;
    blocos.add(pontas.sublist(i, fim));
  }
  return blocos;
}

List<BlocoGraficoVazaoPdf> planejarGraficosVazaoPdf({
  required List<PontaMedicao> medicoes,
  required LadoConferenciaPontas ladoConferencia,
}) {
  if (medicoes.isEmpty) return [];

  final blocos = <BlocoGraficoVazaoPdf>[];
  var legenda = true;

  void adicionarLado({
    required List<PontaMedicao> pontasDoLado,
    required LadoConferenciaPontas lado,
  }) {
    final partes = _dividirEmBlocosIguais(
      pontasDoLado,
      maxPontasPorGraficoPdf,
    );
    var offset = 0;
    for (final parte in partes) {
      final inicio = offset + 1;
      final fim = offset + parte.length;
      blocos.add(
        BlocoGraficoVazaoPdf(
          titulo: _tituloIntervalo(
            lado: lado,
            indiceInicioNoLado: inicio,
            indiceFimNoLado: fim,
          ),
          medicoes: parte,
          lado: lado,
          indiceInicioNoLado: inicio,
          mostrarLegendaMarcadores: legenda,
        ),
      );
      legenda = false;
      offset = fim;
    }
  }

  final total = medicoes.length;
  if (total <= maxPontasPorGraficoPdf) {
    return [
      BlocoGraficoVazaoPdf(
        titulo: _tituloIntervalo(
          lado: ladoConferencia,
          indiceInicioNoLado: 1,
          indiceFimNoLado: total,
        ),
        medicoes: medicoes,
        lado: ladoConferencia,
        indiceInicioNoLado: 1,
        mostrarLegendaMarcadores: true,
      ),
    ];
  }

  final metade = total ~/ 2;
  adicionarLado(
    pontasDoLado: medicoes.sublist(0, metade),
    lado: LadoConferenciaPontas.direita,
  );
  adicionarLado(
    pontasDoLado: medicoes.sublist(metade),
    lado: LadoConferenciaPontas.esquerda,
  );
  return blocos;
}
