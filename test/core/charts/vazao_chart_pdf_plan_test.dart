import 'package:agrocalc/core/charts/vazao_chart_pdf_plan.dart';
import 'package:agrocalc/models/regulagem.dart';
import 'package:flutter_test/flutter_test.dart';

List<PontaMedicao> _medicoes(int n) {
  return [
    for (var i = 0; i < n; i++)
      PontaMedicao(
        id: i + 1,
        valorMedido: 1.0,
        status: StatusPonta.ideal,
      ),
  ];
}

void main() {
  test('10 pontas: um gráfico, legenda no primeiro', () {
    final blocos = planejarGraficosVazaoPdf(
      medicoes: _medicoes(10),
      ladoConferencia: LadoConferenciaPontas.direita,
    );
    expect(blocos.length, 1);
    expect(blocos.first.medicoes.length, 10);
    expect(blocos.first.mostrarLegendaMarcadores, isTrue);
    expect(blocos.first.titulo, contains('1D'));
    expect(blocos.first.titulo, contains('10D'));
  });

  test('30 pontas: dois gráficos (15D e 15E)', () {
    final blocos = planejarGraficosVazaoPdf(
      medicoes: _medicoes(30),
      ladoConferencia: LadoConferenciaPontas.direita,
    );
    expect(blocos.length, 2);
    expect(blocos[0].medicoes.length, 15);
    expect(blocos[1].medicoes.length, 15);
    expect(blocos[0].lado, LadoConferenciaPontas.direita);
    expect(blocos[1].lado, LadoConferenciaPontas.esquerda);
    expect(blocos[0].titulo, contains('15D'));
    expect(blocos[1].titulo, contains('15E'));
    expect(blocos[0].mostrarLegendaMarcadores, isTrue);
    expect(blocos[1].mostrarLegendaMarcadores, isFalse);
  });

  test('60 pontas: quatro gráficos (dois blocos por lado)', () {
    final blocos = planejarGraficosVazaoPdf(
      medicoes: _medicoes(60),
      ladoConferencia: LadoConferenciaPontas.direita,
    );
    expect(blocos.length, 4);
    for (final b in blocos) {
      expect(b.medicoes.length, 15);
    }
    expect(blocos[0].lado, LadoConferenciaPontas.direita);
    expect(blocos[2].lado, LadoConferenciaPontas.esquerda);
    expect(blocos[0].titulo, contains('1D'));
    expect(blocos[1].titulo, contains('16D'));
    expect(blocos[2].titulo, contains('1E'));
    expect(blocos[3].titulo, contains('16E'));
    expect(blocos.where((b) => b.mostrarLegendaMarcadores).length, 1);
  });

  test('45 pontas em um lado divide em três blocos iguais de 15', () {
    final blocos = planejarGraficosVazaoPdf(
      medicoes: _medicoes(90),
      ladoConferencia: LadoConferenciaPontas.direita,
    );
    expect(blocos.length, 6);
    final direita = blocos.where((b) => b.lado == LadoConferenciaPontas.direita);
    expect(direita.length, 3);
    for (final b in direita) {
      expect(b.medicoes.length, 15);
    }
  });
}
