import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme.dart';

class CampoRotulado extends StatelessWidget {
  const CampoRotulado({
    super.key,
    required this.label,
    required this.controller,
    this.helper,
    this.readonly = false,
    this.decimal = false,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? helper;
  final bool readonly;
  final bool decimal;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          readOnly: readonly,
          enabled: !readonly,
          keyboardType: decimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          inputFormatters: decimal
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))]
              : null,
          onChanged: (_) => onChanged?.call(),
          decoration: InputDecoration(helperText: helper),
        ),
      ],
    );
  }
}

class CampoSomenteLeitura extends StatelessWidget {
  const CampoSomenteLeitura({
    super.key,
    required this.label,
    required this.value,
    this.helper,
    this.destacado = false,
  });

  final String label;
  final String value;
  final String? helper;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        InputDecorator(
          decoration: InputDecoration(
            filled: true,
            fillColor: destacado ? colors.primaryLight : colors.surfaceAlt,
            helperText: helper,
          ),
          child: Text(
            value.isEmpty ? '—' : value,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}

class CampoDropdown<T> extends StatelessWidget {
  const CampoDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.onNovo,
    this.novoLabel = 'Novo…',
  });

  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;
  final VoidCallback? onNovo;
  final String novoLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        InputDecorator(
          decoration: const InputDecoration(),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Object?>(
              value: value,
              isExpanded: true,
              hint: const Text('Selecione'),
              items: [
                ...items.map(
                  (item) => DropdownMenuItem<Object?>(
                    value: item,
                    child:
                        Text(itemLabel(item), overflow: TextOverflow.ellipsis),
                  ),
                ),
                if (onNovo != null)
                  DropdownMenuItem<Object?>(
                    value: _NovoItem.sentinel,
                    child: Text(novoLabel),
                  ),
              ],
              onChanged: (selected) {
                if (selected == _NovoItem.sentinel) {
                  onNovo?.call();
                  return;
                }
                onChanged(selected as T?);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _NovoItem {
  static const sentinel = _NovoItem._();
  const _NovoItem._();
}
