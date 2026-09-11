import 'package:agrocalc/domain/calculos/calc_classificacao_status.dart';
import 'package:agrocalc/models/configuracoes.dart';
import 'package:agrocalc/models/regulagem.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('classificarPonta', () {
    const config = Configuracoes();

    test('null fica pendente e zero medido fica irregular', () {
      expect(
        classificarPonta(
          valorMedido: null,
          litroMinIdeal: 2.25,
          configuracoes: config,
        ),
        StatusPonta.pendente,
      );
      expect(
        classificarPonta(
          valorMedido: 0,
          litroMinIdeal: 2.25,
          configuracoes: config,
        ),
        StatusPonta.irregular,
      );
    });

    test('limite superior e inferior seguem a regra documentada', () {
      expect(
        classificarPonta(
          valorMedido: 2.25,
          litroMinIdeal: 2.25,
          configuracoes: config,
        ),
        StatusPonta.ideal,
      );
      expect(
        classificarPonta(
          valorMedido: 2.40,
          litroMinIdeal: 2.25,
          configuracoes: config,
        ),
        StatusPonta.desgaste,
      );
    });

    test('limites editáveis de entupido e desgaste', () {
      const custom = Configuracoes(
        limiteIrregular: 90,
        limiteDesgaste: 110,
      );
      // 2.09 / 2.25 ≈ 92,9%: Entupido no padrão 100, Ideal com limite 90.
      expect(
        classificarPonta(
          valorMedido: 2.09,
          litroMinIdeal: 2.25,
          configuracoes: config,
        ),
        StatusPonta.irregular,
      );
      expect(
        classificarPonta(
          valorMedido: 2.09,
          litroMinIdeal: 2.25,
          configuracoes: custom,
        ),
        StatusPonta.ideal,
      );
      // 2.41 / 2.25 ≈ 107,1%: Desgaste no padrão 105, Ideal com limite 110.
      expect(
        classificarPonta(
          valorMedido: 2.41,
          litroMinIdeal: 2.25,
          configuracoes: config,
        ),
        StatusPonta.desgaste,
      );
      expect(
        classificarPonta(
          valorMedido: 2.41,
          litroMinIdeal: 2.25,
          configuracoes: custom,
        ),
        StatusPonta.ideal,
      );
      expect(
        classificarPonta(
          valorMedido: 2.00,
          litroMinIdeal: 2.25,
          configuracoes: custom,
        ),
        StatusPonta.irregular,
      );
      expect(
        classificarPonta(
          valorMedido: 2.48,
          litroMinIdeal: 2.25,
          configuracoes: custom,
        ),
        StatusPonta.desgaste,
      );
    });
  });
}
