import 'dart:io';

import 'package:agrocalc/models/configuracoes.dart';
import 'package:agrocalc/models/foto_regulagem.dart';
import 'package:agrocalc/models/regulagem.dart';
import 'package:agrocalc/services/fotos_regulagem_service.dart';
import 'package:agrocalc/services/regulagem_pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:intl/date_symbol_data_local.dart';

void main() {
  late Directory tempDir;
  late FotosRegulagemService fotosService;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('pt_BR');
    tempDir = await Directory.systemTemp.createTemp('pdf_fotos_test_');
    fotosService = FotosRegulagemService(diretorioOverride: tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<FotoRegulagem> criarFoto({
    required String regulagemId,
    String? titulo,
    String? observacao,
  }) async {
    final image = img.Image(width: 400, height: 300);
    img.fill(image, color: img.ColorRgb8(30, 120, 200));
    final png = File('${tempDir.path}/origem.png');
    await png.writeAsBytes(img.encodePng(image));
    final foto = await fotosService.salvarFoto(png, regulagemId);
    return foto.copyWith(titulo: titulo, observacao: observacao);
  }

  RegulagemPdfData pdfComFotos(List<FotoRegulagem> fotos) {
    return RegulagemPdfData(
      produtor: 'João',
      fazenda: 'Boa Vista',
      maquina: 'Jacto',
      dataRegulagem: DateTime(2026, 9, 13),
      vazaoLha: 150,
      velocidade: 12,
      espacamentoCm: 50,
      numeroPontas: 2,
      litroMinIdeal: 1,
      medicoes: const [
        PontaMedicao(id: 1, valorMedido: 1, status: StatusPonta.ideal),
      ],
      configuracoes: const Configuracoes(),
      manejo: 0,
      precoBico: 0,
      area: 0,
      fotos: fotos,
    );
  }

  test('PDF inclui seção Fotos da Regulagem quando há fotos', () async {
    const regulagemId = 'pdf-fotos';
    final foto1 = await criarFoto(
      regulagemId: regulagemId,
      titulo: 'Bico 1',
      observacao: 'Desgaste visível',
    );
    final foto2 = await criarFoto(regulagemId: regulagemId);

    final bytes = await RegulagemPdfService.generate(
      pdfComFotos([foto1, foto2]),
      fotosService: fotosService,
    );

    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(bytes.length, greaterThan(1000));
  });

  test('PDF omite seção de fotos quando lista está vazia', () async {
    final bytes = await RegulagemPdfService.generate(pdfComFotos(const []));

    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(bytes.length, greaterThan(1000));
  });
}
