import 'package:flutter/material.dart';

import '../../../theme.dart';
import 'regulagem_form_fields.dart';

class VazaoHaStep extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReadonlyResult(
          label: 'Lt/min Ideal',
          value: '${litroMinIdeal.toStringAsFixed(3)} L/min',
        ),
        const SizedBox(height: AppSpacing.md),
        LabeledField(
          controller: limiteEntupido,
          label: 'Limite entupido (%)',
          helper: 'Abaixo disso o bico fica Entupido. Salva sozinho.',
          readonly: readonly,
          onChanged: onLimiteChanged,
          decimal: true,
        ),
        const SizedBox(height: AppSpacing.md),
        LabeledField(
          controller: limiteDesgaste,
          label: 'Limite desgaste (%)',
          helper: 'Acima disso o bico fica Desgaste. Salva sozinho.',
          readonly: readonly,
          onChanged: onLimiteChanged,
          decimal: true,
        ),
      ],
    );
  }
}
