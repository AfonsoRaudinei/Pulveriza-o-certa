import 'package:agrocalc/domain/calculos/calc_analise_economica.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
