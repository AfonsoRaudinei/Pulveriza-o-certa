import 'package:agrocalc/domain/ordem_aplicacao/calc_quantidade_total.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calcularQuantidadeTotal', () {
    test('1,5 L/ha × 80 ha = 120', () {
      expect(
        calcularQuantidadeTotal(dose: 1.5, areaAplicar: 80),
        closeTo(120, 0.0001),
      );
    });

    test('dose ou área inválida retorna zero', () {
      expect(calcularQuantidadeTotal(dose: 0, areaAplicar: 80), 0);
      expect(calcularQuantidadeTotal(dose: 1.5, areaAplicar: 0), 0);
      expect(calcularQuantidadeTotal(dose: -1, areaAplicar: 80), 0);
    });
  });
}
