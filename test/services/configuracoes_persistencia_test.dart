import 'package:agrocalc/models/configuracoes.dart';
import 'package:agrocalc/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('contato e e-mail persistem após save/load (equivalente a reabrir o app)', () async {
    const salvo = Configuracoes(
      contatoPerfil: '(11) 98888-7777',
      emailPerfil: 'consultor@agro.com',
    );
    final storage = StorageService();
    await storage.saveConfiguracoes(salvo);

    final carregado = await storage.getConfiguracoes();
    expect(carregado.contatoPerfil, salvo.contatoPerfil);
    expect(carregado.emailPerfil, salvo.emailPerfil);
  });
}
