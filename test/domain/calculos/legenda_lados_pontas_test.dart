import 'package:agrocalc/domain/calculos/texto_pontas.dart';
import 'package:agrocalc/models/regulagem.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('10 pontas só direita: legenda só D', () {
    expect(
      legendaLadosPontasLaudo(
        numeroPontas: 10,
        ladoConferencia: LadoConferenciaPontas.direita,
      ),
      'D = lado direito',
    );
  });

  test('30 pontas: legenda D e E', () {
    final legenda = legendaLadosPontasLaudo(
      numeroPontas: 30,
      ladoConferencia: LadoConferenciaPontas.direita,
    );
    expect(legenda, contains('D = lado direito'));
    expect(legenda, contains('E = lado esquerdo'));
  });
}
