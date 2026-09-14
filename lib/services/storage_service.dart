import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Rect;

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/fotos_regulagem_constants.dart';
import '../core/constants/perfil_imagem_constants.dart';
import '../models/configuracoes.dart';
import '../models/foto_regulagem.dart';
import '../models/regulagem.dart';
import 'fotos_regulagem_service.dart';
import 'perfil_imagem_service.dart';

/// Erro de leitura/gravação do armazenamento local, com mensagem apresentável
/// ao usuário.
class StorageException implements Exception {
  const StorageException(this.message);
  final String message;
  @override
  String toString() => message;
}

class StorageService {
  StorageService({
    FotosRegulagemService? fotosService,
    PerfilImagemService? perfilService,
  })  : _fotosService = fotosService ?? FotosRegulagemService(),
        _perfilService = perfilService ?? PerfilImagemService();

  final FotosRegulagemService _fotosService;
  final PerfilImagemService _perfilService;

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
      await _fotosService.removerTodasDaRegulagem(id);
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

  Future<void> clearAll() async {
    try {
      await _fotosService.removerTodas();
      await _perfilService.removerTodas();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.regulagensKey);
      await prefs.remove(AppConstants.configuracoesKey);
      // Chaves legadas de protótipos removidos.
      await prefs.remove('agro_ordens_aplicacao');
      await prefs.remove('agro_cadastros');
    } catch (error) {
      debugPrint('Erro ao limpar dados: $error');
      throw const StorageException('Não foi possível apagar os dados.');
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

  /// Exporta o backup (.zip) via folha de compartilhamento do sistema.
  ///
  /// [sharePositionOrigin] deve ser informado em iPad (âncora do popover); em
  /// iPhone é ignorado.
  Future<void> exportBackup({Rect? sharePositionOrigin}) async {
    try {
      final backup = await buildBackupJson();
      final jsonBytes = utf8.encode(
        const JsonEncoder.withIndent('  ').convert(backup),
      );

      final archive = Archive();
      archive.addFile(
        ArchiveFile(
          FotosRegulagemConstants.arquivoDadosBackup,
          jsonBytes.length,
          jsonBytes,
        ),
      );

      final configuracoes = await getConfiguracoes();
      final perfil = configuracoes.perfilRelatorio;
      for (final path in [perfil.logoPath, perfil.assinaturaPath]) {
        if (path == null || path.isEmpty) continue;
        final file = File(path);
        if (!await file.exists()) continue;
        final bytes = await file.readAsBytes();
        final nome = path.split('/').last;
        archive.addFile(
          ArchiveFile(
            '${PerfilImagemConstants.pastaPerfilBackup}/$nome',
            bytes.length,
            bytes,
          ),
        );
      }

      final regulagens = await getRegulagens();
      for (final regulagem in regulagens) {
        for (final foto in regulagem.fotos) {
          final file = await _fotosService.resolverArquivo(foto);
          if (!await file.exists()) continue;
          final bytes = await file.readAsBytes();
          archive.addFile(
            ArchiveFile(
              '${FotosRegulagemConstants.pastaFotosBackup}/${foto.arquivo}',
              bytes.length,
              bytes,
            ),
          );
        }
      }

      final zipBytes = ZipEncoder().encode(archive);

      final dir = await getTemporaryDirectory();
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final zipFile = File('${dir.path}/pontaverde_backup_$date.zip');
      await zipFile.writeAsBytes(zipBytes);
      await Share.shareXFiles(
        [XFile(zipFile.path)],
        text: 'Backup ${AppConstants.appName}',
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (error) {
      if (error is StorageException) rethrow;
      debugPrint('Erro ao exportar backup: $error');
      throw const StorageException('Não foi possível exportar o backup.');
    }
  }

  /// Retorna `false` quando o usuário cancela o seletor de arquivos.
  Future<bool> importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip', 'json'],
      );
      if (result == null || result.files.single.path == null) return false;

      final path = result.files.single.path!;
      if (path.toLowerCase().endsWith('.zip')) {
        final bytes = await File(path).readAsBytes();
        await importBackupFromZipBytes(bytes);
      } else {
        final raw = await File(path).readAsString();
        await importBackupFromString(raw);
      }
      return true;
    } catch (error) {
      if (error is StorageException) rethrow;
      debugPrint('Erro ao ler arquivo de backup: $error');
      throw const StorageException('Não foi possível ler o arquivo escolhido.');
    }
  }

  Future<void> importBackupFromString(String raw) async {
    final parsed = _parseBackupPayload(raw);
    await _persistBackupImport(
      regulagens: parsed.regulagens,
      configuracoes: parsed.configuracoes,
      fotosPorArquivo: const {},
    );
  }

  Future<void> importBackupFromZipBytes(List<int> zipBytes) async {
    final archive = ZipDecoder().decodeBytes(zipBytes);
    final dadosFile = _localizarArquivoNoZip(
      archive,
      FotosRegulagemConstants.arquivoDadosBackup,
    );
    if (dadosFile == null) {
      throw const StorageException('O arquivo .zip não contém dados.json.');
    }

    final raw = utf8.decode(dadosFile.content as List<int>);
    final parsed = _parseBackupPayload(raw);

    final fotosPorArquivo = <String, List<int>>{};
    final perfilPorArquivo = <String, List<int>>{};
    for (final entry in archive.files) {
      if (!entry.isFile) continue;
      final relativo = _caminhoRelativoNoZip(entry.name);
      if (relativo.startsWith('${FotosRegulagemConstants.pastaFotosBackup}/')) {
        final nome = relativo.split('/').last;
        fotosPorArquivo[nome] = entry.content as List<int>;
      } else if (relativo
          .startsWith('${PerfilImagemConstants.pastaPerfilBackup}/')) {
        final nome = relativo.split('/').last;
        perfilPorArquivo[nome] = entry.content as List<int>;
      }
    }

    await _persistBackupImport(
      regulagens: parsed.regulagens,
      configuracoes: parsed.configuracoes,
      fotosPorArquivo: fotosPorArquivo,
      perfilPorArquivo: perfilPorArquivo,
    );
  }

  ({
    List<Regulagem> regulagens,
    Configuracoes configuracoes,
  }) _parseBackupPayload(String raw) {
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

    try {
      final regulagens = regulagensRaw
          .map((item) => Regulagem.fromJson(item as Map<String, dynamic>))
          .toList();
      final configuracoes = Configuracoes.fromJson(
        Map<String, dynamic>.from(configuracoesRaw),
      );
      return (regulagens: regulagens, configuracoes: configuracoes);
    } catch (error) {
      debugPrint('Backup malformado: $error');
      throw const StorageException(
        'O backup está incompleto ou foi gerado por outra versão.',
      );
    }
  }

  Future<void> _persistBackupImport({
    required List<Regulagem> regulagens,
    required Configuracoes configuracoes,
    required Map<String, List<int>> fotosPorArquivo,
    Map<String, List<int>> perfilPorArquivo = const {},
  }) async {
    await _fotosService.removerTodas();
    await _perfilService.removerTodas();

    final regulagensImportadas = <Regulagem>[];
    for (final regulagem in regulagens) {
      final fotosValidas = <FotoRegulagem>[];
      for (final foto in regulagem.fotos) {
        final bytes = fotosPorArquivo[foto.arquivo];
        if (bytes == null) continue;
        await _fotosService.gravarFotoImportada(bytes, foto);
        fotosValidas.add(foto);
      }
      regulagensImportadas.add(regulagem.copyWith(fotos: fotosValidas));
    }

    var perfil = configuracoes.perfilRelatorio;
    if (perfil.logoPath != null) {
      final nome = perfil.logoPath!.split('/').last;
      final bytes = perfilPorArquivo[nome];
      if (bytes != null) {
        final path = await _perfilService.gravarImportada(bytes, nome);
        perfil = perfil.copyWith(logoPath: path);
      }
    }
    if (perfil.assinaturaPath != null) {
      final nome = perfil.assinaturaPath!.split('/').last;
      final bytes = perfilPorArquivo[nome];
      if (bytes != null) {
        final path = await _perfilService.gravarImportada(bytes, nome);
        perfil = perfil.copyWith(assinaturaPath: path);
      }
    }
    final configuracoesImportadas =
        configuracoes.copyWith(perfilRelatorio: perfil);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AppConstants.regulagensKey,
        jsonEncode(regulagensImportadas.map((item) => item.toJson()).toList()),
      );
      await prefs.setString(
        AppConstants.configuracoesKey,
        jsonEncode(configuracoesImportadas.toJson()),
      );
    } catch (error) {
      debugPrint('Erro ao gravar backup importado: $error');
      throw const StorageException(
        'Não foi possível gravar o backup importado.',
      );
    }
  }

  ArchiveFile? _localizarArquivoNoZip(Archive archive, String nomeAlvo) {
    for (final file in archive.files) {
      if (!file.isFile) continue;
      if (_caminhoRelativoNoZip(file.name) == nomeAlvo) {
        return file;
      }
    }
    return null;
  }

  String _caminhoRelativoNoZip(String caminho) {
    return caminho.replaceAll('\\', '/');
  }
}
