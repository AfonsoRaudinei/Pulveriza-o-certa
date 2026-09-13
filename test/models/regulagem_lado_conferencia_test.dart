import 'package:agrocalc/models/regulagem.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rotuloPonta usa sufixo D ou E', () {
    expect(rotuloPonta(1, LadoConferenciaPontas.direita), '1D');
    expect(rotuloPonta(3, LadoConferenciaPontas.esquerda), '3E');
  });

  test('JSON persiste ladoConferenciaPontas', () {
    final regulagem = Regulagem(
      id: 'x',
      produtor: 'P',
      fazenda: 'F',
      maquina: 'M',
      tipoOperacao: TipoOperacao.pulverizador,
      dataRegulagem: DateTime(2026, 9, 13),
      vazaoLha: 90,
      velocidade: 10,
      espacamentoCm: 50,
      numeroPontas: 2,
      litroMinIdeal: 0.8,
      medicoes: const [],
      ladoConferenciaPontas: LadoConferenciaPontas.esquerda,
      criadoEm: DateTime(2026, 9, 13),
      atualizadoEm: DateTime(2026, 9, 13),
    );

    final json = regulagem.toJson();
    expect(json['ladoConferenciaPontas'], 'esquerda');

    final restaurada = Regulagem.fromJson(json);
    expect(restaurada.ladoConferenciaPontas, LadoConferenciaPontas.esquerda);
  });

  test('JSON antigo sem campo assume direita', () {
    final restaurada = Regulagem.fromJson({
      'id': 'x',
      'produtor': 'P',
      'fazenda': 'F',
      'maquina': 'M',
      'dataRegulagem': '2026-09-13T00:00:00.000',
      'vazaoLha': 90,
      'velocidade': 10,
      'espacamentoCm': 50,
      'numeroPontas': 2,
      'litroMinIdeal': 0.8,
      'medicoes': [],
      'criadoEm': '2026-09-13T00:00:00.000',
      'atualizadoEm': '2026-09-13T00:00:00.000',
    });
    expect(restaurada.ladoConferenciaPontas, LadoConferenciaPontas.direita);
  });
}
