import 'package:agrocalc/domain/calculos/calc_diagnostico_regulagem.dart';
import 'package:agrocalc/domain/calculos/calc_litro_min_ideal.dart';
import 'package:agrocalc/domain/calculos/calc_recomendacao_laudo.dart';
import 'package:agrocalc/domain/calculos/calc_texto_veredito_laudo.dart';
import 'package:agrocalc/domain/calculos/limites_regulagem.dart';
import 'package:agrocalc/models/regulagem.dart';
import 'package:flutter_test/flutter_test.dart';

const _medidas = [
  0.550,
  0.530,
  0.490,
  0.530,
  0.570,
  0.570,
  0.559,
  0.550,
  0.500,
  0.510,
];

DiagnosticoRegulagem _nova4({double precoBico = 30}) {
  final ideal = calcularLitroMinIdeal(
    vazaoLha: 80,
    velocidade: 8,
    espacamentoCm: 50,
  );
  return DiagnosticoRegulagem.calcular(
    medicoes: [
      for (var i = 0; i < _medidas.length; i++)
        PontaMedicao(
          id: i + 1,
          valorMedido: _medidas[i],
          status: StatusPonta.pendente,
        ),
    ],
    litroMinIdeal: ideal,
    limites: LimitesRegulagem.padrao,
    lado: LadoConferenciaPontas.direita,
    manejoRS: 600,
    precoBicoRS: precoBico,
    areaHa: 30,
  );
}

void main() {
  test('Nova4 veredito troca completa', () {
    final d = _nova4(precoBico: 30);
    expect(d.planoLaudo.tipo, TipoRecomendacaoLaudo.completa);
    expect(d.vereditoLaudo, contains('trocar todos os bicos'));
    expect(d.vereditoLaudo, contains('2 pontas em desgaste'));
    expect(d.vereditoLaudo, contains('3 em atenção'));
    expect(d.vereditoLaudo, contains('R\$ 446,63'));
    expect(d.vereditoLaudo, contains('R\$ 300,00'));
    expect(d.vereditoLaudo, contains('1ª aplicação'));
    expect(d.vereditoLaudo, isNot(contains('payback')));
    expect(d.vereditoLaudo, isNot(contains('perda')));
  });

  test('Nova4 bico R\$ 50 veredito unitário', () {
    final d = _nova4(precoBico: 50);
    expect(d.planoLaudo.tipo, TipoRecomendacaoLaudo.unitaria);
    expect(d.vereditoLaudo, contains('5D e 6D'));
    expect(d.vereditoLaudo, contains('R\$ 247,50'));
    expect(d.vereditoLaudo, contains('R\$ 100,00'));
    expect(d.vereditoLaudo, contains('não compensa'));
  });

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
}
