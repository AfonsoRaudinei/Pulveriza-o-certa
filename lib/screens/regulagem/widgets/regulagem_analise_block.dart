import 'package:flutter/material.dart';

import '../../../models/configuracoes.dart';
import '../../../models/regulagem.dart';
import '../../../services/regulagem_pdf_service.dart';
import '../../../theme.dart';
import 'exportar_pdf_button.dart';
import 'pontas_analise_section.dart';

class RegulagemAnaliseBlock extends StatelessWidget {
  const RegulagemAnaliseBlock({
    super.key,
    required this.medicoes,
    required this.ideal,
    required this.configuracoes,
    required this.manejo,
    required this.precoBico,
    required this.area,
    this.numeroAplicacoes,
    this.tipoPonta,
    required this.ladoConferencia,
    required this.readonly,
    required this.buildData,
    this.onShareFlowStarted,
  });

  final List<PontaMedicao> medicoes;
  final double ideal;
  final Configuracoes configuracoes;
  final double manejo;
  final double precoBico;
  final double area;
  final int? numeroAplicacoes;
  final TipoPontaBico? tipoPonta;
  final LadoConferenciaPontas ladoConferencia;
  final bool readonly;
  final Future<RegulagemPdfData> Function() buildData;
  final VoidCallback? onShareFlowStarted;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PontasAnaliseSection(
          medicoes: medicoes,
          ideal: ideal,
          configuracoes: configuracoes,
          manejo: manejo,
          precoBico: precoBico,
          area: area,
          numeroAplicacoes: numeroAplicacoes,
          tipoPonta: tipoPonta,
          ladoConferencia: ladoConferencia,
        ),
        if (!readonly) ...[
          const SizedBox(height: AppSpacing.lg),
          ExportarPdfButton(
            buildData: buildData,
            variant: ExportarPdfButtonVariant.outlined,
            onShareFlowStarted: onShareFlowStarted,
          ),
        ],
      ],
    );
  }
}
