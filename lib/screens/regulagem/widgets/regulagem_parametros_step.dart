import 'package:flutter/material.dart';

import '../../../theme.dart';
import 'regulagem_form_fields.dart';

class ParametrosStep extends StatelessWidget {
  const ParametrosStep({
    super.key,
    required this.vazao,
    required this.velocidade,
    required this.espacamento,
    required this.numeroPontas,
    required this.pressao,
    required this.readonly,
    required this.onChanged,
  });

  final TextEditingController vazao;
  final TextEditingController velocidade;
  final TextEditingController espacamento;
  final TextEditingController numeroPontas;
  final TextEditingController pressao;
  final bool readonly;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FieldRow(
          left: LabeledField(
            controller: vazao,
            label: 'Vazão (L/ha)',
            readonly: readonly,
            onChanged: onChanged,
            decimal: true,
          ),
          right: LabeledField(
            controller: velocidade,
            label: 'Velocidade (km/h)',
            readonly: readonly,
            onChanged: onChanged,
            decimal: true,
          ),
        ),
        FieldRow(
          stacked: true,
          left: LabeledField(
            controller: espacamento,
            label: 'Espaçamento entre bicos (cm)',
            readonly: readonly,
            onChanged: onChanged,
            decimal: true,
          ),
          right: LabeledField(
            controller: numeroPontas,
            label: 'Número de pontas',
            readonly: readonly,
            onChanged: onChanged,
            integer: true,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: LabeledField(
            controller: pressao,
            label: 'Pressão de trabalho (bar)',
            readonly: readonly,
            onChanged: onChanged,
            decimal: true,
          ),
        ),
      ],
    );
  }
}
