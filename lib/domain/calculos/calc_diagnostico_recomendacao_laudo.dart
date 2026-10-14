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
  final linhas = <LinhaZonaDiagnosticoRecomendacaoLaudo>[];

  for (final o in d.orientacoes) {
    linhas.add(
      LinhaZonaDiagnosticoRecomendacaoLaudo(
        status: o.status,
        trechos: _trechosLinhaZona(o, d),
      ),
    );
  }

  return DiagnosticoRecomendacaoLaudo(
    linhasPorZona: linhas,
    textoBridging: null,
    textoRecomendacaoFinal: _montarRecomendacaoFinal(d),
    comparativo: null,
  );
}

List<TrechoDiagnosticoRecomendacaoLaudo> _trechosLinhaZona(
  OrientacaoDiagnostico o,
  DiagnosticoRegulagem d,
) {
  final rotulo = rotuloZonaLaudo(o.status, o.quantidade);

  if (o.status == StatusPonta.ideal) {
    return [
      TrechoDiagnosticoRecomendacaoLaudo(texto: rotulo, negrito: true),
      TrechoDiagnosticoRecomendacaoLaudo(
        texto: ' (${o.quantidade}): Nada a fazer.',
      ),
    ];
  }

  final ids = juntarRotulosPontas(o.rotulos);
  final sufixoIds = ids.isEmpty ? '' : ' — $ids';
  final acao = _acaoCurtaZona(o, d.numeroAplicacoes, d.tipoPonta);

  return [
    TrechoDiagnosticoRecomendacaoLaudo(texto: rotulo, negrito: true),
    TrechoDiagnosticoRecomendacaoLaudo(
      texto: ' (${o.quantidade}$sufixoIds): $acao',
    ),
  ];
}

String _acaoCurtaZona(
  OrientacaoDiagnostico o,
  int numeroAplicacoes,
  TipoPontaBico? tipoPonta,
) {
  return switch (o.status) {
    StatusPonta.desgaste => () {
        if (o.perdaRs == null || o.perdaRs! <= 0) return 'Substituir.';
        final perdaSafra = calcularPerdaSafra(
          perdaPorAplicacao: o.perdaRs!,
          numeroAplicacoes: numeroAplicacoes,
        );
        final perda = formatarMoedaLaudo(perdaSafra);
        final apps = numeroAplicacoesEfetivo(numeroAplicacoes);
        if (apps <= 1 && tipoPonta == null) {
          return 'Substituir. Desperdício de $perda na safra.';
        }
        final tipo = tipoPonta?.label;
        if (apps <= 1 && tipo != null) {
          return 'Substituir. Desperdício de $perda na safra (ponta $tipo).';
        }
        if (tipo != null) {
          return 'Substituir. Desperdício de $perda na safra '
              '($apps aplicações · ponta $tipo).';
        }
        return 'Substituir. Desperdício de $perda na safra ($apps aplicações).';
      }(),
    StatusPonta.irregular => 'Limpar e medir de novo.',
    StatusPonta.atencao => 'Acompanhar. Trocar se o excesso continuar.',
    StatusPonta.ideal => 'Nada a fazer.',
    StatusPonta.pendente => '',
  };
}

String _montarRecomendacaoFinal(DiagnosticoRegulagem d) {
  final plano = d.planoLaudo;
  switch (plano.tipo) {
    case TipoRecomendacaoLaudo.dadosIncompletos:
      return 'Recomendação: informe preço do bico, área e manejo para fechar '
          'a análise econômica.';
    case TipoRecomendacaoLaudo.completa:
      return 'Recomendação: trocar todos os bicos.';
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
