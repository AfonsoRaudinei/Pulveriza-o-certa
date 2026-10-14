import 'package:flutter/material.dart';

import '../../../models/regulagem.dart';
import '../../../theme.dart';
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
    required this.tipoPonta,
    required this.numeroAplicacoes,
    required this.data,
    required this.readonly,
    required this.onChanged,
    required this.onEconomiaChanged,
    required this.onCulturaChanged,
    required this.onTipoPontaChanged,
    this.onSelecionarCustoManejo,
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
  final TextEditingController numeroAplicacoes;
  final CulturaCultivo? cultura;
  final TipoPontaBico? tipoPonta;
  final DateTime data;
  final bool readonly;
  final VoidCallback onChanged;
  final VoidCallback onEconomiaChanged;
  final ValueChanged<CulturaCultivo?> onCulturaChanged;
  final ValueChanged<TipoPontaBico?> onTipoPontaChanged;
  final VoidCallback? onSelecionarCustoManejo;
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
            trailing: readonly || onSelecionarCustoManejo == null
                ? null
                : IconButton(
                    tooltip: 'Usar custo de manejo salvo',
                    onPressed: onSelecionarCustoManejo,
                    icon: const Icon(Icons.calculate_outlined),
                    color: AppColors.iosPrimary,
                  ),
          ),
          right: LabeledCulturaField(
            value: cultura,
            readonly: readonly,
            onChanged: onCulturaChanged,
          ),
        ),
        FieldRow(
          left: LabeledTipoPontaField(
            value: tipoPonta,
            readonly: readonly,
            onChanged: onTipoPontaChanged,
          ),
          right: LabeledField(
            controller: numeroAplicacoes,
            label: 'Nº de aplicações na safra',
            helper: 'Com esta regulagem e tipo de ponta.',
            readonly: readonly,
            onChanged: onEconomiaChanged,
            integer: true,
          ),
        ),
      ],
    );
  }
}
