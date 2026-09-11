import 'package:agrocalc/domain/calculos/calc_litro_min_ideal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calcularLitroMinIdeal', () {
    test('150 L/ha, 18 km/h, 50 cm resulta em 2.25 L/min', () {
      final result = calcularLitroMinIdeal(
        vazaoLha: 150,
        velocidade: 18,
        espacamentoCm: 50,
      );
      expect(result, closeTo(2.25, 0.001));
    });

    test('entradas invalidas retornam zero', () {
      expect(
        calcularLitroMinIdeal(
          vazaoLha: 0,
          velocidade: 18,
          espacamentoCm: 50,
        ),
        0,
      );
    });
  });
}
