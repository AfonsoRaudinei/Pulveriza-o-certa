import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;

import '../core/constants/app_constants.dart';

/// Carrega e comprime o logo SoloForte para o rodapé do laudo (uma vez por sessão).
class SoloForteLogoPdfService {
  SoloForteLogoPdfService._();

  /// Altura exibida no rodapé (pt PDF).
  /// Alinhada à altura da linha do texto do rodapé (fonte ~8 pt).
  static const alturaExibicaoPt = 10.0;

  /// Reduz o JPEG para ~2,5× a altura exibida (leve no WhatsApp).
  static const _fatorReducao = 2.5;
  static const _qualidadeJpeg = 82;

  static Uint8List? _cache;

  static Future<Uint8List?> carregarParaPdf() async {
    if (_cache != null) return _cache;
    try {
      final bundle = await rootBundle.load(AppConstants.logoSoloForteAsset);
      final raw = bundle.buffer.asUint8List();
      _cache = _prepararBytes(raw);
      return _cache;
    } catch (e, st) {
      debugPrint('Rodapé PDF: logo SoloForte indisponível ($e)');
      debugPrint('$st');
      return null;
    }
  }

  @visibleForTesting
  static void limparCache() => _cache = null;

  static Uint8List? _prepararBytes(Uint8List raw) {
    final decoded = img.decodeImage(raw);
    if (decoded == null) return null;

    final alvoPx =
        (alturaExibicaoPt * _fatorReducao * 96 / 72).round().clamp(24, 128);
    final maior = decoded.width > decoded.height ? decoded.width : decoded.height;
    if (maior <= alvoPx) {
      return Uint8List.fromList(img.encodeJpg(decoded, quality: _qualidadeJpeg));
    }

    final resized = decoded.width >= decoded.height
        ? img.copyResize(decoded, width: alvoPx)
        : img.copyResize(decoded, height: alvoPx);
    return Uint8List.fromList(img.encodeJpg(resized, quality: _qualidadeJpeg));
  }
}
