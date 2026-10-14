import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/formatters/digitos_maximo_formatter.dart';
import '../../../models/regulagem.dart';
import '../../../theme.dart';

class FieldRow extends StatelessWidget {
  const FieldRow({
    super.key,
    required this.left,
    required this.right,
    this.stacked = false,
  });

  final Widget left;
  final Widget right;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    if (stacked) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: left,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: right,
          ),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: right),
        ],
      ),
    );
  }
}

class LabeledField extends StatefulWidget {
  const LabeledField({
    super.key,
    required this.controller,
    required this.label,
    required this.readonly,
    required this.onChanged,
    this.helper,
    this.decimal = false,
    this.integer = false,
    this.trailing,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.onEditingComplete,
    this.scrollPadding = const EdgeInsets.all(20),
  });

  final TextEditingController controller;
  final String label;
  final String? helper;
  final bool readonly;
  final VoidCallback onChanged;
  final bool decimal;
  final bool integer;
  final Widget? trailing;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final EdgeInsets scrollPadding;

  @override
  State<LabeledField> createState() => _LabeledFieldState();
}

class _LabeledFieldState extends State<LabeledField> {
  late final ScrollController _scroll =
      ScrollController(keepScrollOffset: false);

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextInputType keyboardType;
    final List<TextInputFormatter> formatters;
    if (widget.decimal) {
      keyboardType = const TextInputType.numberWithOptions(decimal: true);
      formatters = [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        const DigitosMaximoFormatter(),
      ];
    } else if (widget.integer) {
      keyboardType = TextInputType.number;
      formatters = [
        FilteringTextInputFormatter.digitsOnly,
        const DigitosMaximoFormatter(),
      ];
    } else {
      keyboardType = TextInputType.text;
      formatters = const [];
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                scrollController: _scroll,
                focusNode: widget.focusNode,
                enabled: !widget.readonly,
                keyboardType: keyboardType,
                textInputAction: widget.textInputAction,
                inputFormatters: formatters,
                scrollPadding: widget.scrollPadding,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                ),
                onChanged: (_) => widget.onChanged(),
                onSubmitted: widget.onSubmitted,
                onEditingComplete: widget.onEditingComplete,
              ),
            ),
            if (widget.trailing != null) widget.trailing!,
          ],
        ),
        if (widget.helper != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(widget.helper!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}

class LabeledCulturaField extends StatelessWidget {
  const LabeledCulturaField({
    super.key,
    required this.value,
    required this.readonly,
    required this.onChanged,
  });

  final CulturaCultivo? value;
  final bool readonly;
  final ValueChanged<CulturaCultivo?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cultura', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<CulturaCultivo>(
          value: value,
          isExpanded: true,
          isDense: true,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
          ),
          hint: const Text('Selecione'),
          items: [
            for (final cultura in CulturaCultivo.values)
              DropdownMenuItem(
                value: cultura,
                child: Text(cultura.label),
              ),
          ],
          onChanged: readonly ? null : onChanged,
        ),
      ],
    );
  }
}

class LabeledTipoPontaField extends StatelessWidget {
  const LabeledTipoPontaField({
    super.key,
    required this.value,
    required this.readonly,
    required this.onChanged,
  });

  final TipoPontaBico? value;
  final bool readonly;
  final ValueChanged<TipoPontaBico?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tipo de ponta', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<TipoPontaBico>(
          value: value,
          isExpanded: true,
          isDense: true,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
          ),
          hint: const Text('Selecione'),
          items: [
            for (final tipo in TipoPontaBico.values)
              DropdownMenuItem(
                value: tipo,
                child: Text(tipo.label),
              ),
          ],
          onChanged: readonly ? null : onChanged,
        ),
      ],
    );
  }
}

class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.data,
    required this.readonly,
    required this.onPickDate,
  });

  final DateTime data;
  final bool readonly;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat('dd/MM/yyyy', 'pt_BR').format(data);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data da regulagem',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            onTap: readonly ? null : onPickDate,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      formatted,
                      maxLines: 2,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ReadonlyResult extends StatelessWidget {
  const ReadonlyResult({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
        ],
      ),
    );
  }
}
