import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../core/constants/fotos_regulagem_constants.dart';
import '../models/foto_regulagem.dart';

/// Persistência de fotos de regulagem no disco (Documents/regulagens_fotos).
class FotosRegulagemService {
  FotosRegulagemService({Directory? diretorioOverride})
      : _diretorioOverride = diretorioOverride;

  final Directory? _diretorioOverride;

  Future<Directory> _diretorioFotos() async {
    if (_diretorioOverride != null) {
      if (!_diretorioOverride!.existsSync()) {
        _diretorioOverride!.createSync(recursive: true);
      }
      return _diretorioOverride!;
    }
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(
      '${docs.path}/${FotosRegulagemConstants.pastaFotos}',
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Comprime, grava em disco e retorna o registro [FotoRegulagem] criado.
  Future<FotoRegulagem> salvarFoto(File original, String regulagemId) async {
    final timestamp = DateTime.now();
    final nomeArquivo = _nomeArquivo(regulagemId, timestamp);
    final dir = await _diretorioFotos();
    final destino = File('${dir.path}/$nomeArquivo');

    final bytes = await _comprimir(original);
    await destino.writeAsBytes(bytes);

    return FotoRegulagem(
      arquivo: nomeArquivo,
      timestamp: timestamp,
    );
  }

  Future<void> removerFoto(FotoRegulagem foto) async {
    final file = await resolverArquivo(foto);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<File> resolverArquivo(FotoRegulagem foto) async {
    final dir = await _diretorioFotos();
    return File('${dir.path}/${foto.arquivo}');
  }

  /// Remove todos os arquivos físicos vinculados a uma regulagem.
  Future<void> removerTodasDaRegulagem(String regulagemId) async {
    final dir = await _diretorioFotos();
    if (!await dir.exists()) return;

    final prefixo = '${regulagemId}_';
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final nome = entity.uri.pathSegments.last;
      if (nome.startsWith(prefixo)) {
        await entity.delete();
      }
    }
  }

  /// Remove todos os arquivos do diretório de fotos (ex.: import ou limpar dados).
  Future<void> removerTodas() async {
    final dir = await _diretorioFotos();
    if (!await dir.exists()) return;

    await for (final entity in dir.list()) {
      if (entity is File) {
        await entity.delete();
      }
    }
  }

  /// Grava bytes de uma foto importada de backup usando o nome do registro.
  Future<void> gravarFotoImportada(List<int> bytes, FotoRegulagem foto) async {
    final dir = await _diretorioFotos();
    final destino = File('${dir.path}/${foto.arquivo}');
    await destino.writeAsBytes(bytes);
  }

  String _nomeArquivo(String regulagemId, DateTime timestamp) {
    final stamp = timestamp.toIso8601String().replaceAll(':', '-');
    return '${regulagemId}_$stamp${FotosRegulagemConstants.extensaoArquivo}';
  }

  Future<List<int>> _comprimir(File original) async {
    final raw = await original.readAsBytes();
    final decoded = img.decodeImage(raw);
    if (decoded == null) {
      debugPrint('Foto inválida: ${original.path}');
      throw StateError('Imagem inválida ou formato não suportado.');
    }

    final resized = _redimensionar(decoded);
    return img.encodeJpg(
      resized,
      quality: FotosRegulagemConstants.qualidadeJpeg,
    );
  }

  img.Image _redimensionar(img.Image image) {
    const maxLado = FotosRegulagemConstants.maxLadoPx;
    final largura = image.width;
    final altura = image.height;
    final maiorLado = largura > altura ? largura : altura;

    if (maiorLado <= maxLado) {
      return image;
    }

    if (largura >= altura) {
      return img.copyResize(image, width: maxLado);
    }
    return img.copyResize(image, height: maxLado);
  }
}
