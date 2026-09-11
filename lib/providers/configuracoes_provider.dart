import 'package:flutter/foundation.dart';

import '../models/configuracoes.dart';
import '../services/storage_service.dart';

class ConfiguracoesProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();

  Configuracoes _configuracoes = const Configuracoes();
  bool _loading = false;

  Configuracoes get configuracoes => _configuracoes;
  bool get loading => _loading;

  Future<void> load() async {
    try {
      _loading = true;
      notifyListeners();
      _configuracoes = await _storage.getConfiguracoes();
    } catch (error) {
      debugPrint('Erro no provider de configurações: $error');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> save(Configuracoes configuracoes) async {
    try {
      await _storage.saveConfiguracoes(configuracoes);
      _configuracoes = configuracoes;
      notifyListeners();
    } catch (error) {
      debugPrint('Erro ao salvar provider de configurações: $error');
      rethrow;
    }
  }
}
