import 'package:agrocalc/domain/calculos/calc_diagnostico_recomendacao_laudo.dart';
import 'package:agrocalc/domain/calculos/calc_diagnostico_regulagem.dart';
import 'package:agrocalc/domain/calculos/calc_litro_min_ideal.dart';
import 'package:agrocalc/domain/calculos/calc_recomendacao_laudo.dart';
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
  test('Nova4 troca completa — frase-ponte e ordem das zonas', () {
    final d = _nova4(precoBico: 30);
    final vm = montarDiagnosticoRecomendacaoLaudo(d);

    expect(d.planoLaudo.tipo, TipoRecomendacaoLaudo.completa);
    expect(vm.linhasPorZona.length, 4);
    expect(vm.linhasPorZona.first.status, StatusPonta.desgaste);
    expect(vm.linhasPorZona[1].status, StatusPonta.irregular);
    expect(vm.linhasPorZona[2].status, StatusPonta.atencao);
    expect(vm.linhasPorZona[3].status, StatusPonta.ideal);

    expect(vm.textoBridging, isNotNull);
    expect(vm.textoBridging, contains('Atenção'));
    expect(vm.textoBridging, contains('R\$ 446,63'));
    expect(vm.textoBridging, contains('R\$ 300,00'));

    expect(vm.textoRecomendacaoFinal, contains('troca completa'));
    expect(vm.comparativo, isNotNull);

    final atencao = vm.linhasPorZona[2];
    expect(
      atencao.trechos.firstWhere((t) => t.negrito).texto,
      'Atenção',
    );
    expect(
      atencao.trechos.any((t) => t.texto.contains('Acompanhar')),
      isTrue,
    );
  });

  test('Nova4 bico R\$ 50 — unitária sem frase-ponte', () {
    final d = _nova4(precoBico: 50);
    final vm = montarDiagnosticoRecomendacaoLaudo(d);

    expect(d.planoLaudo.tipo, TipoRecomendacaoLaudo.unitaria);
    expect(vm.textoBridging, isNull);
    expect(vm.textoRecomendacaoFinal, contains('5D e 6D'));
  });
}
