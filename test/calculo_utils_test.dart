import 'package:agrocalc/core/utils/calculo_utils.dart';
import 'package:agrocalc/models/configuracoes.dart';
import 'package:agrocalc/models/regulagem.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calcularLitroMinIdeal', () {
    test('calcula exemplo normal do PRD', () {
      final result = CalcUtils.calcularLitroMinIdeal(
        vazaoLha: 150,
        velocidade: 15,
        espacamentoCm: 50,
      );
      expect(result, 1.875);
    });

    test('retorna zero para vazão zero', () {
      final result = CalcUtils.calcularLitroMinIdeal(
        vazaoLha: 0,
        velocidade: 15,
        espacamentoCm: 50,
      );
      expect(result, 0);
    });

    test('retorna zero para velocidade negativa', () {
      final result = CalcUtils.calcularLitroMinIdeal(
        vazaoLha: 150,
        velocidade: -1,
        espacamentoCm: 50,
      );
      expect(result, 0);
    });

    test('retorna zero para espaçamento zero', () {
      final result = CalcUtils.calcularLitroMinIdeal(
        vazaoLha: 150,
        velocidade: 15,
        espacamentoCm: 0,
      );
      expect(result, 0);
    });
  });

  group('calcularPercentualPonta', () {
    test('calcula percentual normal', () {
      final result = CalcUtils.calcularPercentualPonta(
        valorMedido: 1.875,
        litroMinIdeal: 1.875,
      );
      expect(result, 100);
    });

    test('retorna zero para ideal zero', () {
      final result = CalcUtils.calcularPercentualPonta(
        valorMedido: 1,
        litroMinIdeal: 0,
      );
      expect(result, 0);
    });

    test('retorna zero para valor medido negativo', () {
      final result = CalcUtils.calcularPercentualPonta(
        valorMedido: -1,
        litroMinIdeal: 1.875,
      );
      expect(result, 0);
    });

    test('calcula ponta com desgaste', () {
      final result = CalcUtils.calcularPercentualPonta(
        valorMedido: 2.0625,
        litroMinIdeal: 1.875,
      );
      expect(result, closeTo(110, 0.000001));
    });
  });

  group('classificarPonta', () {
    const config = Configuracoes();

    test('valor nulo fica pendente', () {
      final result = CalcUtils.classificarPonta(
        valorMedido: null,
        litroMinIdeal: 2.25,
        configuracoes: config,
      );
      expect(result, StatusPonta.pendente);
    });

    test('medição zero fica irregular quando existe ideal válido', () {
      final result = CalcUtils.classificarPonta(
        valorMedido: 0,
        litroMinIdeal: 2.25,
        configuracoes: config,
      );
      expect(result, StatusPonta.irregular);
    });

    test('105% exato ainda é ideal', () {
      final result = CalcUtils.classificarPonta(
        valorMedido: 2.3625,
        litroMinIdeal: 2.25,
        configuracoes: config,
      );
      expect(result, StatusPonta.ideal);
    });

    test('acima de 105% é desgaste', () {
      final result = CalcUtils.classificarPonta(
        valorMedido: 2.40,
        litroMinIdeal: 2.25,
        configuracoes: config,
      );
      expect(result, StatusPonta.desgaste);
    });
  });

  group('tolerancia', () {
    const config = Configuracoes();

    test('103% entra entre tolerâncias e acima min', () {
      final result = CalcUtils.verificarTolerancia(
        percentual: 103,
        configuracoes: config,
      );
      expect(result.entreTolerancias, isTrue);
      expect(result.acimaToleranciaMin, isTrue);
    });

    test('107% só entra acima min', () {
      final result = CalcUtils.verificarTolerancia(
        percentual: 107,
        configuracoes: config,
      );
      expect(result.entreTolerancias, isFalse);
      expect(result.acimaToleranciaMin, isTrue);
    });

    test('agrega entre tolerâncias e acima min', () {
      final result = CalcUtils.agregarTolerancia(
        percentuais: [88, 100, 101.5, 103, 107],
        configuracoes: config,
      );
      expect(result.entreTolerancias, 2);
      expect(result.acimaToleranciaMin, 3);
    });
  });

  group('calcularPerdaEstimada', () {
    test('calcula perda com desgaste', () {
      final result = CalcUtils.calcularPerdaEstimada(
        percentual: 110,
        manejoRS: 200,
        numeroPontas: 20,
        areaHa: 100,
      );
      expect(result, 100);
    });

    test('retorna zero sem desgaste', () {
      final result = CalcUtils.calcularPerdaEstimada(
        percentual: 100,
        manejoRS: 200,
        numeroPontas: 20,
        areaHa: 100,
      );
      expect(result, 0);
    });

    test('retorna zero com área zero', () {
      final result = CalcUtils.calcularPerdaEstimada(
        percentual: 110,
        manejoRS: 200,
        numeroPontas: 20,
        areaHa: 0,
      );
      expect(result, 0);
    });

    test('retorna zero com manejo zero', () {
      final result = CalcUtils.calcularPerdaEstimada(
        percentual: 110,
        manejoRS: 0,
        numeroPontas: 20,
        areaHa: 100,
      );
      expect(result, 0);
    });

    test('retorna zero com número de pontas zero', () {
      final result = CalcUtils.calcularPerdaEstimada(
        percentual: 110,
        manejoRS: 200,
        numeroPontas: 0,
        areaHa: 100,
      );
      expect(result, 0);
    });
  });

  group('calcularPontaRS', () {
    test('divide manejo pelo número de pontas', () {
      final result = CalcUtils.calcularPontaRS(
        manejoRS: 2400,
        numeroPontas: 24,
      );
      expect(result, 100);
    });

    test('retorna zero para número de pontas inválido', () {
      final result = CalcUtils.calcularPontaRS(
        manejoRS: 2400,
        numeroPontas: 0,
      );
      expect(result, 0);
    });
  });

  group('recomendarTrocaCompleta', () {
    test('recomenda troca completa quando perda supera custo', () {
      final result = CalcUtils.recomendarTrocaCompleta(
        perdaEstimadaTotal: 1000,
        custoTrocaTotal: 800,
      );
      expect(result, isTrue);
    });

    test('recomenda troca completa quando perda empata com custo', () {
      final result = CalcUtils.recomendarTrocaCompleta(
        perdaEstimadaTotal: 800,
        custoTrocaTotal: 800,
      );
      expect(result, isTrue);
    });

    test('recomenda troca seletiva quando perda é menor que custo', () {
      final result = CalcUtils.recomendarTrocaCompleta(
        perdaEstimadaTotal: 700,
        custoTrocaTotal: 800,
      );
      expect(result, isFalse);
    });

    test('retorna falso com custo zero', () {
      final result = CalcUtils.recomendarTrocaCompleta(
        perdaEstimadaTotal: 700,
        custoTrocaTotal: 0,
      );
      expect(result, isFalse);
    });
  });

  group('plantadeira', () {
    test('calcula largura útil', () {
      final result = CalcUtils.calcularLarguraUtil(
        nLinhas: 12,
        espacamentoLinhasM: 0.45,
      );
      expect(result, 5.4);
    });

    test('calcula rendimento operacional', () {
      final result = CalcUtils.calcularRendimentoOperacional(
        larguraUtil: 5.4,
        velocidade: 6,
        eficiencia: 80,
      );
      expect(result, closeTo(2.592, 0.000001));
    });
  });
}
