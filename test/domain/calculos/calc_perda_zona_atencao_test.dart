import 'package:agrocalc/domain/calculos/calc_perda_zona_atencao.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const manejo = 2400.0;
  const n = 24;
  const area = 500.0;

  group('calcularPerdaZonaAtencao', () {
    test('nenhuma ponta na faixa → zero', () {
      final r = calcularPerdaZonaAtencao(
        percentuais: [88, 100, 108, 110.2],
        manejoRS: manejo,
        numeroPontas: n,
        areaHa: area,
      );
      expect(r.perdaEstimada, 0);
      expect(r.qtdPontasNaZona, 0);
    });

    test('todas na faixa → soma o exemplo 103% + 105%', () {
      final r = calcularPerdaZonaAtencao(
        percentuais: [103, 105],
        manejoRS: manejo,
        numeroPontas: n,
        areaHa: area,
      );
      expect(r.qtdPontasNaZona, 2);
      expect(r.perdaEstimada, closeTo(4000, 0.01));
    });

    test('mistura de faixas ignora Entupido, 100% e Desgaste', () {
      final r = calcularPerdaZonaAtencao(
        percentuais: [88, 100, 101, 103, 105, 105.01, 108],
        manejoRS: manejo,
        numeroPontas: n,
        areaHa: area,
      );
      // 101 → 500; 103 → 1500; 105 → 2500
      expect(r.qtdPontasNaZona, 3);
      expect(r.perdaEstimada, closeTo(4500, 0.01));
    });

    test('105% exato entra; acima do limite não', () {
      final r = calcularPerdaZonaAtencao(
        percentuais: [105, 105.01],
        manejoRS: manejo,
        numeroPontas: n,
        areaHa: area,
      );
      expect(r.qtdPontasNaZona, 1);
      expect(r.perdaEstimada, closeTo(2500, 0.01));
    });

    test('limiteDesgaste customizado 110 inclui 108%', () {
      final r = calcularPerdaZonaAtencao(
        percentuais: [108, 112],
        manejoRS: manejo,
        numeroPontas: n,
        areaHa: area,
        limiteDesgaste: 110,
      );
      expect(r.qtdPontasNaZona, 1);
      expect(r.perdaEstimada, closeTo(4000, 0.01));
    });

    test('numeroPontas <= 0 → zero sem exceção', () {
      final r = calcularPerdaZonaAtencao(
        percentuais: [103],
        manejoRS: manejo,
        numeroPontas: 0,
        areaHa: area,
      );
      expect(r.perdaEstimada, 0);
      expect(r.qtdPontasNaZona, 0);
    });

    test('manejoRS <= 0 → zero sem exceção', () {
      final r = calcularPerdaZonaAtencao(
        percentuais: [103],
        manejoRS: 0,
        numeroPontas: n,
        areaHa: area,
      );
      expect(r.perdaEstimada, 0);
      expect(r.qtdPontasNaZona, 0);
    });

    test('areaHa <= 0 → zero sem exceção', () {
      final r = calcularPerdaZonaAtencao(
        percentuais: [103],
        manejoRS: manejo,
        numeroPontas: n,
        areaHa: -10,
      );
      expect(r.perdaEstimada, 0);
      expect(r.qtdPontasNaZona, 0);
    });
  });
}
