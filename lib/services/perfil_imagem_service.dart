import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../core/constants/perfil_imagem_constants.dart';

enum TipoImagemPerfil { logo, assinatura }

/// Persistência de logo e assinatura no disco (Documents/perfil_relatorio).
class PerfilImagemService {
  PerfilImagemService({Directory? diretorioOverride})
      : _diretorioOverride = diretorioOverride;

  final Directory? _diretorioOverride;

  Future<Directory> _diretorio() async {
    if (_diretorioOverride != null) {
      if (!_diretorioOverride!.existsSync()) {
        _diretorioOverride!.createSync(recursive: true);
      }
      return _diretorioOverride!;
    }
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(
      '${docs.path}/${PerfilImagemConstants.pastaPerfil}',
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> salvarImagem(File original, TipoImagemPerfil tipo) async {
    final dir = await _diretorio();
    final nome = '${tipo.name}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final destino = File('${dir.path}/$nome');
    final bytes = await _comprimir(original);
    await destino.writeAsBytes(bytes);
    return destino.path;
  }

  Future<void> removerImagem(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> removerTodas() async {
    final dir = await _diretorio();
    if (!await dir.exists()) return;
    await for (final entity in dir.list()) {
      if (entity is File) {
        await entity.delete();
      }
    }
  }

  Future<List<int>> _comprimir(File original) async {
    try {
      final raw = await original.readAsBytes();
      final decoded = img.decodeImage(raw);
      if (decoded == null) return raw;

      const maxLado = PerfilImagemConstants.maxLadoPx;
      img.Image redimensionada = decoded;
      if (decoded.width > maxLado || decoded.height > maxLado) {
        redimensionada = img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? maxLado : null,
          height: decoded.height > decoded.width ? maxLado : null,
        );
      }

      return img.encodeJpg(
        redimensionada,
        quality: PerfilImagemConstants.qualidadeJpeg,
      );
    } catch (error) {
      debugPrint('Erro ao comprimir imagem de perfil: $error');
      return original.readAsBytes();
    }
  }
}
