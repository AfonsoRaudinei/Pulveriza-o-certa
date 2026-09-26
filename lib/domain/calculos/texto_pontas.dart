import '../../models/regulagem.dart';

/// Concordância de gênero e número das zonas do laudo.
String textoQuantidadePontas(int quantidade, StatusPonta zona) {
  final substantivo = quantidade == 1 ? 'ponta' : 'pontas';
  final complemento = switch (zona) {
    StatusPonta.irregular => quantidade == 1 ? 'entupida' : 'entupidas',
    StatusPonta.ideal => quantidade == 1 ? 'ideal' : 'ideais',
    StatusPonta.atencao => 'em atenção',
    StatusPonta.desgaste => 'em desgaste',
    StatusPonta.pendente => quantidade == 1 ? 'pendente' : 'pendentes',
  };
  return '$quantidade $substantivo $complemento';
}

String rotuloZona(StatusPonta zona) {
  return switch (zona) {
    StatusPonta.irregular => 'Entupida',
    StatusPonta.ideal => 'Ideal',
    StatusPonta.atencao => 'Atenção',
    StatusPonta.desgaste => 'Desgaste',
    StatusPonta.pendente => 'Pendente',
  };
}

/// Junta rótulos no padrão "5D e 6D" / "3D, 9D e 10D".
/// Legenda D/E só com os lados usados neste laudo.
String legendaLadosPontasLaudo({
  required int numeroPontas,
  required LadoConferenciaPontas ladoConferencia,
}) {
  final partes = <String>[];
  // Mesmo limite de [maxPontasPorGraficoPdf] no planejamento do gráfico PDF.
  if (numeroPontas <= 20) {
    if (ladoConferencia == LadoConferenciaPontas.direita) {
      partes.add('D = lado direito');
    } else {
      partes.add('E = lado esquerdo');
    }
  } else {
    partes.add('D = lado direito');
    partes.add('E = lado esquerdo');
  }
  return partes.join(', ');
}

String juntarRotulosPontas(Iterable<String> rotulos) {
  final itens = rotulos.toList(growable: false);
  if (itens.isEmpty) return '';
  if (itens.length == 1) return itens.first;
  if (itens.length == 2) return '${itens[0]} e ${itens[1]}';
  return '${itens.sublist(0, itens.length - 1).join(', ')} e ${itens.last}';
}

String mensagemOrientacaoZona(
  StatusPonta zona, {
  String? perdaPorAplicacao,
}) {
  return switch (zona) {
    StatusPonta.desgaste =>
      perdaPorAplicacao == null || perdaPorAplicacao.isEmpty
          ? 'Substituir as pontas.'
          : 'Substituir. Perda de $perdaPorAplicacao por aplicação.',
    StatusPonta.irregular =>
      'Limpar bicos, verificar filtro e calda, repetir o teste.',
    StatusPonta.atencao => perdaPorAplicacao == null ||
            perdaPorAplicacao.isEmpty
        ? 'Monitorar. Troca preventiva se persistir.'
        : 'Monitorar. Perda de $perdaPorAplicacao por aplicação. Troca preventiva se persistir.',
    StatusPonta.ideal => 'Sem ação, continuar o monitoramento.',
    StatusPonta.pendente => '',
  };
}

String textoAcaoNecessaria({
  required List<String> desgaste,
  required List<String> entupida,
  required List<String> atencao,
}) {
  final partes = <String>[];
  if (desgaste.isNotEmpty) {
    partes.add('Trocar ${juntarRotulosPontas(desgaste)}');
  }
  if (entupida.isNotEmpty) {
    partes.add(
      'limpar ${juntarRotulosPontas(entupida)} e repetir o teste',
    );
  }
  if (atencao.isNotEmpty) {
    partes.add('monitorar ${juntarRotulosPontas(atencao)}');
  }
  if (partes.isEmpty) return 'Sem ação de troca';
  final buffer = StringBuffer(partes.first);
  for (var i = 1; i < partes.length; i++) {
    buffer.write('; ${partes[i]}');
  }
  return buffer.toString();
}

/// Frase curta do significado da zona no laudo (E2).
String significadoZonaLaudo(StatusPonta zona) {
  return switch (zona) {
    StatusPonta.irregular =>
      'Vazão abaixo do esperado; em geral obstrução.',
    StatusPonta.ideal => 'Dentro do esperado.',
    StatusPonta.atencao => 'Levemente acima; já gera desperdício.',
    StatusPonta.desgaste => 'Acima do limite; bico gasto.',
    StatusPonta.pendente => '',
  };
}

String avisoMedicaoIncompleta({
  required int medidas,
  required int total,
}) =>
    'Medição incompleta ($medidas/$total)';
