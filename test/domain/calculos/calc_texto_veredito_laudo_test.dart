import 'package:agrocalc/domain/calculos/calc_recomendacao_laudo.dart';
import 'package:agrocalc/domain/calculos/calc_texto_veredito_laudo.dart';
import 'package:agrocalc/models/regulagem.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatarMoedaLaudo e soma exibida', () {
    expect(formatarMoedaLaudo(446.63), 'R\$ 446,63');
    final ex = prejuizoLaudoParaExibicao(
      prejuizoDesgaste: 247.5,
      prejuizoAtencao: 199.13,
    );
    expect(
      formatarMoedaLaudo(ex.desgaste + ex.atencao),
      formatarMoedaLaudo(ex.total),
    );
  });

  test('mensagemOrientacaoLaudo por zona', () {
    expect(
      mensagemOrientacaoLaudo(StatusPonta.atencao, excessoMedioPercentual: '3,7'),
      contains('Acompanhar'),
    );
    expect(
      mensagemOrientacaoLaudo(
        StatusPonta.desgaste,
        desperdicioDefensivo: 'R\$ 10,00',
      ),
      contains('R\$ 10,00'),
    );
  });
}
