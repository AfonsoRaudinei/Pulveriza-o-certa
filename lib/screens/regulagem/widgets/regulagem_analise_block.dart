import 'package:flutter/material.dart';

import '../../../models/configuracoes.dart';
import '../../../models/regulagem.dart';
import '../../../services/regulagem_pdf_service.dart';
import '../../../theme.dart';
import 'exportar_pdf_button.dart';
import 'pontas_table.dart';

class RegulagemAnaliseBlock extends StatelessWidget {
  const RegulagemAnaliseBlock({
    super.key,
    required this.medicoes,
    required this.ideal,
    required this.configuracoes,
    required this.manejo,
    required this.precoBico,
    required this.area,
    required this.ladoConferencia,
    required this.readonly,
    required this.buildData,
  });

  final List<PontaMedicao> medicoes;
  final double ideal;
  final Configuracoes configuracoes;
  final double manejo;
  final double precoBico;
  final double area;
  final LadoConferenciaPontas ladoConferencia;
  final bool readonly;
  final RegulagemPdfData Function() buildData;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PontasAnaliseSection(
            medicoes: medicoes,
            ideal: ideal,
            configuracoes: configuracoes,
            manejo: manejo,
            precoBico: precoBico,
            area: area,
            ladoConferencia: ladoConferencia,
          ),
          if (!readonly) ...[
            const SizedBox(height: AppSpacing.lg),
            ExportarPdfButton(
              buildData: buildData,
              variant: ExportarPdfButtonVariant.outlined,
            ),
          ],
        ],
      ),
    );
  }
}
