import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Imagem de fundo da faixa do cabeçalho do laudo (um arquivo por app).
class MarcaFundoCabecalhoService {
  MarcaFundoCabecalhoService({Directory? diretorioOverride})
      : _diretorioOverride = diretorioOverride;

  static const pasta = 'marca_perfil';
  static const nomeArquivo = 'fundo_cabecalho.jpg';
  static const _maxLadoPx = 1200;
  static const _qualidadeJpeg = 80;

  final Directory? _diretorioOverride;

  Future<Directory> _diretorio() async {
    if (_diretorioOverride != null) {
      if (!_diretorioOverride!.existsSync()) {
        _diretorioOverride!.createSync(recursive: true);
      }
      return _diretorioOverride!;
    }
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$pasta');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _arquivo() async {
    final dir = await _diretorio();
    return File('${dir.path}/$nomeArquivo');
  }

  Future<String> salvarFundo(File original) async {
    final bytes = await _comprimir(original);
    await gravarBytes(bytes);
    return nomeArquivo;
  }

  /// Grava bytes já comprimidos (ex.: restauração de backup).
  Future<void> gravarBytes(List<int> bytes) async {
    final destino = await _arquivo();
    await destino.writeAsBytes(bytes);
  }

  Future<void> removerFundo() async {
    final file = await _arquivo();
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<Uint8List?> lerBytes(String marcaFundoArquivo) async {
    if (marcaFundoArquivo.trim().isEmpty) return null;
    final file = await _arquivo();
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  Future<File?> arquivoExistente(String marcaFundoArquivo) async {
    if (marcaFundoArquivo.trim().isEmpty) return null;
    final file = await _arquivo();
    if (!await file.exists()) return null;
    return file;
  }

  Future<List<int>> _comprimir(File original) async {
    final raw = await original.readAsBytes();
    final decoded = img.decodeImage(raw);
    if (decoded == null) {
      debugPrint('Fundo do cabeçalho inválido: ${original.path}');
      throw StateError('Imagem inválida ou formato não suportado.');
    }

    final resized = _redimensionar(decoded);
    return img.encodeJpg(resized, quality: _qualidadeJpeg);
  }

  img.Image _redimensionar(img.Image image) {
    final largura = image.width;
    final altura = image.height;
    final maiorLado = largura > altura ? largura : altura;

    if (maiorLado <= _maxLadoPx) {
      return image;
    }

    if (largura >= altura) {
      return img.copyResize(image, width: _maxLadoPx);
    }
    return img.copyResize(image, height: _maxLadoPx);
  }
}
