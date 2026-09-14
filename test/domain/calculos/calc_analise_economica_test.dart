import 'package:agrocalc/domain/calculos/calc_analise_economica.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('segmentarPerdaPorPonta', () {
    const manejoRS = 2400.0;
    const numeroPontas = 24;
    const areaHa = 500.0;
    const limiteDesgaste = 105.0;

    test('100% exato nao entra em nenhuma faixa', () {
      final segmento = segmentarPerdaPorPonta(
        percentual: 100,
        manejoRS: manejoRS,
        numeroPontas: numeroPontas,
        areaHa: areaHa,
        limiteDesgaste: limiteDesgaste,
      );
      expect(segmento.tolerancia, 0);
      expect(segmento.desgaste, 0);
    });

    test('105% exato entra em tolerancia', () {
      final segmento = segmentarPerdaPorPonta(
        percentual: 105,
        manejoRS: manejoRS,
        numeroPontas: numeroPontas,
        areaHa: areaHa,
        limiteDesgaste: limiteDesgaste,
      );
      expect(segmento.tolerancia, closeTo(2500, 0.01));
      expect(segmento.desgaste, 0);
    });

    test('105,01% entra em desgaste', () {
      final segmento = segmentarPerdaPorPonta(
        percentual: 105.01,
        manejoRS: manejoRS,
        numeroPontas: numeroPontas,
        areaHa: areaHa,
        limiteDesgaste: limiteDesgaste,
      );
      expect(segmento.tolerancia, 0);
      expect(segmento.desgaste, closeTo(2505, 0.01));
    });
  });

  group('analisarEconomia', () {
    test('cenario do documento recomenda troca completa', () {
      final result = analisarEconomia(
        percentuais: [108, 106.5, 110.2, 100, 88],
        manejoRS: 2400,
        numeroPontas: 24,
        areaHa: 500,
        precoBicoRS: 35,
      );
      expect(result.perdaTotal, closeTo(12350, 1));
      expect(result.perdaTolerancia, 0);
      expect(result.perdaDesgaste, closeTo(12350, 1));
      expect(
        result.perdaTolerancia + result.perdaDesgaste,
        closeTo(result.perdaTotal, 0.01),
      );
      expect(result.custoTrocaTotal, closeTo(840, 0.01));
      expect(result.pontaRS, closeTo(100, 0.01));
      expect(result.recomendarTroca, isTrue);
    });

    test('parcelas somam o total para percentuais acima de 100%', () {
      final percentuais = [101.0, 103.0, 108.0, 112.0];
      final result = analisarEconomia(
        percentuais: percentuais,
        manejoRS: 1200,
        numeroPontas: 12,
        areaHa: 100,
        precoBicoRS: 20,
      );
      final totalLegado = percentuais.fold<double>(
        0,
        (acc, percentual) =>
            acc +
            calcularPerdaPorPonta(
              percentual: percentual,
              manejoRS: 1200,
              numeroPontas: 12,
              areaHa: 100,
            ),
      );
      expect(result.perdaTotal, closeTo(totalLegado, 0.01));
      expect(
        result.perdaTolerancia + result.perdaDesgaste,
        closeTo(totalLegado, 0.01),
      );
    });

    test('area ou manejo zero mantem parcelas zeradas', () {
      final result = analisarEconomia(
        percentuais: [108],
        manejoRS: 0,
        numeroPontas: 24,
        areaHa: 500,
        precoBicoRS: 35,
      );
      expect(result.perdaTotal, 0);
      expect(result.perdaTolerancia, 0);
      expect(result.perdaDesgaste, 0);
    });
  });
}
