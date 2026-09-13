import 'dart:io';

import 'package:agrocalc/core/constants/fotos_regulagem_constants.dart';
import 'package:agrocalc/services/fotos_regulagem_service.dart';
import 'package:agrocalc/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tempDir;
  late FotosRegulagemService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('fotos_regulagem_test_');
    service = FotosRegulagemService(diretorioOverride: tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<File> criarImagemGrande({
    required int largura,
    required int altura,
    required String nome,
  }) async {
    final image = img.Image(width: largura, height: altura);
    img.fill(image, color: img.ColorRgb8(120, 80, 40));
    final pngBytes = img.encodePng(image);
    final file = File('${tempDir.path}/$nome');
    await file.writeAsBytes(pngBytes);
    return file;
  }

  test('salvarFoto comprime para no máximo 1600px no lado maior', () async {
    const regulagemId = 'reg-001';
    final original = await criarImagemGrande(
      largura: 2400,
      altura: 1800,
      nome: 'original.png',
    );
    final foto = await service.salvarFoto(original, regulagemId);
    final salva = await service.resolverArquivo(foto);

    expect(await salva.exists(), isTrue);
    expect(foto.arquivo, startsWith('${regulagemId}_'));
    expect(foto.arquivo, endsWith(FotosRegulagemConstants.extensaoArquivo));

    final bytes = await salva.readAsBytes();
    final decodificada = img.decodeImage(bytes);
    expect(decodificada, isNotNull);
    expect(decodificada!.width,
        lessThanOrEqualTo(FotosRegulagemConstants.maxLadoPx));
    expect(decodificada.height,
        lessThanOrEqualTo(FotosRegulagemConstants.maxLadoPx));
    expect(
      decodificada.width > decodificada.height
          ? decodificada.width
          : decodificada.height,
      FotosRegulagemConstants.maxLadoPx,
    );
    expect(bytes.length, greaterThan(0));
  });

  test('removerFoto apaga o arquivo físico do disco', () async {
    const regulagemId = 'reg-002';
    final original = await criarImagemGrande(
      largura: 800,
      altura: 600,
      nome: 'remover.png',
    );

    final foto = await service.salvarFoto(original, regulagemId);
    final arquivo = await service.resolverArquivo(foto);
    expect(await arquivo.exists(), isTrue);

    await service.removerFoto(foto);
    expect(await arquivo.exists(), isFalse);
  });

  test('removerTodasDaRegulagem apaga todas as fotos da regulagem', () async {
    const regulagemId = 'reg-cascade';
    final original1 = await criarImagemGrande(
      largura: 900,
      altura: 700,
      nome: 'cascade-1.png',
    );
    final original2 = await criarImagemGrande(
      largura: 900,
      altura: 700,
      nome: 'cascade-2.png',
    );
    final outraRegulagem = await criarImagemGrande(
      largura: 900,
      altura: 700,
      nome: 'outra.png',
    );

    final foto1 = await service.salvarFoto(original1, regulagemId);
    final foto2 = await service.salvarFoto(original2, regulagemId);
    final fotoOutra = await service.salvarFoto(outraRegulagem, 'reg-outra');

    await service.removerTodasDaRegulagem(regulagemId);

    expect(await (await service.resolverArquivo(foto1)).exists(), isFalse);
    expect(await (await service.resolverArquivo(foto2)).exists(), isFalse);
    expect(await (await service.resolverArquivo(fotoOutra)).exists(), isTrue);
  });

  test('deleteRegulagem no StorageService remove fotos em cascata', () async {
    SharedPreferences.setMockInitialValues({});
    const regulagemId = 'reg-storage-delete';
    final fotosService = FotosRegulagemService(diretorioOverride: tempDir);
    final storage = StorageService(fotosService: fotosService);

    final original = await criarImagemGrande(
      largura: 800,
      altura: 600,
      nome: 'storage-delete.png',
    );
    final foto = await fotosService.salvarFoto(original, regulagemId);
    final arquivo = await fotosService.resolverArquivo(foto);
    expect(await arquivo.exists(), isTrue);

    await storage.deleteRegulagem(regulagemId);
    expect(await arquivo.exists(), isFalse);
  });
}
