import 'package:flutter/material.dart';

import '../../../models/regulagem.dart';
import 'regulagem_form_fields.dart';

class ContextStep extends StatelessWidget {
  const ContextStep({
    super.key,
    required this.produtor,
    required this.fazenda,
    required this.talhao,
    required this.maquina,
    required this.consultor,
    required this.area,
    required this.manejo,
    required this.precoBico,
    required this.cultura,
    required this.data,
    required this.readonly,
    required this.onChanged,
    required this.onEconomiaChanged,
    required this.onCulturaChanged,
    required this.onPickDate,
  });

  final TextEditingController produtor;
  final TextEditingController fazenda;
  final TextEditingController talhao;
  final TextEditingController maquina;
  final TextEditingController consultor;
  final TextEditingController area;
  final TextEditingController manejo;
  final TextEditingController precoBico;
  final CulturaCultivo? cultura;
  final DateTime data;
  final bool readonly;
  final VoidCallback onChanged;
  final VoidCallback onEconomiaChanged;
  final ValueChanged<CulturaCultivo?> onCulturaChanged;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FieldRow(
          left: LabeledField(
            controller: produtor,
            label: 'Produtor',
            readonly: readonly,
            onChanged: onChanged,
          ),
          right: LabeledField(
            controller: fazenda,
            label: 'Fazenda',
            readonly: readonly,
            onChanged: onChanged,
          ),
        ),
        FieldRow(
          left: LabeledField(
            controller: talhao,
            label: 'Talhão',
            readonly: readonly,
            onChanged: onChanged,
          ),
          right: LabeledField(
            controller: maquina,
            label: 'Máquina',
            readonly: readonly,
            onChanged: onChanged,
          ),
        ),
        FieldRow(
          left: LabeledField(
            controller: consultor,
            label: 'Consultor',
            readonly: readonly,
            onChanged: onChanged,
          ),
          right: DateField(
            data: data,
            readonly: readonly,
            onPickDate: onPickDate,
          ),
        ),
        FieldRow(
          left: LabeledField(
            controller: area,
            label: 'Área (ha)',
            readonly: readonly,
            onChanged: onEconomiaChanged,
            decimal: true,
          ),
          right: LabeledField(
            controller: precoBico,
            label: 'Preço do bico (R\$/un)',
            helper: 'Valor de um bico. Troca completa = preço × nº de pontas.',
            readonly: readonly,
            onChanged: onEconomiaChanged,
            decimal: true,
          ),
        ),
        FieldRow(
          left: LabeledField(
            controller: manejo,
            label: 'Manejo (R\$)',
            readonly: readonly,
            onChanged: onEconomiaChanged,
            decimal: true,
          ),
          right: LabeledCulturaField(
            value: cultura,
            readonly: readonly,
            onChanged: onCulturaChanged,
          ),
        ),
      ],
    );
  }
}
