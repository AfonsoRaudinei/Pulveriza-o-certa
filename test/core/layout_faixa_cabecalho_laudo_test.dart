import 'package:agrocalc/core/layout_faixa_cabecalho_laudo.dart';
import 'package:agrocalc/models/configuracoes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('altura da faixa imagem depende da linha de contato', () {
    expect(
      LayoutFaixaCabecalhoLaudo.alturaFaixaImagem(const Configuracoes()),
      LayoutFaixaCabecalhoLaudo.alturaFaixaImagemSemLinhaContato,
    );
    expect(
      LayoutFaixaCabecalhoLaudo.alturaFaixaImagem(
        const Configuracoes(emailPerfil: 'a@b.com'),
      ),
      LayoutFaixaCabecalhoLaudo.alturaFaixaImagemComLinhaContato,
    );
  });

  test('padding e raio são os valores usados no PDF', () {
    expect(LayoutFaixaCabecalhoLaudo.raioBorda, 6);
    expect(LayoutFaixaCabecalhoLaudo.paddingHorizontal, 10);
    expect(LayoutFaixaCabecalhoLaudo.paddingVertical, 8);
  });
}
