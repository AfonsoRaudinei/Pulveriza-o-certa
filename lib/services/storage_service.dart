import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Rect;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../domain/ordem_aplicacao/ordem_aplicacao.dart';
import '../models/cadastro_local.dart';
import '../models/configuracoes.dart';
import '../models/regulagem.dart';

/// Erro de leitura/gravação do armazenamento local, com mensagem apresentável
/// ao usuário.
class StorageException implements Exception {
  const StorageException(this.message);
  final String message;
  @override
  String toString() => message;
}

class StorageService {
  /// Lê a lista de regulagens do disco.
  ///
  /// Se o conteúdo gravado estiver corrompido (JSON inválido ou registro
  /// malformado), o blob original é preservado numa chave de quarentena
  /// (`agro_regulagens_corrompido_<timestamp>`) e a leitura retorna uma lista
  /// vazia — os dados NÃO são perdidos e podem ser recuperados depois.
  Future<List<Regulagem>> getRegulagens() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.regulagensKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return _parseRegulagens(raw);
    } catch (error) {
      debugPrint('Regulagens corrompidas, movendo para quarentena: $error');
      await _quarantine(prefs, raw);
      return [];
    }
  }

  List<Regulagem> _parseRegulagens(String raw) {
    final data = jsonDecode(raw) as List<dynamic>;
    final regulagens = data
        .map((item) => Regulagem.fromJson(item as Map<String, dynamic>))
        .toList();
    regulagens.sort((a, b) => b.dataRegulagem.compareTo(a.dataRegulagem));
    return regulagens;
  }

  Future<void> _quarantine(SharedPreferences prefs, String raw) async {
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    await prefs.setString(
      '${AppConstants.regulagensKey}_corrompido_$stamp',
      raw,
    );
    // Remove a chave principal para o app voltar a funcionar; a cópia acima
    // mantém o dado íntegro para recuperação.
    await prefs.remove(AppConstants.regulagensKey);
  }

  /// Indica se existe pelo menos um blob de regulagens em quarentena.
  Future<bool> temDadosEmQuarentena() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getKeys().any(
          (k) => k.startsWith('${AppConstants.regulagensKey}_corrompido_'),
        );
  }

  Future<void> saveRegulagem(Regulagem regulagem) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final regulagens = await getRegulagens();
      final index = regulagens.indexWhere((item) => item.id == regulagem.id);
      if (index >= 0) {
        regulagens[index] = regulagem;
      } else {
        regulagens.add(regulagem);
      }
      await prefs.setString(
        AppConstants.regulagensKey,
        jsonEncode(regulagens.map((item) => item.toJson()).toList()),
      );
    } catch (error) {
      debugPrint('Erro ao salvar regulagem: $error');
      throw const StorageException('Não foi possível salvar a regulagem.');
    }
  }

  Future<void> deleteRegulagem(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final regulagens = await getRegulagens();
      regulagens.removeWhere((item) => item.id == id);
      await prefs.setString(
        AppConstants.regulagensKey,
        jsonEncode(regulagens.map((item) => item.toJson()).toList()),
      );
    } catch (error) {
      debugPrint('Erro ao excluir regulagem: $error');
      throw const StorageException('Não foi possível excluir a regulagem.');
    }
  }

  Future<Configuracoes> getConfiguracoes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(AppConstants.configuracoesKey);
      if (raw == null || raw.isEmpty) return const Configuracoes();
      return Configuracoes.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (error) {
      debugPrint('Erro ao carregar configurações: $error');
      return const Configuracoes();
    }
  }

  Future<void> saveConfiguracoes(Configuracoes configuracoes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AppConstants.configuracoesKey,
        jsonEncode(configuracoes.toJson()),
      );
    } catch (error) {
      debugPrint('Erro ao salvar configurações: $error');
      throw const StorageException('Não foi possível salvar as configurações.');
    }
  }

  Future<List<OrdemAplicacao>> getOrdensAplicacao() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.ordensAplicacaoKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final data = jsonDecode(raw) as List<dynamic>;
      final ordens = data
          .map((item) => OrdemAplicacao.fromJson(item as Map<String, dynamic>))
          .toList();
      ordens.sort((a, b) => b.atualizadoEm.compareTo(a.atualizadoEm));
      return ordens;
    } catch (error) {
      debugPrint('Ordens corrompidas, ignorando blob: $error');
      return [];
    }
  }

  Future<void> saveOrdemAplicacao(OrdemAplicacao ordem) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ordens = await getOrdensAplicacao();
      final index = ordens.indexWhere((item) => item.id == ordem.id);
      if (index >= 0) {
        ordens[index] = ordem;
      } else {
        ordens.add(ordem);
      }
      await prefs.setString(
        AppConstants.ordensAplicacaoKey,
        jsonEncode(ordens.map((item) => item.toJson()).toList()),
      );
    } catch (error) {
      debugPrint('Erro ao salvar ordem: $error');
      throw const StorageException('Não foi possível salvar a ordem.');
    }
  }

  Future<void> deleteOrdemAplicacao(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ordens = await getOrdensAplicacao();
      ordens.removeWhere((item) => item.id == id);
      await prefs.setString(
        AppConstants.ordensAplicacaoKey,
        jsonEncode(ordens.map((item) => item.toJson()).toList()),
      );
    } catch (error) {
      debugPrint('Erro ao excluir ordem: $error');
      throw const StorageException('Não foi possível excluir a ordem.');
    }
  }

  Future<CadastrosLocais> getCadastros() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(AppConstants.cadastrosKey);
      if (raw == null || raw.isEmpty) return const CadastrosLocais();
      return CadastrosLocais.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (error) {
      debugPrint('Erro ao carregar cadastros: $error');
      return const CadastrosLocais();
    }
  }

  Future<void> saveCadastros(CadastrosLocais cadastros) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AppConstants.cadastrosKey,
        jsonEncode(cadastros.toJson()),
      );
    } catch (error) {
      debugPrint('Erro ao salvar cadastros: $error');
      throw const StorageException('Não foi possível salvar os cadastros.');
    }
  }

  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.regulagensKey);
      await prefs.remove(AppConstants.configuracoesKey);
      await prefs.remove(AppConstants.ordensAplicacaoKey);
      await prefs.remove(AppConstants.cadastrosKey);
    } catch (error) {
      debugPrint('Erro ao limpar dados: $error');
      throw const StorageException('Não foi possível apagar os dados.');
    }
  }

  Future<Map<String, dynamic>> buildBackupJson() async {
    final regulagens = await getRegulagens();
    final configuracoes = await getConfiguracoes();
    final ordens = await getOrdensAplicacao();
    final cadastros = await getCadastros();
    return {
      'app': AppConstants.appName,
      'version': AppConstants.appVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'regulagens': regulagens.map((item) => item.toJson()).toList(),
      'configuracoes': configuracoes.toJson(),
      'ordensAplicacao': ordens.map((item) => item.toJson()).toList(),
      'cadastros': cadastros.toJson(),
    };
  }

  /// Exporta o backup via folha de compartilhamento do sistema.
  ///
  /// [sharePositionOrigin] deve ser informado em iPad (âncora do popover); em
  /// iPhone é ignorado.
  Future<void> exportBackup({Rect? sharePositionOrigin}) async {
    try {
      final backup = await buildBackupJson();
      final dir = await getTemporaryDirectory();
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final file = File('${dir.path}/pontaverde_backup_$date.json');
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(backup),
      );
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Backup ${AppConstants.appName}',
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (error) {
      debugPrint('Erro ao exportar backup: $error');
      throw const StorageException('Não foi possível exportar o backup.');
    }
  }

  /// Retorna `false` quando o usuário cancela o seletor de arquivos.
  Future<bool> importBackup() async {
    final String raw;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) return false;
      raw = await File(result.files.single.path!).readAsString();
    } catch (error) {
      debugPrint('Erro ao ler arquivo de backup: $error');
      throw const StorageException('Não foi possível ler o arquivo escolhido.');
    }
    await importBackupFromString(raw);
    return true;
  }

  Future<void> importBackupFromString(String raw) async {
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      throw const StorageException('O arquivo não é um backup válido.');
    }

    final regulagensRaw = data['regulagens'];
    final configuracoesRaw = data['configuracoes'];
    if (regulagensRaw is! List || configuracoesRaw is! Map) {
      throw const StorageException('O arquivo não é um backup do Ponta Verde.');
    }

    final List<Regulagem> regulagens;
    final Configuracoes configuracoes;
    try {
      regulagens = regulagensRaw
          .map((item) => Regulagem.fromJson(item as Map<String, dynamic>))
          .toList();
      configuracoes = Configuracoes.fromJson(
        Map<String, dynamic>.from(configuracoesRaw),
      );
    } catch (error) {
      debugPrint('Backup malformado: $error');
      throw const StorageException(
        'O backup está incompleto ou foi gerado por outra versão.',
      );
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AppConstants.regulagensKey,
        jsonEncode(regulagens.map((item) => item.toJson()).toList()),
      );
      await prefs.setString(
        AppConstants.configuracoesKey,
        jsonEncode(configuracoes.toJson()),
      );
      final ordensRaw = data['ordensAplicacao'];
      if (ordensRaw is List) {
        final ordens = ordensRaw
            .map(
              (item) => OrdemAplicacao.fromJson(item as Map<String, dynamic>),
            )
            .toList();
        await prefs.setString(
          AppConstants.ordensAplicacaoKey,
          jsonEncode(ordens.map((item) => item.toJson()).toList()),
        );
      }
      final cadastrosRaw = data['cadastros'];
      if (cadastrosRaw is Map) {
        final cadastros = CadastrosLocais.fromJson(
          Map<String, dynamic>.from(cadastrosRaw),
        );
        await prefs.setString(
          AppConstants.cadastrosKey,
          jsonEncode(cadastros.toJson()),
        );
      }
    } catch (error) {
      debugPrint('Erro ao gravar backup importado: $error');
      throw const StorageException(
        'Não foi possível gravar o backup importado.',
      );
    }
  }
}
