import 'package:flutter/foundation.dart';

import '../domain/ordem_aplicacao/ordem_aplicacao.dart';
import '../services/storage_service.dart';

class OrdensAplicacaoProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();

  List<OrdemAplicacao> _ordens = [];
  bool _loading = false;

  List<OrdemAplicacao> get ordens => List.unmodifiable(_ordens);
  bool get loading => _loading;

  Future<void> load() async {
    try {
      _loading = true;
      notifyListeners();
      _ordens = await _storage.getOrdensAplicacao();
    } catch (error) {
      debugPrint('Erro no provider de ordens: $error');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> save(OrdemAplicacao ordem) async {
    try {
      await _storage.saveOrdemAplicacao(ordem);
      await load();
    } catch (error) {
      debugPrint('Erro ao salvar ordem no provider: $error');
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _storage.deleteOrdemAplicacao(id);
      await load();
    } catch (error) {
      debugPrint('Erro ao excluir ordem no provider: $error');
      rethrow;
    }
  }
}
