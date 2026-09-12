import 'dart:math' show max, min;

import '../../models/regulagem.dart';
import '../utils/calculo_utils.dart';

/// Uma ponta preparada para o gráfico de vazão.
///
/// `percentual` é `null` quando a ponta ainda não foi medida — pendente não é
/// zero, então a barra não é desenhada e a ponta aparece como marcador vazio.
class VazaoChartPonta {
  const VazaoChartPonta({
    required this.id,
    required this.valorMedido,
    required this.percentual,
    required this.status,
  });

  final int id;
  final double? valorMedido;
  final double? percentual;
  final StatusPonta status;

  bool get medida => percentual != null;
}

/// Dados de apresentação do gráfico "Vazão por ponta".
///
/// O gráfico é desenhado em percentual do ideal (100% = vazão ideal), porque é
/// nessa escala que os limites de entupimento e desgaste são definidos. A
/// janela do eixo Y sempre contém a faixa ideal inteira, mesmo quando todas as
/// pontas ficam dentro dela.
///
/// Usado pela tela de regulagem e pelo laudo em PDF, para que os dois desenhem
/// exatamente a mesma geometria.
class VazaoChartData {
  const VazaoChartData._({
    required this.pontas,
    required this.litroMinIdeal,
    required this.limiteIrregular,
    required this.limiteDesgaste,
    required this.minPercent,
    required this.maxPercent,
  });

  /// Alcance máximo do eixo Y, em pontos percentuais.
  ///
  /// Uma ponta totalmente entupida (0%) achataria o resto do gráfico; acima
  /// desse alcance a barra é cortada na borda e o rótulo mantém o valor real.
  static const alcanceMaximo = 60.0;

  factory VazaoChartData.from({
    required List<PontaMedicao> medicoes,
    required double litroMinIdeal,
    required double limiteIrregular,
    required double limiteDesgaste,
  }) {
    final pontas = [
      for (final item in medicoes)
        VazaoChartPonta(
          id: item.id,
          valorMedido: item.valorMedido,
          percentual: item.valorMedido == null || litroMinIdeal <= 0
              ? null
              : CalcUtils.calcularPercentualPonta(
                  valorMedido: item.valorMedido!,
                  litroMinIdeal: litroMinIdeal,
                ),
          status: item.status,
        ),
    ];

    var inferior = min(limiteIrregular, 100.0);
    var superior = max(limiteDesgaste, 100.0);
    for (final ponta in pontas) {
      final percentual = ponta.percentual;
      if (percentual == null) continue;
      inferior = min(inferior, percentual);
      superior = max(superior, percentual);
    }

    final margem = max(3.0, (superior - inferior) * 0.12);
    final maxPercent = superior + margem;
    final minPercent = max(inferior - margem, maxPercent - alcanceMaximo);

    return VazaoChartData._(
      pontas: pontas,
      litroMinIdeal: litroMinIdeal,
      limiteIrregular: limiteIrregular,
      limiteDesgaste: limiteDesgaste,
      minPercent: minPercent,
      maxPercent: maxPercent,
    );
  }

  final List<VazaoChartPonta> pontas;
  final double litroMinIdeal;
  final double limiteIrregular;
  final double limiteDesgaste;
  final double minPercent;
  final double maxPercent;

  double get amplitude => maxPercent - minPercent;

  /// Sem ideal ou sem nenhuma ponta medida não há gráfico para mostrar.
  bool get vazio =>
      litroMinIdeal <= 0 ||
      pontas.isEmpty ||
      !pontas.any((ponta) => ponta.medida);

  bool get temPendente => pontas.any((ponta) => !ponta.medida);

  /// Status que aparecem na legenda, na ordem ideal → entupido → desgaste.
  List<StatusPonta> get statusMedidos {
    const ordem = [
      StatusPonta.ideal,
      StatusPonta.irregular,
      StatusPonta.desgaste,
    ];
    return [
      for (final status in ordem)
        if (pontas.any((ponta) => ponta.medida && ponta.status == status))
          status,
    ];
  }

  /// Percentual limitado à janela do eixo, para desenhar a barra.
  double percentualNoEixo(double percentual) =>
      percentual.clamp(minPercent, maxPercent);
}

/// Rótulo curto de cada status, usado na legenda do gráfico na tela e no PDF.
String rotuloStatusPonta(StatusPonta status) {
  return switch (status) {
    StatusPonta.ideal => 'Ideal',
    StatusPonta.irregular => 'Entupido',
    StatusPonta.desgaste => 'Desgaste',
    StatusPonta.pendente => 'Sem medição',
  };
}
