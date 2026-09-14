import 'package:flutter/foundation.dart';

import '../models/configuracoes.dart';
import '../models/lembretes_config.dart';
import '../models/perfil_relatorio.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

class ConfiguracoesProvider extends ChangeNotifier {
  ConfiguracoesProvider({
    StorageService? storage,
    NotificationService? notifications,
  })  : _storage = storage ?? StorageService(),
        _notifications = notifications ?? NotificationService.instance;

  final StorageService _storage;
  final NotificationService _notifications;

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

  Future<void> saveTema(TemaApp tema) {
    return save(_configuracoes.copyWith(tema: tema));
  }

  Future<void> saveLimites({
    double? limiteDesgaste,
    double? limiteIrregular,
  }) {
    return save(
      _configuracoes.copyWith(
        limiteDesgaste: limiteDesgaste,
        limiteIrregular: limiteIrregular,
      ),
    );
  }

  Future<void> savePerfilRelatorio(PerfilRelatorio perfil) {
    return save(_configuracoes.copyWith(perfilRelatorio: perfil));
  }

  Future<void> saveLembretes(LembretesConfig lembretes) async {
    try {
      final sincronizado = await _notifications.sincronizarLembretes(lembretes);
      await save(_configuracoes.copyWith(lembretes: sincronizado));
    } catch (error) {
      debugPrint('Lembretes locais indisponíveis neste ambiente: $error');
      await save(_configuracoes.copyWith(lembretes: lembretes));
    }
  }

  Future<bool> ativarLembretesRevisao(bool ativo) async {
    if (ativo) {
      final granted = await _notifications.solicitarPermissao();
      if (!granted) return false;
    }
    final lembretes = _configuracoes.lembretes.copyWith(revisaoAtivo: ativo);
    await saveLembretes(lembretes);
    return true;
  }

  Future<bool> ativarLembreteBackup(bool ativo) async {
    if (ativo) {
      final granted = await _notifications.solicitarPermissao();
      if (!granted) return false;
    }
    final lembretes =
        _configuracoes.lembretes.copyWith(lembreteBackupAtivo: ativo);
    await saveLembretes(lembretes);
    return true;
  }

  Future<void> registrarUltimoBackup() async {
    await save(_configuracoes.copyWith(ultimoBackup: DateTime.now()));
  }

  /// Incrementa contador de regulagens salvas e dispara lembrete por uso, se aplicável.
  Future<void> registrarRegulagemSalva() async {
    final lembretes = _configuracoes.lembretes;
    if (!lembretes.revisaoAtivo || lembretes.criterio != CriterioLembrete.uso) {
      return;
    }

    final novoContador = lembretes.regulagensDesdeUltimoLembrete + 1;
    if (novoContador >= lembretes.intervaloRegulagens) {
      await _notifications.notificarRevisaoPorUso();
      await saveLembretes(
        lembretes.copyWith(regulagensDesdeUltimoLembrete: 0),
      );
    } else {
      await saveLembretes(
        lembretes.copyWith(regulagensDesdeUltimoLembrete: novoContador),
      );
    }
  }
}
