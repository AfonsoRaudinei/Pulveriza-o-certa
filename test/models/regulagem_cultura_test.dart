import 'package:agrocalc/models/regulagem.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cultura serializa e restaura do JSON', () {
    final json = {
      'id': '1',
      'produtor': 'P',
      'fazenda': 'F',
      'maquina': 'M',
      'tipoOperacao': 'pulverizador',
      'dataRegulagem': '2026-09-26T00:00:00.000',
      'vazaoLha': 80,
      'velocidade': 8,
      'espacamentoCm': 50,
      'numeroPontas': 10,
      'litroMinIdeal': 0.5,
      'medicoes': [],
      'cultura': 'milho',
      'criadoEm': '2026-09-26T00:00:00.000',
      'atualizadoEm': '2026-09-26T00:00:00.000',
    };
    final r = Regulagem.fromJson(json);
    expect(r.cultura, CulturaCultivo.milho);
    expect(r.toJson()['cultura'], 'milho');
  });

  test('regulagem antiga sem cultura', () {
    final json = {
      'id': '1',
      'produtor': 'P',
      'fazenda': 'F',
      'maquina': 'M',
      'tipoOperacao': 'pulverizador',
      'dataRegulagem': '2026-09-26T00:00:00.000',
      'vazaoLha': 80,
      'velocidade': 8,
      'espacamentoCm': 50,
      'numeroPontas': 10,
      'litroMinIdeal': 0.5,
      'medicoes': [],
      'criadoEm': '2026-09-26T00:00:00.000',
      'atualizadoEm': '2026-09-26T00:00:00.000',
    };
    expect(Regulagem.fromJson(json).cultura, isNull);
  });
}
