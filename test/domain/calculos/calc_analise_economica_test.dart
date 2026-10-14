import 'package:agrocalc/domain/calculos/calc_analise_economica.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('numeroAplicacoesEfetivo', () {
    test('null ou zero → 1', () {
      expect(numeroAplicacoesEfetivo(null), 1);
      expect(numeroAplicacoesEfetivo(0), 1);
    });
  });

  group('recomendarTrocaCompleta', () {
    test('empate perda == custo → troca completa', () {
      expect(
        recomendarTrocaCompleta(
          perdaEstimadaTotal: 800,
          custoTrocaTotal: 800,
        ),
        isTrue,
      );
    });

    test('perda logo abaixo do custo → troca seletiva', () {
      expect(
        recomendarTrocaCompleta(
          perdaEstimadaTotal: 799.99,
          custoTrocaTotal: 800,
        ),
        isFalse,
      );
    });

    test('custo total zero → não recomenda troca completa', () {
      expect(
        recomendarTrocaCompleta(
          perdaEstimadaTotal: 1000,
          custoTrocaTotal: 0,
        ),
        isFalse,
      );
    });
  });

  group('calcularPerdaSafra', () {
    test('multiplica perda por aplicação', () {
      expect(
        calcularPerdaSafra(perdaPorAplicacao: 100, numeroAplicacoes: 5),
        500,
      );
    });

    test('default compatível → ×1', () {
      expect(
        calcularPerdaSafra(perdaPorAplicacao: 446.62, numeroAplicacoes: null),
        closeTo(446.62, 0.001),
      );
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
      expect(result.custoTrocaTotal, closeTo(840, 0.01));
      expect(result.pontaRS, closeTo(100, 0.01));
      expect(result.recomendarTroca, isTrue);
    });
  });
}
