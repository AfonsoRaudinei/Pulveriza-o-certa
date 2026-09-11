import 'package:agrocalc/domain/calculos/calc_percentual_ponta.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calcularPercentualPonta', () {
    test('ponta perfeita resulta em 100%', () {
      final result = calcularPercentualPonta(
        valorMedido: 2.25,
        litroMinIdeal: 2.25,
      );
      expect(result, closeTo(100, 0.01));
    });

    test('valor nulo ou ideal zero retorna zero', () {
      expect(
          calcularPercentualPonta(valorMedido: null, litroMinIdeal: 2.25), 0);
      expect(calcularPercentualPonta(valorMedido: 2.25, litroMinIdeal: 0), 0);
    });
  });
}
