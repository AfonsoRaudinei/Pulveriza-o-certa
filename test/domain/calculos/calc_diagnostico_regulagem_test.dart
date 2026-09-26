import 'package:agrocalc/domain/calculos/calc_diagnostico_regulagem.dart';
import 'package:agrocalc/domain/calculos/calc_litro_min_ideal.dart';
import 'package:agrocalc/domain/calculos/limites_regulagem.dart';
import 'package:agrocalc/domain/calculos/texto_pontas.dart';
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

List<PontaMedicao> _pontasComStatus(LimitesRegulagem limites, double ideal) {
  return [
    for (var i = 0; i < _medidas.length; i++)
      PontaMedicao(
        id: i + 1,
        valorMedido: _medidas[i],
        status: StatusPonta.pendente,
      ),
  ];
}

DiagnosticoRegulagem _diagnostico({
  LimitesRegulagem limites = LimitesRegulagem.padrao,
}) {
  final ideal = calcularLitroMinIdeal(
    vazaoLha: 80,
    velocidade: 8,
    espacamentoCm: 50,
  );
  return DiagnosticoRegulagem.calcular(
    medicoes: _pontasComStatus(limites, ideal),
    litroMinIdeal: ideal,
    limites: limites,
    lado: LadoConferenciaPontas.direita,
    manejoRS: 600,
    precoBicoRS: 30,
    areaHa: 30,
  );
}

void main() {
  test('conjunto canônico 97/105 — zonas, perdas e troca completa', () {
    final d = _diagnostico();
    expect(d.limites.limiteEntupido, 97);
    expect(
        calcularLitroMinIdeal(vazaoLha: 80, velocidade: 8, espacamentoCm: 50),
        closeTo(0.5333, 0.0001));

    expect(d.entupida?.quantidade, 3);
    expect(d.entupida?.rotulos, ['3D', '9D', '10D']);
    expect(d.ideal?.quantidade, 2);
    expect(d.ideal?.rotulos, ['2D', '4D']);
    expect(d.atencao?.quantidade, 3);
    expect(d.atencao?.rotulos, ['1D', '7D', '8D']);
    expect(d.desgaste?.quantidade, 2);
    expect(d.desgaste?.rotulos, ['5D', '6D']);

    expect(d.perdaAtencao, closeTo(199.13, 0.01));
    expect(d.perdaDesgaste, closeTo(247.50, 0.01));
    expect(d.perdaTotal, closeTo(446.63, 0.01));
    expect(d.custoTrocaCompleta, closeTo(300.00, 0.01));
    expect(d.recomendacao.tipo, TipoRecomendacao.trocaCompleta);
    expect(d.analiseParcial, isFalse);
    expect(
      d.acaoNecessaria,
      'Trocar 5D e 6D; limpar 3D, 9D e 10D e repetir o teste; monitorar 1D, 7D e 8D',
    );
    expect(d.piorZona, StatusPonta.desgaste);
  });

  test('limite entupido = 100: 2D e 4D viram entupidas e Ideal some', () {
    const limites = LimitesRegulagem(
      limiteEntupido: 100,
      limiteDesgaste: 105,
    );
    final d = _diagnostico(limites: limites);
    expect(d.entupida?.quantidade, 5);
    expect(d.entupida?.rotulos, ['2D', '3D', '4D', '9D', '10D']);
    expect(d.ideal, isNull);
    expect(d.atencao?.quantidade, 3);
    expect(d.desgaste?.quantidade, 2);
  });

  test('textos com concordância de gênero e número', () {
    expect(textoQuantidadePontas(1, StatusPonta.irregular), '1 ponta entupida');
    expect(
      textoQuantidadePontas(3, StatusPonta.irregular),
      '3 pontas entupidas',
    );
    expect(
      textoQuantidadePontas(2, StatusPonta.desgaste),
      '2 pontas em desgaste',
    );
    expect(
      textoQuantidadePontas(3, StatusPonta.atencao),
      '3 pontas em atenção',
    );
    expect(textoQuantidadePontas(5, StatusPonta.ideal), '5 pontas ideais');
  });

  test('sem preço, área ou manejo não recomenda troca por custo', () {
    final ideal = calcularLitroMinIdeal(
      vazaoLha: 80,
      velocidade: 8,
      espacamentoCm: 50,
    );
    final d = DiagnosticoRegulagem.calcular(
      medicoes: _pontasComStatus(LimitesRegulagem.padrao, ideal),
      litroMinIdeal: ideal,
      limites: LimitesRegulagem.padrao,
      lado: LadoConferenciaPontas.direita,
      manejoRS: 0,
      precoBicoRS: 0,
      areaHa: 0,
    );
    expect(
      d.recomendacao.tipo,
      TipoRecomendacao.dadosEconomicosIncompletos,
    );
    expect(
      d.recomendacao.texto,
      'Informe preço do bico, área e manejo para a análise econômica',
    );
  });

  test('medição incompleta rotula a análise como parcial', () {
    final d = DiagnosticoRegulagem.calcular(
      medicoes: const [
        PontaMedicao(id: 1, valorMedido: 0.55, status: StatusPonta.pendente),
        PontaMedicao(id: 2, valorMedido: null, status: StatusPonta.pendente),
      ],
      litroMinIdeal: 0.5333,
      limites: LimitesRegulagem.padrao,
      lado: LadoConferenciaPontas.direita,
      manejoRS: 600,
      precoBicoRS: 30,
      areaHa: 30,
    );
    expect(d.analiseParcial, isTrue);
    expect(d.avisoMedicao, 'Medição incompleta (1/2)');
    expect(d.medidas, 1);
  });
}
