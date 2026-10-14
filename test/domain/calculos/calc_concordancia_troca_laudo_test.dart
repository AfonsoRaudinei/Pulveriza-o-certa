import 'package:agrocalc/domain/calculos/calc_diagnostico_recomendacao_laudo.dart';
import 'package:agrocalc/domain/calculos/calc_diagnostico_regulagem.dart';
import 'package:agrocalc/domain/calculos/calc_litro_min_ideal.dart';
import 'package:agrocalc/domain/calculos/calc_recomendacao_laudo.dart';
import 'package:agrocalc/domain/calculos/calc_texto_analise_economica_laudo.dart';
import 'package:agrocalc/domain/calculos/limites_regulagem.dart';
import 'package:agrocalc/models/regulagem.dart';
import 'package:flutter_test/flutter_test.dart';

const _medidasNova4 = [
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

DiagnosticoRegulagem _diagnosticoNova4({required double precoBico}) {
  final ideal = calcularLitroMinIdeal(
    vazaoLha: 80,
    velocidade: 8,
    espacamentoCm: 50,
  );
  return DiagnosticoRegulagem.calcular(
    medicoes: [
      for (var i = 0; i < _medidasNova4.length; i++)
        PontaMedicao(
          id: i + 1,
          valorMedido: _medidasNova4[i],
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

bool _trocaCompletaNoTextoDiagnostico(DiagnosticoRegulagem d) {
  final laudo = montarDiagnosticoRecomendacaoLaudo(d);
  return laudo.textoRecomendacaoFinal.contains('trocar todos os bicos');
}

bool _trocaCompletaNoTextoAnaliseEconomica(DiagnosticoRegulagem d) {
  final entrada = entradaAnaliseEconomicaLaudoDe(d);
  final blocos = montarBlocosAnaliseEconomicaLaudoDe(entrada);
  final texto = analiseEconomicaLaudoComoTexto(blocos);
  return texto.contains('Essa perda já passa o custo de trocar todos os bicos');
}

void main() {
  test(
    'Diagnóstico e Análise Econômica concordam na troca completa vs. seletiva',
    () {
      final casos = <double>[
        30,
        50,
        _diagnosticoNova4(precoBico: 30).perdaTotal /
            _diagnosticoNova4(precoBico: 30).totalPontas,
      ];

      for (final preco in casos) {
        final d = _diagnosticoNova4(precoBico: preco);
        final entrada = entradaAnaliseEconomicaLaudoDe(d);
        final trocaPlano = d.planoLaudo.trocaTodosOsBicos;
        final trocaEntrada = entrada.recomendarTroca;
        final trocaDiag = _trocaCompletaNoTextoDiagnostico(d);
        final trocaAnalise = _trocaCompletaNoTextoAnaliseEconomica(d);

        expect(
          trocaEntrada,
          trocaPlano,
          reason: 'entrada vs plano (preço bico $preco)',
        );
        expect(
          trocaDiag,
          trocaPlano,
          reason: 'texto diagnóstico vs plano (preço bico $preco)',
        );
        expect(
          trocaAnalise,
          trocaPlano,
          reason: 'texto análise vs plano (preço bico $preco)',
        );
      }
    },
  );

  test('empate exato perda safra == custo troca → ambos recomendam troca completa',
      () {
    final ref = _diagnosticoNova4(precoBico: 30);
    final precoEmpate = ref.perdaTotal / ref.totalPontas;
    final d = _diagnosticoNova4(precoBico: precoEmpate);

    expect(d.planoLaudo.tipo, TipoRecomendacaoLaudo.completa);
    expect(entradaAnaliseEconomicaLaudoDe(d).recomendarTroca, isTrue);
    expect(_trocaCompletaNoTextoDiagnostico(d), isTrue);
    expect(_trocaCompletaNoTextoAnaliseEconomica(d), isTrue);
  });
}
