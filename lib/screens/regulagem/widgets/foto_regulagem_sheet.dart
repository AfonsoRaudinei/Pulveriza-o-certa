import 'dart:io';

import 'package:flutter/material.dart';

import '../../../models/foto_regulagem.dart';
import '../../../theme.dart';
import '../../../widgets/gradient_primary_button.dart';

/// Bottom sheet compacto para título/observação de uma foto.
class FotoRegulagemSheet extends StatefulWidget {
  const FotoRegulagemSheet({
    super.key,
    required this.imageFile,
    required this.foto,
    required this.isNew,
    required this.readonly,
    this.onSave,
    this.onDelete,
  });

  final File imageFile;
  final FotoRegulagem foto;
  final bool isNew;
  final bool readonly;
  final ValueChanged<FotoRegulagem>? onSave;
  final VoidCallback? onDelete;

  static Future<void> show({
    required BuildContext context,
    required File imageFile,
    required FotoRegulagem foto,
    required bool isNew,
    required bool readonly,
    ValueChanged<FotoRegulagem>? onSave,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => FotoRegulagemSheet(
        imageFile: imageFile,
        foto: foto,
        isNew: isNew,
        readonly: readonly,
        onSave: onSave,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<FotoRegulagemSheet> createState() => _FotoRegulagemSheetState();
}

class _FotoRegulagemSheetState extends State<FotoRegulagemSheet> {
  late final TextEditingController _titulo;
  late final TextEditingController _observacao;

  @override
  void initState() {
    super.initState();
    _titulo = TextEditingController(text: widget.foto.titulo ?? '');
    _observacao = TextEditingController(text: widget.foto.observacao ?? '');
  }

  @override
  void dispose() {
    _titulo.dispose();
    _observacao.dispose();
    super.dispose();
  }

  void _salvar() {
    final titulo = _titulo.text.trim();
    final observacao = _observacao.text.trim();
    widget.onSave?.call(
      widget.foto.copyWith(
        titulo: titulo.isEmpty ? null : titulo,
        observacao: observacao.isEmpty ? null : observacao,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xl + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.iosDashedBorder,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.file(
                widget.imageFile,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Título', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _titulo,
            enabled: !widget.readonly,
            maxLines: 1,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'Opcional',
              isDense: true,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Observação', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _observacao,
            enabled: !widget.readonly,
            maxLines: 3,
            minLines: 3,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'Opcional',
              alignLabelWithHint: true,
              isDense: true,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!widget.readonly) ...[
            GradientPrimaryButton(
              label: 'Salvar',
              onPressed: _salvar,
            ),
            if (!widget.isNew && widget.onDelete != null) ...[
              const SizedBox(height: AppSpacing.md),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onDelete?.call();
                },
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.iosDestructive,
                ),
                label: const Text(
                  'Excluir foto',
                  style: TextStyle(color: AppColors.iosDestructive),
                ),
              ),
            ],
          ] else
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ),
        ],
      ),
    );
  }
}
