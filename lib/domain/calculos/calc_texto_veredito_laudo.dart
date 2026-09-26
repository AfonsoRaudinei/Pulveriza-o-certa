import '../../models/regulagem.dart';
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
