import 'dart:io';
import 'dart:typed_data';

import 'package:agrocalc/models/configuracoes.dart';
import 'package:agrocalc/models/marca_pdf.dart';
import 'package:agrocalc/models/regulagem.dart';
import 'package:agrocalc/models/tipo_cabecalho_laudo.dart';
import 'package:agrocalc/services/regulagem_pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:intl/date_symbol_data_local.dart';

RegulagemPdfData _base(Configuracoes configuracoes, {Uint8List? fundo}) {
  return RegulagemPdfData(
    produtor: 'Produtor Audit',
    fazenda: 'Fazenda Audit',
    maquina: 'Pulverizador Teste',
    dataRegulagem: DateTime(2026, 3, 20),
    vazaoLha: 120,
    velocidade: 12,
    espacamentoCm: 50,
    numeroPontas: 2,
    litroMinIdeal: 1,
    medicoes: const [
      PontaMedicao(id: 1, valorMedido: 1, status: StatusPonta.ideal),
      PontaMedicao(id: 2, valorMedido: 1, status: StatusPonta.ideal),
    ],
    configuracoes: configuracoes,
    manejo: 0,
    precoBico: 0,
    area: 10,
    marcaFundoCabecalhoBytes: fundo,
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('pt_BR');
  });

  test('exporta PDFs de auditoria dos 3 modos de cabeçalho', () async {
    final dir = Directory('build/audit_cabecalho');
    if (!dir.existsSync()) dir.createSync(recursive: true);

    final solida = await RegulagemPdfService.generate(
      _base(
        const Configuracoes(
          empresaNome: 'Agro Audit Sólida',
          corMarcaPdf: CorMarcaPdf.azul,
        ),
      ),
    );
    await File('${dir.path}/cabecalho_solida.pdf').writeAsBytes(solida);

    final gradiente = await RegulagemPdfService.generate(
      _base(
        const Configuracoes(
          empresaNome: 'Agro Audit Gradiente',
          tipoCabecalhoLaudo: TipoCabecalhoLaudo.gradiente,
          corMarcaGradienteInicioPdf: CorMarcaPdf.azul,
          corMarcaGradienteFimPdf: CorMarcaPdf.verde,
        ),
      ),
    );
    await File('${dir.path}/cabecalho_gradiente.pdf').writeAsBytes(gradiente);

    final image = img.Image(width: 800, height: 400);
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        image.setPixel(x, y, img.ColorRgb8(x % 256, y % 256, (x + y) % 256));
      }
    }
    final fundoJpeg = Uint8List.fromList(img.encodeJpg(image, quality: 80));

    final imagem = await RegulagemPdfService.generate(
      _base(
        const Configuracoes(
          empresaNome: 'Agro Audit Imagem',
          tipoCabecalhoLaudo: TipoCabecalhoLaudo.imagem,
          marcaFundoCabecalhoArquivo: 'fundo_cabecalho.jpg',
        ),
        fundo: fundoJpeg,
      ),
    );
    await File('${dir.path}/cabecalho_imagem.pdf').writeAsBytes(imagem);

    expect(solida.length, greaterThan(1000));
    expect(gradiente.length, greaterThan(1000));
    expect(imagem.length, greaterThan(1000));
    expect(fundoJpeg.length, lessThan(800 * 400 * 3));
  });
}
