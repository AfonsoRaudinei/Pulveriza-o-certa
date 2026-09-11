import 'package:agrocalc/domain/calculos/calc_tolerancia_ponta.dart';
import 'package:agrocalc/models/configuracoes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('agregarTolerancia', () {
    test('conta entre tolerancias e acima min separadamente', () {
      final result = agregarTolerancia(
        percentuais: [88, 100, 101.5, 103, 107],
        configuracoes: const Configuracoes(),
      );
      expect(result.entreTolerancias, 2);
      expect(result.acimaToleranciaMin, 3);
    });
  });
}
