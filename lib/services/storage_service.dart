import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../models/configuracoes.dart';
import '../models/regulagem.dart';

class StorageService {
  Future<List<Regulagem>> getRegulagens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(AppConstants.regulagensKey);
      if (raw == null || raw.isEmpty) return [];
      final data = jsonDecode(raw) as List<dynamic>;
      final regulagens = data
          .map((item) => Regulagem.fromJson(item as Map<String, dynamic>))
          .toList();
      regulagens.sort((a, b) => b.dataRegulagem.compareTo(a.dataRegulagem));
      return regulagens;
    } catch (error) {
      debugPrint('Erro ao carregar regulagens: $error');
      return [];
    }
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
      rethrow;
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
      rethrow;
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
      rethrow;
    }
  }

  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.regulagensKey);
      await prefs.remove(AppConstants.configuracoesKey);
    } catch (error) {
      debugPrint('Erro ao limpar dados: $error');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> buildBackupJson() async {
    final regulagens = await getRegulagens();
    final configuracoes = await getConfiguracoes();
    return {
      'app': AppConstants.appName,
      'version': AppConstants.appVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'regulagens': regulagens.map((item) => item.toJson()).toList(),
      'configuracoes': configuracoes.toJson(),
    };
  }

  Future<void> exportBackup() async {
    try {
      final backup = await buildBackupJson();
      final dir = await getTemporaryDirectory();
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final file = File('${dir.path}/agro_backup_$date.json');
      await file
          .writeAsString(const JsonEncoder.withIndent('  ').convert(backup));
      await Share.shareXFiles([XFile(file.path)], text: 'Backup AgroCalc');
    } catch (error) {
      debugPrint('Erro ao exportar backup: $error');
      rethrow;
    }
  }

  Future<void> importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) return;
      final raw = await File(result.files.single.path!).readAsString();
      await importBackupFromString(raw);
    } catch (error) {
      debugPrint('Erro ao importar backup: $error');
      rethrow;
    }
  }

  Future<void> importBackupFromString(String raw) async {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final regulagens = (data['regulagens'] as List<dynamic>)
          .map((item) => Regulagem.fromJson(item as Map<String, dynamic>))
          .toList();
      final configuracoes = Configuracoes.fromJson(
        data['configuracoes'] as Map<String, dynamic>,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AppConstants.regulagensKey,
        jsonEncode(regulagens.map((item) => item.toJson()).toList()),
      );
      await prefs.setString(
        AppConstants.configuracoesKey,
        jsonEncode(configuracoes.toJson()),
      );
    } catch (error) {
      debugPrint('Backup inválido: $error');
      throw FormatException('Backup inválido: $error');
    }
  }
}
