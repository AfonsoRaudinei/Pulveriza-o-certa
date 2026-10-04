import 'package:agrocalc/domain/calculos/calc_diagnostico_regulagem.dart';
import 'package:agrocalc/domain/calculos/calc_layout_laudo_pdf.dart';
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
  test('Nova4 completa — o que fazer e comparativo', () {
    final d = _nova4(precoBico: 30);
    final itens = montarOQueFazerLaudo(
      plano: d.planoLaudo,
      desgaste: d.desgaste,
      entupida: d.entupida,
      atencao: d.atencao,
    );
    expect(itens.any((i) => i.todosOsBicos && i.verbo == 'Trocar'), isTrue);
    expect(itens.any((i) => i.verbo == 'Acompanhar'), isTrue);

    final c = montarComparativoLaudo(d.planoLaudo)!;
    expect(c.naoFazer.continuaPerdendo, 'R\$ 446,63');
    expect(c.seguir.voceGasta, 'R\$ 300,00');
    expect(c.seguir.continuaPerdendo, 'R\$ 0,00');
    expect(c.rodape, contains('ideal'));
    expect(
        montarFraseMotivoTrocaLaudo(d.planoLaudo), contains('todos os bicos'));
  });

  test('ficha cabeçalho — com e sem cultura', () {
    final comCultura = montarLinhasFichaCabecalhoLaudo(
      produtor: 'P',
      fazenda: 'F',
      talhao: 'T',
      cultura: 'Soja',
      maquina: 'M',
      consultor: 'C',
      data: '26/09/2026',
    );
    expect(comCultura.length, 4);
    expect(comCultura[1].$1.$1, 'Talhão');
    expect(comCultura[1].$2?.$1, 'Cultura');
    expect(comCultura[1].$2?.$2, 'Soja');
    expect(comCultura[3].$2, isNull);
    expect(comCultura[3].$1.$1, 'Data');

    final legado = montarLinhasFichaCabecalhoLaudo(
      produtor: 'P',
      fazenda: 'F',
      talhao: 'T',
      cultura: null,
      maquina: 'M',
      consultor: 'C',
      data: '26/09/2026',
    );
    expect(legado.length, 3);
    expect(legado[1].$2?.$1, 'Máquina');
  });

  test('Como calculamos — fórmula resumida e troca completa', () {
    final linhas = montarLinhasComoCalculamosLaudo();
    expect(linhas.first, contains('espaçamento (m)'));
    expect(linhas.first, isNot(contains('cm ÷ 100')));
    expect(linhas[1], contains('só acima de 100%'));
    expect(linhas[2], contains('desperdício total (Atenção + Desgaste)'));
    expect(linhas[2], contains('pontas em desgaste'));
  });

  test('Nova4 unitária — motivo não troca tudo', () {
    final d = _nova4(precoBico: 50);
    expect(d.planoLaudo.tipo, TipoRecomendacaoLaudo.unitaria);
    final trocar = montarOQueFazerLaudo(
      plano: d.planoLaudo,
      desgaste: d.desgaste,
      entupida: d.entupida,
      atencao: d.atencao,
    ).first;
    expect(trocar.rotulos, contains('5D'));
    expect(
        montarFraseMotivoTrocaLaudo(d.planoLaudo), contains('ponta a ponta'));
  });
}
