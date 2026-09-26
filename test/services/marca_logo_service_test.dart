import 'dart:io';

import 'package:agrocalc/services/marca_logo_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('salvar e ler logo comprimido', () async {
    final temp = await Directory.systemTemp.createTemp('marca_logo_test');
    final service = MarcaLogoService(diretorioOverride: temp);

    final source = File('${temp.path}/source.png');
    final image = img.Image(width: 400, height: 200);
    await source.writeAsBytes(img.encodePng(image));

    final nome = await service.salvarLogo(source);
    expect(nome, MarcaLogoService.nomeArquivo);

    final bytes = await service.lerBytes(nome);
    expect(bytes, isNotNull);
    expect(bytes!.length, greaterThan(100));

    await service.removerLogo();
    expect(await service.lerBytes(nome), isNull);

    await temp.delete(recursive: true);
  });
}
