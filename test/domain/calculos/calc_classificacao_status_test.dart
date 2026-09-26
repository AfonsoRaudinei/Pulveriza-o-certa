import 'package:agrocalc/domain/calculos/calc_classificacao_status.dart';
import 'package:agrocalc/domain/calculos/limites_regulagem.dart';
import 'package:agrocalc/models/regulagem.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('classificarPonta', () {
    const padrao = LimitesRegulagem.padrao;
    const limites100 = LimitesRegulagem(
      limiteEntupido: 100,
      limiteDesgaste: 105,
    );

    test('null fica pendente e zero medido fica irregular', () {
      expect(
        classificarPonta(
          valorMedido: null,
          litroMinIdeal: 2.25,
          limites: padrao,
        ),
        StatusPonta.pendente,
      );
      expect(
        classificarPonta(
          valorMedido: 0,
          litroMinIdeal: 2.25,
          limites: padrao,
        ),
        StatusPonta.irregular,
      );
    });

    test('zona de atenção entre 100% e o limite de desgaste', () {
      expect(
        classificarPonta(
          valorMedido: 2.25,
          litroMinIdeal: 2.25,
          limites: padrao,
        ),
        StatusPonta.ideal,
      );
      expect(
        classificarPonta(
          valorMedido: 2.3175,
          litroMinIdeal: 2.25,
          limites: padrao,
        ),
        StatusPonta.atencao,
      );
      expect(
        classificarPonta(
          valorMedido: 2.16,
          litroMinIdeal: 2.25,
          limites: padrao,
        ),
        StatusPonta.irregular,
      );
    });

    test('105% exato é atenção e acima é desgaste', () {
      expect(
        classificarPonta(
          valorMedido: 2.3625,
          litroMinIdeal: 2.25,
          limites: padrao,
        ),
        StatusPonta.atencao,
      );
      expect(
        classificarPonta(
          valorMedido: 2.40,
          litroMinIdeal: 2.25,
          limites: padrao,
        ),
        StatusPonta.desgaste,
      );
    });

    test('limites editáveis de entupido e desgaste', () {
      const custom = LimitesRegulagem(
        limiteEntupido: 90,
        limiteDesgaste: 110,
      );
      expect(
        classificarPonta(
          valorMedido: 2.09,
          litroMinIdeal: 2.25,
          limites: limites100,
        ),
        StatusPonta.irregular,
      );
      expect(
        classificarPonta(
          valorMedido: 2.09,
          litroMinIdeal: 2.25,
          limites: custom,
        ),
        StatusPonta.ideal,
      );
      expect(
        classificarPonta(
          valorMedido: 2.41,
          litroMinIdeal: 2.25,
          limites: padrao,
        ),
        StatusPonta.desgaste,
      );
      expect(
        classificarPonta(
          valorMedido: 2.41,
          litroMinIdeal: 2.25,
          limites: custom,
        ),
        StatusPonta.atencao,
      );
    });
  });

  group('validarLimitesRegulagem', () {
    test('bloqueia entupida acima de 100 ou desgaste abaixo de 100', () {
      expect(
        validarLimitesRegulagem(limiteEntupido: 101, limiteDesgaste: 105)
            .valido,
        isFalse,
      );
      expect(
        validarLimitesRegulagem(limiteEntupido: 97, limiteDesgaste: 99).valido,
        isFalse,
      );
      expect(
        validarLimitesRegulagem(limiteEntupido: 97, limiteDesgaste: 105).valido,
        isTrue,
      );
      expect(
        validarLimitesRegulagem(limiteEntupido: 100, limiteDesgaste: 100)
            .valido,
        isTrue,
      );
    });
  });
}
