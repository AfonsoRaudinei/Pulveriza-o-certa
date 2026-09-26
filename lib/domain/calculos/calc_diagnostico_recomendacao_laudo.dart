import '../../models/regulagem.dart';
import 'calc_analise_economica.dart';
import 'calc_diagnostico_regulagem.dart';
import 'calc_layout_laudo_pdf.dart';
import 'calc_recomendacao_laudo.dart';
import 'calc_texto_veredito_laudo.dart';
import 'texto_pontas.dart';

/// Trecho de texto com negrito opcional (tela e PDF).
class TrechoDiagnosticoRecomendacaoLaudo {
  const TrechoDiagnosticoRecomendacaoLaudo({
    required this.texto,
    this.negrito = false,
  });

  final String texto;
  final bool negrito;
}

class LinhaZonaDiagnosticoRecomendacaoLaudo {
  const LinhaZonaDiagnosticoRecomendacaoLaudo({
    required this.status,
    required this.trechos,
  });

  final StatusPonta status;
  final List<TrechoDiagnosticoRecomendacaoLaudo> trechos;
}

/// Conteúdo unificado de "Diagnóstico e Recomendação".
class DiagnosticoRecomendacaoLaudo {
  const DiagnosticoRecomendacaoLaudo({
    required this.linhasPorZona,
    required this.textoBridging,
    required this.textoRecomendacaoFinal,
    required this.comparativo,
  });

  final List<LinhaZonaDiagnosticoRecomendacaoLaudo> linhasPorZona;
  final String? textoBridging;
  final String textoRecomendacaoFinal;
  final ComparativoLaudo? comparativo;
}

DiagnosticoRecomendacaoLaudo montarDiagnosticoRecomendacaoLaudo(
  DiagnosticoRegulagem d,
) {
  final plano = d.planoLaudo;
  final linhas = <LinhaZonaDiagnosticoRecomendacaoLaudo>[];

  for (final o in d.orientacoes) {
    linhas.add(
      LinhaZonaDiagnosticoRecomendacaoLaudo(
        status: o.status,
        trechos: _trechosLinhaZona(o, d.atencao),
      ),
    );
  }

  return DiagnosticoRecomendacaoLaudo(
    linhasPorZona: linhas,
    textoBridging: _montarFrasePonte(d),
    textoRecomendacaoFinal: _montarRecomendacaoFinal(d),
    comparativo: montarComparativoLaudo(plano),
  );
}

List<TrechoDiagnosticoRecomendacaoLaudo> _trechosLinhaZona(
  OrientacaoDiagnostico o,
  ZonaDiagnostico? atencao,
) {
  final ids = juntarRotulosPontas(o.rotulos);
  final sufixoIds = ids.isEmpty ? '' : ' — $ids';
  final acao = _textoAcaoZona(o, atencao);

  return [
    TrechoDiagnosticoRecomendacaoLaudo(
      texto: rotuloZona(o.status),
      negrito: true,
    ),
    TrechoDiagnosticoRecomendacaoLaudo(
      texto: ' (${o.quantidade}$sufixoIds): $acao',
    ),
  ];
}

String _textoAcaoZona(
  OrientacaoDiagnostico o,
  ZonaDiagnostico? atencao,
) {
  final perda = o.perdaRs != null && o.perdaRs! > 0
      ? formatarMoedaLaudo(o.perdaRs!)
      : null;
  String? excesso;
  if (o.status == StatusPonta.atencao && atencao?.mediaPercentual != null) {
    final exc = atencao!.mediaPercentual! - 100;
    if (exc > 0) {
      excesso = exc.toStringAsFixed(1).replaceAll('.', ',');
    }
  }
  return mensagemOrientacaoLaudo(
    o.status,
    desperdicioDefensivo: perda,
    excessoMedioPercentual: excesso,
  );
}

String? _montarFrasePonte(DiagnosticoRegulagem d) {
  final qAtencao = d.atencao?.quantidade ?? 0;
  if (qAtencao <= 0 || !d.dadosEconomicosCompletos) return null;

  final recomendar = recomendarTrocaCompleta(
    perdaEstimadaTotal: d.planoLaudo.exibicao.total,
    custoTrocaTotal: d.custoTrocaCompleta,
  );
  if (!recomendar) return null;

  final perda = formatarMoedaLaudo(d.planoLaudo.exibicao.total);
  final custo = formatarMoedaLaudo(d.custoTrocaCompleta);

  return 'Mesmo pontas em Atenção podendo ser só acompanhadas isoladamente, '
      'a perda somada de Atenção e Desgaste ($perda) já ultrapassa o custo de '
      'trocar todos os bicos ($custo) — por isso a recomendação final é a '
      'troca completa.';
}

String _montarRecomendacaoFinal(DiagnosticoRegulagem d) {
  final plano = d.planoLaudo;
  switch (plano.tipo) {
    case TipoRecomendacaoLaudo.dadosIncompletos:
      return 'Recomendação: informe preço do bico, área e manejo para fechar '
          'a análise econômica.';
    case TipoRecomendacaoLaudo.completa:
      return 'Recomendação: troca completa dos bicos.';
    case TipoRecomendacaoLaudo.unitaria:
      final pontas = juntarRotulosPontas(plano.acoes.trocar);
      return pontas.isEmpty
          ? 'Recomendação: trocar as pontas em desgaste.'
          : 'Recomendação: trocar as pontas $pontas.';
    case TipoRecomendacaoLaudo.nenhuma:
      if ((d.entupida?.quantidade ?? 0) > 0) {
        return 'Recomendação: não é necessário trocar bicos agora; limpe e '
            'repita o teste nas pontas entupidas.';
      }
      return 'Recomendação: não é necessário trocar bicos agora.';
  }
}
