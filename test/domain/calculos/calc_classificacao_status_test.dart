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
  });
}
