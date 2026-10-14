import 'package:agrocalc/models/configuracoes.dart';
import 'package:agrocalc/models/marca_pdf.dart';
import 'package:agrocalc/models/tipo_cabecalho_laudo.dart';
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

  test('tipo e gradiente do cabeçalho no JSON', () {
    const original = Configuracoes(
      tipoCabecalhoLaudo: TipoCabecalhoLaudo.gradiente,
      corMarcaGradienteInicioPdf: CorMarcaPdf.grafite,
      corMarcaGradienteFimPdf: CorMarcaPdf.vinho,
      marcaFundoCabecalhoArquivo: 'fundo_cabecalho.jpg',
    );
    final restored = Configuracoes.fromJson(original.toJson());
    expect(restored.tipoCabecalhoLaudo, TipoCabecalhoLaudo.gradiente);
    expect(restored.corMarcaGradienteInicioPdf, CorMarcaPdf.grafite);
    expect(restored.corMarcaGradienteFimPdf, CorMarcaPdf.vinho);
    expect(restored.marcaFundoCabecalhoArquivo, 'fundo_cabecalho.jpg');
  });

  test('tipo cabeçalho padrão é cor sólida sem chave no JSON', () {
    final restored = Configuracoes.fromJson(const Configuracoes().toJson());
    expect(restored.tipoCabecalhoLaudo, TipoCabecalhoLaudo.solida);
  });

  test('linhaContatoPerfilLaudo omite vazios e ordena e-mail antes do contato', () {
    expect(const Configuracoes().linhaContatoPerfilLaudo(), isNull);
    expect(
      const Configuracoes(contatoPerfil: '(11) 99999-9999')
          .linhaContatoPerfilLaudo(),
      '(11) 99999-9999',
    );
    expect(
      const Configuracoes(emailPerfil: 'a@b.com').linhaContatoPerfilLaudo(),
      'a@b.com',
    );
    expect(
      const Configuracoes(
        emailPerfil: 'a@b.com',
        contatoPerfil: '(11) 99999-9999',
      ).linhaContatoPerfilLaudo(),
      'a@b.com · (11) 99999-9999',
    );
  });

  test('contato e e-mail persistem no JSON', () {
    const original = Configuracoes(
      contatoPerfil: '(11) 98888-7777',
      emailPerfil: 'consultor@agro.com',
    );
    final restored = Configuracoes.fromJson(original.toJson());
    expect(restored.contatoPerfil, '(11) 98888-7777');
    expect(restored.emailPerfil, 'consultor@agro.com');
  });

  test('fromJson legado sem tipo de cabeçalho nem contato/e-mail', () {
    final restored = Configuracoes.fromJson({
      'limiteDesgaste': 105,
      'limiteIrregular': 97,
      'nomeConsultor': 'Consultor antigo',
      'empresaNome': 'Agro Legado',
      'registroProfissional': 'CREA 1',
      'marcaLogoArquivo': '',
      'corMarcaPdf': 'azul',
      'tema': 'system',
    });
    expect(restored.tipoCabecalhoLaudo, TipoCabecalhoLaudo.solida);
    expect(restored.contatoPerfil, '');
    expect(restored.emailPerfil, '');
    expect(restored.textoMarcaCabecalho(), 'Agro Legado');
    expect(restored.linhaContatoPerfilLaudo(), isNull);
  });

  test('emailPerfilValido aceita vazio e formato básico', () {
    expect(Configuracoes.emailPerfilValido(''), isTrue);
    expect(Configuracoes.emailPerfilValido('user@dominio.com.br'), isTrue);
    expect(Configuracoes.emailPerfilValido('invalido'), isFalse);
    expect(Configuracoes.emailPerfilValido('a@b'), isFalse);
  });
}
