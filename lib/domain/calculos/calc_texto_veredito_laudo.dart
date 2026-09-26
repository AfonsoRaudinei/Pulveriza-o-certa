import '../../models/regulagem.dart';
import 'calc_recomendacao_laudo.dart';
import 'texto_pontas.dart';

/// Moeda pt_BR para textos do laudo (arredonda só na exibição).
String formatarMoedaLaudo(double valor) {
  final cents = (valor * 100).round();
  final negativo = cents < 0;
  final abs = cents.abs();
  final reais = abs ~/ 100;
  final centavos = abs % 100;
  final reaisStr = reais.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  );
  final prefixo = negativo ? '-R\$ ' : 'R\$ ';
  return '$prefixo$reaisStr,${centavos.toString().padLeft(2, '0')}';
}

String fraseSePagaNoLaudo(double? aplicacoesBrutas) {
  final n = aplicacoesParaSePagarArredondadas(aplicacoesBrutas);
  if (n == null) return '';
  if (n <= 1) return 'se paga já na 1ª aplicação';
  return 'se paga em $n aplicações';
}

String _formatarHa(double areaHa) {
  if (areaHa <= 0) return '';
  final s = areaHa.toStringAsFixed(1);
  return s.endsWith('.0') ? areaHa.toStringAsFixed(0) : s;
}

String _excessoMedioTexto(double mediaPercentual) {
  final excesso = mediaPercentual - 100;
  if (excesso <= 0) return '';
  return excesso.toStringAsFixed(1).replaceAll('.', ',');
}

/// Veredito em uma frase — alimenta PDF e tela a partir de [plano].
String montarVereditoLaudo({
  required ResultadoRecomendacaoLaudo plano,
  required double areaHa,
  required int quantidadeDesgaste,
  required int quantidadeAtencao,
  required List<String> rotulosDesgaste,
  double? mediaPercentualAtencao,
}) {
  final ex = plano.exibicao;
  final areaTxt = _formatarHa(areaHa);

  switch (plano.tipo) {
    case TipoRecomendacaoLaudo.dadosIncompletos:
      return 'Informe o custo do defensivo por hectare, a área aplicada e o preço do bico '
          'para calcular se a troca compensa.';
    case TipoRecomendacaoLaudo.completa:
      final reforcoAtencao = quantidadeAtencao > 0
          ? ', e as $quantidadeAtencao em atenção reforçam a decisão'
          : '';
      final areaFrase = areaTxt.isNotEmpty ? ' nos $areaTxt ha' : '';
      final sePaga = fraseSePagaNoLaudo(plano.aplicacoesParaSePagar);
      return 'Recomendamos trocar todos os bicos. '
          'As $quantidadeDesgaste pontas em desgaste já justificam a troca$reforcoAtencao. '
          'Hoje você gasta ${formatarMoedaLaudo(ex.total)} a mais em defensivo '
          'a cada aplicação$areaFrase. '
          'A troca custa ${formatarMoedaLaudo(plano.custoTrocaRecomendada)} e $sePaga.';
    case TipoRecomendacaoLaudo.unitaria:
      final pontas = juntarRotulosPontas(rotulosDesgaste);
      return 'Troque as pontas $pontas. '
          'Elas desperdiçam ${formatarMoedaLaudo(ex.desgaste)} por aplicação '
          'e a troca custa ${formatarMoedaLaudo(plano.custoTrocaRecomendada)}. '
          'Trocar todos os bicos (${formatarMoedaLaudo(plano.custoTrocaCompleta)}) não compensa agora.';
    case TipoRecomendacaoLaudo.nenhuma:
      if (quantidadeAtencao > 0 && quantidadeDesgaste == 0) {
        final excesso = mediaPercentualAtencao != null
            ? _excessoMedioTexto(mediaPercentualAtencao)
            : '';
        final detalhe = excesso.isNotEmpty
            ? ' As pontas em atenção soltam em média $excesso% a mais; acompanhe e troque se persistir.'
            : ' Acompanhe as pontas em atenção e troque se o excesso de vazão persistir.';
        return 'Não é necessário trocar bicos agora.$detalhe '
            'Limpe e repita o teste nas pontas entupidas, se houver.';
      }
      return 'Não é necessário trocar bicos agora. '
          'A regulagem está dentro do esperado; continue monitorando nas próximas aplicações.';
  }
}

/// Orientação por zona, sem “perda” nem “payback”.
String mensagemOrientacaoLaudo(
  StatusPonta zona, {
  String? desperdicioDefensivo,
  String? excessoMedioPercentual,
}) {
  return switch (zona) {
    StatusPonta.desgaste =>
      desperdicioDefensivo == null || desperdicioDefensivo.isEmpty
          ? 'Substituir os bicos em desgaste.'
          : 'Substituir. Desperdício de $desperdicioDefensivo em defensivo por aplicação.',
    StatusPonta.irregular =>
      'Limpar bicos, verificar filtro e calda, repetir o teste.',
    StatusPonta.atencao =>
      excessoMedioPercentual != null && excessoMedioPercentual.isNotEmpty
          ? 'Acompanhar; soltam em média $excessoMedioPercentual% a mais. Troque se persistir.'
          : 'Acompanhar; troque se o excesso de vazão persistir.',
    StatusPonta.ideal => 'Sem ação; continue o monitoramento.',
    StatusPonta.pendente => '',
  };
}
