import 'package:agrocalc/domain/calculos/calc_valor_total_safra.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calcularValorTotalSafra', () {
    test('manejo 600 e area 700 retorna 420000', () {
      expect(
        calcularValorTotalSafra(manejoRS: 600, areaHa: 700),
        closeTo(420000, 0.01),
      );
    });

    test('manejo zero retorna zero sem excecao', () {
      expect(
        calcularValorTotalSafra(manejoRS: 0, areaHa: 700),
        closeTo(0, 0.01),
      );
    });

    test('area zero retorna zero sem excecao', () {
      expect(
        calcularValorTotalSafra(manejoRS: 600, areaHa: 0),
        closeTo(0, 0.01),
      );
    });

    test('valores negativos retornam zero', () {
      expect(
        calcularValorTotalSafra(manejoRS: -600, areaHa: 700),
        closeTo(0, 0.01),
      );
      expect(
        calcularValorTotalSafra(manejoRS: 600, areaHa: -700),
        closeTo(0, 0.01),
      );
    });
  });
}
