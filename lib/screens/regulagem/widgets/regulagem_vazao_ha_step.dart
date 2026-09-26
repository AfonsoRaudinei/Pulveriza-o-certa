import 'package:flutter/material.dart';

import '../../../domain/calculos/limites_regulagem.dart';
import '../../../theme.dart';
import '../../../widgets/barra_preview_zonas.dart';
import 'regulagem_form_fields.dart';

class VazaoHaStep extends StatefulWidget {
  const VazaoHaStep({
    super.key,
    required this.litroMinIdeal,
    required this.limiteEntupido,
    required this.limiteDesgaste,
    required this.readonly,
    required this.onLimiteChanged,
  });

  final double litroMinIdeal;
  final TextEditingController limiteEntupido;
  final TextEditingController limiteDesgaste;
  final bool readonly;
  final VoidCallback onLimiteChanged;

  @override
  State<VazaoHaStep> createState() => _VazaoHaStepState();
}

class _VazaoHaStepState extends State<VazaoHaStep> {
  @override
  void initState() {
    super.initState();
    widget.limiteEntupido.addListener(_rebuild);
    widget.limiteDesgaste.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.limiteEntupido.removeListener(_rebuild);
    widget.limiteDesgaste.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  LimitesRegulagem _limitesAtuais() {
    final ent = double.tryParse(
          widget.limiteEntupido.text.replaceAll(',', '.'),
        ) ??
        LimitesRegulagem.padrao.limiteEntupido;
    final des = double.tryParse(
          widget.limiteDesgaste.text.replaceAll(',', '.'),
        ) ??
        LimitesRegulagem.padrao.limiteDesgaste;
    return LimitesRegulagem(limiteEntupido: ent, limiteDesgaste: des);
  }

  @override
  Widget build(BuildContext context) {
    final limites = _limitesAtuais();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReadonlyResult(
          label: 'Lt/min Ideal',
          value: '${widget.litroMinIdeal.toStringAsFixed(3)} L/min',
        ),
        const SizedBox(height: AppSpacing.md),
        LabeledField(
          controller: widget.limiteEntupido,
          label: 'Limite entupida (%)',
          helper:
              'Abaixo disso o bico fica Entupida. Salva sozinho nesta regulagem.',
          readonly: widget.readonly,
          onChanged: widget.onLimiteChanged,
          decimal: true,
        ),
        const SizedBox(height: AppSpacing.md),
        LabeledField(
          controller: widget.limiteDesgaste,
          label: 'Limite desgaste (%)',
          helper:
              'Acima disso o bico fica Desgaste. Entre 100% e este limite é Atenção.',
          readonly: widget.readonly,
          onChanged: widget.onLimiteChanged,
          decimal: true,
        ),
        const SizedBox(height: AppSpacing.md),
        BarraPreviewZonas(limites: limites),
      ],
    );
  }
}
