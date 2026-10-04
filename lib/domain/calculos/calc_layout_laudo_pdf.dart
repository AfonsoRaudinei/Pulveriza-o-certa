import '../../core/formatters/laudo_numero_format.dart';
import '../../models/regulagem.dart';
import 'calc_diagnostico_regulagem.dart';
import 'calc_recomendacao_laudo.dart';
import 'calc_texto_veredito_laudo.dart';

/// Uma linha do bloco "O que fazer" (verbo + pontas + complemento).
class ItemOQueFazerLaudo {
  const ItemOQueFazerLaudo({
    required this.marcador,
    required this.verbo,
    required this.rotulos,
    this.todosOsBicos = false,
    this.complemento,
  });

  final StatusPonta marcador;
  final String verbo;
  final List<String> rotulos;
  final bool todosOsBicos;
  final String? complemento;
}

class LinhaComparativoLaudo {
  const LinhaComparativoLaudo({
    required this.titulo,
    required this.voceGasta,
    required this.continuaPerdendo,
    required this.valorPerdaDestaque,
  });

  final String titulo;
  final String voceGasta;
  final String continuaPerdendo;
  final double valorPerdaDestaque;
}

class ComparativoLaudo {
  const ComparativoLaudo({
    required this.naoFazer,
    required this.seguir,
    required this.rodape,
  });

  final LinhaComparativoLaudo naoFazer;
  final LinhaComparativoLaudo seguir;
  final String rodape;
}

class DadosCalculoLaudo {
  const DadosCalculoLaudo({
    required this.manejoPorHa,
    required this.manejoPorPonta,
    required this.precoBico,
    required this.area,
  });

  final String manejoPorHa;
  final String manejoPorPonta;
  final String precoBico;
  final String area;
}

String rotulosPontasLinha(Iterable<String> rotulos) => rotulos.join(' · ');

String _excessoMedioFrase(double? mediaPercentual) {
  if (mediaPercentual == null) return '';
  final excesso = mediaPercentual - 100;
  if (excesso <= 0) return '';
  return 'soltam ${LaudoNumeroFormat.decimal(excesso, casas: 1)}% a mais';
}

List<ItemOQueFazerLaudo> montarOQueFazerLaudo({
  required ResultadoRecomendacaoLaudo plano,
  required ZonaDiagnostico? desgaste,
  required ZonaDiagnostico? entupida,
  required ZonaDiagnostico? atencao,
}) {
  final itens = <ItemOQueFazerLaudo>[];

  if (plano.trocaTodosOsBicos) {
    itens.add(
      ItemOQueFazerLaudo(
        marcador: StatusPonta.desgaste,
        verbo: 'Trocar',
        rotulos: const [],
        todosOsBicos: true,
        complemento: desgaste != null
            ? _excessoMedioFrase(desgaste.mediaPercentual)
            : null,
      ),
    );
  } else if (plano.acoes.trocar.isNotEmpty) {
    itens.add(
      ItemOQueFazerLaudo(
        marcador: StatusPonta.desgaste,
        verbo: 'Trocar',
        rotulos: plano.acoes.trocar,
        complemento: desgaste != null
            ? _excessoMedioFrase(desgaste.mediaPercentual)
            : null,
      ),
    );
  }

  if (plano.acoes.limparRepetirTeste.isNotEmpty) {
    itens.add(
      ItemOQueFazerLaudo(
        marcador: StatusPonta.irregular,
        verbo: 'Limpar e repetir teste',
        rotulos: plano.acoes.limparRepetirTeste,
        complemento: 'subaplicação — risco de eficácia',
      ),
    );
  }

  if (plano.acoes.acompanhar.isNotEmpty) {
    itens.add(
      ItemOQueFazerLaudo(
        marcador: StatusPonta.atencao,
        verbo: 'Acompanhar',
        rotulos: plano.acoes.acompanhar,
        complemento: atencao != null
            ? _excessoMedioFrase(atencao.mediaPercentual)
            : null,
      ),
    );
  }

  if (itens.isEmpty &&
      plano.tipo == TipoRecomendacaoLaudo.nenhuma &&
      (entupida == null || entupida.quantidade == 0) &&
      (atencao == null || atencao.quantidade == 0)) {
    itens.add(
      const ItemOQueFazerLaudo(
        marcador: StatusPonta.ideal,
        verbo: 'Manter',
        rotulos: [],
        complemento: 'regulagem dentro do esperado',
      ),
    );
  }

  return itens;
}

ComparativoLaudo? montarComparativoLaudo(ResultadoRecomendacaoLaudo plano) {
  if (plano.tipo == TipoRecomendacaoLaudo.dadosIncompletos) return null;

  final ex = plano.exibicao;
  final perdaNaoFazer = ex.total;
  final perdaSeguir = plano.prejuizoResidual;

  return ComparativoLaudo(
    naoFazer: LinhaComparativoLaudo(
      titulo: 'Não fazer nada',
      voceGasta: formatarMoedaLaudo(0),
      continuaPerdendo: formatarMoedaLaudo(perdaNaoFazer),
      valorPerdaDestaque: perdaNaoFazer,
    ),
    seguir: LinhaComparativoLaudo(
      titulo: 'Seguir a recomendação',
      voceGasta: formatarMoedaLaudo(plano.custoTrocaRecomendada),
      continuaPerdendo: formatarMoedaLaudo(perdaSeguir),
      valorPerdaDestaque: perdaSeguir,
    ),
    rodape: 'Considera bicos novos dentro do ideal.',
  );
}

String? montarFraseMotivoTrocaLaudo(ResultadoRecomendacaoLaudo plano) {
  switch (plano.tipo) {
    case TipoRecomendacaoLaudo.dadosIncompletos:
    case TipoRecomendacaoLaudo.nenhuma:
      return null;
    case TipoRecomendacaoLaudo.completa:
      return 'Trocamos todos os bicos porque o custo da troca completa '
          '(${formatarMoedaLaudo(plano.custoTrocaRecomendada)}) é menor que o '
          'desperdício de defensivo por aplicação '
          '(${formatarMoedaLaudo(plano.exibicao.total)}).';
    case TipoRecomendacaoLaudo.unitaria:
      return 'Não trocamos todos os bicos porque a troca completa '
          '(${formatarMoedaLaudo(plano.custoTrocaCompleta)}) custaria mais que '
          'o prejuízo atual — a troca ponta a ponta resolve o desgaste.';
  }
}

DadosCalculoLaudo montarDadosCalculoLaudo({
  required double manejoRS,
  required double manejoPorPonta,
  required double precoBicoRS,
  required double areaHa,
}) {
  return DadosCalculoLaudo(
    manejoPorHa: manejoRS > 0 ? formatarMoedaLaudo(manejoRS) : '—',
    manejoPorPonta:
        manejoPorPonta > 0 ? formatarMoedaLaudo(manejoPorPonta) : '—',
    precoBico: precoBicoRS > 0 ? formatarMoedaLaudo(precoBicoRS) : '—',
    area: areaHa > 0 ? '${_formatarHa(areaHa)} ha' : '—',
  );
}

String _formatarHa(double areaHa) =>
    LaudoNumeroFormat.hectares(areaHa).replaceAll(' ha', '');

/// Par label/valor na ficha do cabeçalho do laudo.
typedef ParFichaCabecalhoLaudo = (String label, String value);

/// Monta as linhas da ficha (cada linha: esquerda e opcionalmente direita).
List<(ParFichaCabecalhoLaudo, ParFichaCabecalhoLaudo?)>
    montarLinhasFichaCabecalhoLaudo({
  required String produtor,
  required String fazenda,
  String? talhao,
  String? cultura,
  required String maquina,
  required String consultor,
  required String data,
}) {
  final talhaoTxt = (talhao ?? '').trim();
  final culturaTxt = (cultura ?? '').trim();
  final consultorTxt = consultor.trim();
  final comCultura = culturaTxt.isNotEmpty;

  if (!comCultura) {
    return [
      (('Produtor', produtor.trim()), ('Fazenda', fazenda.trim())),
      (
        ('Talhão', talhaoTxt.isEmpty ? '—' : talhaoTxt),
        ('Máquina', maquina.trim()),
      ),
      (
        ('Consultor', consultorTxt.isEmpty ? '—' : consultorTxt),
        ('Data', data),
      ),
    ];
  }

  return [
    (('Produtor', produtor.trim()), ('Fazenda', fazenda.trim())),
    (
      ('Talhão', talhaoTxt.isEmpty ? '—' : talhaoTxt),
      ('Cultura', culturaTxt),
    ),
    (
      ('Máquina', maquina.trim()),
      ('Consultor', consultorTxt.isEmpty ? '—' : consultorTxt),
    ),
    (('Data', data), null),
  ];
}

/// Textos do rodapé metodológico do laudo PDF.
List<String> montarLinhasComoCalculamosLaudo({
  UniformidadeDiagnostico? uniformidade,
}) {
  final linhas = <String>[
    'Vazão ideal (L/min) = vazão (L/ha) × velocidade (km/h) × '
        'espaçamento (m) ÷ 600.',
    'Perda da ponta = % excedente × manejo por ponta × área (só acima de 100%).',
    'Troca completa: recomendada quando o custo de trocar todos os bicos é menor '
        'que o desperdício total (Atenção + Desgaste); caso contrário, troca-se só '
        'as pontas em desgaste.',
  ];
  if (uniformidade != null) {
    linhas.add(
      'Uniformidade: média ${LaudoNumeroFormat.percentual(uniformidade.media)}, '
      'desvio ${LaudoNumeroFormat.decimal(uniformidade.desvioPadrao)} pp, '
      'CV ${LaudoNumeroFormat.percentual(uniformidade.cvPercentual)}.',
    );
  }
  return linhas;
}
