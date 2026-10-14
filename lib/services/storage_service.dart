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
import '../models/configuracoes.dart';
import '../models/custo_manejo.dart';
import '../models/foto_regulagem.dart';
import '../models/regulagem.dart';
import 'fotos_regulagem_service.dart';
import 'marca_fundo_cabecalho_service.dart';
import 'marca_logo_service.dart';

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
    MarcaLogoService? marcaLogoService,
    MarcaFundoCabecalhoService? marcaFundoCabecalhoService,
  })  : _fotosService = fotosService ?? FotosRegulagemService(),
        _marcaLogoService = marcaLogoService ?? MarcaLogoService(),
        _marcaFundoCabecalhoService =
            marcaFundoCabecalhoService ?? MarcaFundoCabecalhoService();

  final FotosRegulagemService _fotosService;
  final MarcaLogoService _marcaLogoService;
  final MarcaFundoCabecalhoService _marcaFundoCabecalhoService;

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
      await _marcaLogoService.removerLogo();
      await _marcaFundoCabecalhoService.removerFundo();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.regulagensKey);
      await prefs.remove(AppConstants.configuracoesKey);
      await prefs.remove(AppConstants.custosManejoKey);
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

      await _adicionarMarcaPerfilAoZip(archive, backup['configuracoes'] as Map<String, dynamic>);

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
      marcaPorArquivo: const {},
      substituirFotosLocais: false,
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
    final marcaPorArquivo = <String, List<int>>{};
    for (final entry in archive.files) {
      if (!entry.isFile) continue;
      final relativo = _caminhoRelativoNoZip(entry.name);
      if (relativo.startsWith('${FotosRegulagemConstants.pastaFotosBackup}/')) {
        final nome = relativo.split('/').last;
        fotosPorArquivo[nome] = entry.content as List<int>;
        continue;
      }
      if (relativo.startsWith('${FotosRegulagemConstants.pastaMarcaBackup}/')) {
        final nome = relativo.split('/').last;
        marcaPorArquivo[nome] = entry.content as List<int>;
      }
    }

    await _persistBackupImport(
      regulagens: parsed.regulagens,
      configuracoes: parsed.configuracoes,
      fotosPorArquivo: fotosPorArquivo,
      marcaPorArquivo: marcaPorArquivo,
      substituirFotosLocais: true,
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

  Future<void> _adicionarMarcaPerfilAoZip(
    Archive archive,
    Map<String, dynamic> configuracoesJson,
  ) async {
    final config = Configuracoes.fromJson(configuracoesJson);
    if (config.marcaLogoArquivo.trim().isNotEmpty) {
      final bytes = await _marcaLogoService.lerBytes(config.marcaLogoArquivo);
      if (bytes != null) {
        archive.addFile(
          ArchiveFile(
            '${FotosRegulagemConstants.pastaMarcaBackup}/${MarcaLogoService.nomeArquivo}',
            bytes.length,
            bytes,
          ),
        );
      }
    }
    if (config.marcaFundoCabecalhoArquivo.trim().isNotEmpty) {
      final bytes = await _marcaFundoCabecalhoService.lerBytes(
        config.marcaFundoCabecalhoArquivo,
      );
      if (bytes != null) {
        archive.addFile(
          ArchiveFile(
            '${FotosRegulagemConstants.pastaMarcaBackup}/${MarcaFundoCabecalhoService.nomeArquivo}',
            bytes.length,
            bytes,
          ),
        );
      }
    }
  }

  Future<void> _restaurarMarcaPerfilDoBackup(
    Map<String, List<int>> marcaPorArquivo, {
    required bool substituirArquivosLocais,
  }) async {
    if (substituirArquivosLocais) {
      await _marcaLogoService.removerLogo();
      await _marcaFundoCabecalhoService.removerFundo();
    }

    final logoBytes = marcaPorArquivo[MarcaLogoService.nomeArquivo];
    if (logoBytes != null) {
      await _marcaLogoService.gravarBytes(logoBytes);
    }

    final fundoBytes = marcaPorArquivo[MarcaFundoCabecalhoService.nomeArquivo];
    if (fundoBytes != null) {
      await _marcaFundoCabecalhoService.gravarBytes(fundoBytes);
    }
  }

  Future<void> _persistBackupImport({
    required List<Regulagem> regulagens,
    required Configuracoes configuracoes,
    required Map<String, List<int>> fotosPorArquivo,
    required Map<String, List<int>> marcaPorArquivo,
    required bool substituirFotosLocais,
  }) async {
    if (substituirFotosLocais) {
      await _fotosService.removerTodas();
    }
    await _restaurarMarcaPerfilDoBackup(
      marcaPorArquivo,
      substituirArquivosLocais: substituirFotosLocais,
    );

    final regulagensImportadas = <Regulagem>[];
    for (final regulagem in regulagens) {
      final fotosValidas = <FotoRegulagem>[];
      for (final foto in regulagem.fotos) {
        final bytes = fotosPorArquivo[foto.arquivo];
        if (bytes != null) {
          await _fotosService.gravarFotoImportada(bytes, foto);
          fotosValidas.add(foto);
          continue;
        }
        if (!substituirFotosLocais) {
          final arquivo = await _fotosService.resolverArquivo(foto);
          if (await arquivo.exists()) {
            fotosValidas.add(foto);
          }
        }
      }
      regulagensImportadas.add(regulagem.copyWith(fotos: fotosValidas));
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AppConstants.regulagensKey,
        jsonEncode(regulagensImportadas.map((item) => item.toJson()).toList()),
      );
      await prefs.setString(
        AppConstants.configuracoesKey,
        jsonEncode(configuracoes.toJson()),
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

  Future<List<CustoManejo>> getCustosManejo() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.custosManejoKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final data = jsonDecode(raw) as List<dynamic>;
      final itens = data
          .map((item) => CustoManejo.fromJson(item as Map<String, dynamic>))
          .toList();
      itens.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
      return itens;
    } catch (error) {
      debugPrint('Custos de manejo corrompidos: $error');
      return [];
    }
  }

  Future<void> saveCustoManejo(CustoManejo custo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lista = await getCustosManejo();
      final index = lista.indexWhere((item) => item.id == custo.id);
      if (index >= 0) {
        lista[index] = custo;
      } else {
        lista.add(custo);
      }
      await prefs.setString(
        AppConstants.custosManejoKey,
        jsonEncode(lista.map((item) => item.toJson()).toList()),
      );
    } catch (error) {
      debugPrint('Erro ao salvar custo de manejo: $error');
      throw const StorageException('Não foi possível salvar o custo de manejo.');
    }
  }

  Future<void> deleteCustoManejo(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lista = await getCustosManejo();
      lista.removeWhere((item) => item.id == id);
      await prefs.setString(
        AppConstants.custosManejoKey,
        jsonEncode(lista.map((item) => item.toJson()).toList()),
      );
    } catch (error) {
      debugPrint('Erro ao excluir custo de manejo: $error');
      throw const StorageException('Não foi possível excluir o custo de manejo.');
    }
  }
}
