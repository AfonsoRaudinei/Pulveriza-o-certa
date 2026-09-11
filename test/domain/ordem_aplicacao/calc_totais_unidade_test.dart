import 'package:agrocalc/domain/ordem_aplicacao/calc_totais_unidade.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calcularTotaisPorUnidade', () {
    test('soma L e g do exemplo canônico', () {
      final totais = calcularTotaisPorUnidade([
        (unidade: UnidadeDose.lHa, quantidadeTotal: 120),
        (unidade: UnidadeDose.lHa, quantidadeTotal: 32),
        (unidade: UnidadeDose.gHa, quantidadeTotal: 16000),
      ]);

      expect(totais.length, 2);
      expect(totais[0].unidade, UnidadeDose.lHa);
      expect(totais[0].quantidade, closeTo(152, 0.0001));
      expect(totais[1].unidade, UnidadeDose.gHa);
      expect(totais[1].quantidade, closeTo(16000, 0.0001));
    });

    test('lista vazia retorna vazio', () {
      expect(calcularTotaisPorUnidade(const []), isEmpty);
    });
  });
}
