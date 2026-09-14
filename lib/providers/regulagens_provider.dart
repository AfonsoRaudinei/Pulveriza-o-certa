import 'package:flutter/foundation.dart';

import '../models/regulagem.dart';
import '../services/storage_service.dart';
import 'configuracoes_provider.dart';

class RegulagensProvider extends ChangeNotifier {
  RegulagensProvider({
    StorageService? storage,
    ConfiguracoesProvider? configuracoesProvider,
  })  : _storage = storage ?? StorageService(),
        _configuracoesProvider = configuracoesProvider;

  final StorageService _storage;
  ConfiguracoesProvider? _configuracoesProvider;

  void bindConfiguracoes(ConfiguracoesProvider provider) {
    _configuracoesProvider = provider;
  }

  List<Regulagem> _regulagens = [];
  bool _loading = false;

  List<Regulagem> get regulagens => List.unmodifiable(_regulagens);
  bool get loading => _loading;

  Future<void> load() async {
    try {
      _loading = true;
      notifyListeners();
      _regulagens = await _storage.getRegulagens();
    } catch (error) {
      debugPrint('Erro no provider de regulagens: $error');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> save(Regulagem regulagem) async {
    try {
      final existia = _regulagens.any((item) => item.id == regulagem.id);
      await _storage.saveRegulagem(regulagem);
      await load();
      if (!existia) {
        await _configuracoesProvider?.registrarRegulagemSalva();
      }
    } catch (error) {
      debugPrint('Erro ao salvar provider de regulagens: $error');
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _storage.deleteRegulagem(id);
      await load();
    } catch (error) {
      debugPrint('Erro ao excluir provider de regulagens: $error');
      rethrow;
    }
  }
}
