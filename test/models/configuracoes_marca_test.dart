import 'package:agrocalc/models/configuracoes.dart';
import 'package:agrocalc/models/marca_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('textoMarcaCabecalho prioriza empresa, depois consultor', () {
    expect(
      const Configuracoes(
        empresaNome: 'Agro Norte',
        nomeConsultor: 'Maria',
      ).textoMarcaCabecalho(),
      'Agro Norte',
    );
    expect(
      const Configuracoes(nomeConsultor: 'Maria').textoMarcaCabecalho(),
      'Maria',
    );
    expect(const Configuracoes().textoMarcaCabecalho(), 'Ponta Verde');
  });

  test('marca e CREA no JSON de configuracoes', () {
    const original = Configuracoes(
      empresaNome: 'Fazenda X',
      registroProfissional: 'CREA-SP 12345',
      marcaLogoArquivo: 'logo_marca.jpg',
      corMarcaPdf: CorMarcaPdf.verde,
    );
    final restored = Configuracoes.fromJson(original.toJson());
    expect(restored.empresaNome, 'Fazenda X');
    expect(restored.registroProfissional, 'CREA-SP 12345');
    expect(restored.marcaLogoArquivo, 'logo_marca.jpg');
    expect(restored.corMarcaPdf, CorMarcaPdf.verde);
    expect(restored.toJson(), isNot(contains('toleranciaMin')));
  });
}
