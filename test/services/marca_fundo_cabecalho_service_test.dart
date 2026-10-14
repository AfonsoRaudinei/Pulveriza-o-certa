import 'dart:io';

import 'package:agrocalc/services/marca_fundo_cabecalho_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('salvarFundo comprime imagem grande para JPEG menor que o original', () async {
    final dir = await Directory.systemTemp.createTemp('pv_fundo_test_');
    final service = MarcaFundoCabecalhoService(diretorioOverride: dir);

    final originalPath = '${dir.path}/original.jpg';
    final image = img.Image(width: 2400, height: 1200);
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        image.setPixel(
          x,
          y,
          img.ColorRgb8((x * 3 + y) % 256, (x + y * 5) % 256, (x * y) % 256),
        );
      }
    }
    await File(originalPath).writeAsBytes(img.encodeJpg(image, quality: 95));
    final originalSize = await File(originalPath).length();

    await service.salvarFundo(File(originalPath));
    final comprimido = await service.lerBytes(MarcaFundoCabecalhoService.nomeArquivo);
    expect(comprimido, isNotNull);
    expect(comprimido!.length, lessThan(originalSize));

    final salvo = img.decodeImage(comprimido);
    expect(salvo, isNotNull);
    expect(salvo!.width, lessThanOrEqualTo(1200));
    expect(salvo.height, lessThanOrEqualTo(1200));

    await dir.delete(recursive: true);
  });
}
