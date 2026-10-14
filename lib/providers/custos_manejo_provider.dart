import 'package:flutter/foundation.dart';

import '../models/custo_manejo.dart';
import '../services/storage_service.dart';

class CustosManejoProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();

  List<CustoManejo> _custos = [];
  bool _loading = false;

  List<CustoManejo> get custos => List.unmodifiable(_custos);
  bool get loading => _loading;

  Future<void> load() async {
    try {
      _loading = true;
      notifyListeners();
      _custos = await _storage.getCustosManejo();
    } catch (error) {
      debugPrint('Erro no provider de custos de manejo: $error');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> save(CustoManejo custo) async {
    try {
      await _storage.saveCustoManejo(custo);
      await load();
    } catch (error) {
      debugPrint('Erro ao salvar custo de manejo: $error');
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _storage.deleteCustoManejo(id);
      await load();
    } catch (error) {
      debugPrint('Erro ao excluir custo de manejo: $error');
      rethrow;
    }
  }
}
