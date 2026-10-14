import 'dart:convert';
import 'dart:io';

import 'package:agrocalc/core/constants/fotos_regulagem_constants.dart';
import 'package:agrocalc/models/configuracoes.dart';
import 'package:agrocalc/services/fotos_regulagem_service.dart';
import 'package:agrocalc/services/marca_fundo_cabecalho_service.dart';
import 'package:agrocalc/services/marca_logo_service.dart';
import 'package:agrocalc/services/storage_service.dart';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('marca_backup_test');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('importBackupFromZipBytes restaura logo e fundo em marca_perfil', () async {
    final logoBytes = List<int>.filled(32, 1);
    final fundoBytes = List<int>.filled(32, 2);

    final config = const Configuracoes(
      marcaLogoArquivo: MarcaLogoService.nomeArquivo,
      marcaFundoCabecalhoArquivo: MarcaFundoCabecalhoService.nomeArquivo,
    );

    final dados = jsonEncode({
      'regulagens': <dynamic>[],
      'configuracoes': config.toJson(),
    });

    final archive = Archive()
      ..addFile(
        ArchiveFile(
          FotosRegulagemConstants.arquivoDadosBackup,
          dados.length,
          utf8.encode(dados),
        ),
      )
      ..addFile(
        ArchiveFile(
          '${FotosRegulagemConstants.pastaMarcaBackup}/${MarcaLogoService.nomeArquivo}',
          logoBytes.length,
          logoBytes,
        ),
      )
      ..addFile(
        ArchiveFile(
          '${FotosRegulagemConstants.pastaMarcaBackup}/${MarcaFundoCabecalhoService.nomeArquivo}',
          fundoBytes.length,
          fundoBytes,
        ),
      );

    final zipBytes = ZipEncoder().encode(archive);
    final marcaLogo = MarcaLogoService(diretorioOverride: tempDir);
    final marcaFundo = MarcaFundoCabecalhoService(diretorioOverride: tempDir);
    final storage = StorageService(
      fotosService: FotosRegulagemService(diretorioOverride: tempDir),
      marcaLogoService: marcaLogo,
      marcaFundoCabecalhoService: marcaFundo,
    );
    await storage.importBackupFromZipBytes(zipBytes);

    final logoLido = await marcaLogo.lerBytes(MarcaLogoService.nomeArquivo);
    final fundoLido =
        await marcaFundo.lerBytes(MarcaFundoCabecalhoService.nomeArquivo);

    expect(logoLido, logoBytes);
    expect(fundoLido, fundoBytes);

    final carregado = await storage.getConfiguracoes();
    expect(carregado.marcaLogoArquivo, MarcaLogoService.nomeArquivo);
    expect(
      carregado.marcaFundoCabecalhoArquivo,
      MarcaFundoCabecalhoService.nomeArquivo,
    );
  });
}
