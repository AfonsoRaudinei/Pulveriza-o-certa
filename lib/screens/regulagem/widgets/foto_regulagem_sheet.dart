import 'dart:io';

import 'package:flutter/material.dart';

import '../../../models/foto_regulagem.dart';
import '../../../models/regulagem.dart';
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
    this.pontasRotulo = const {},
    this.onSave,
    this.onDelete,
  });

  final File imageFile;
  final FotoRegulagem foto;
  final bool isNew;
  final bool readonly;
  final Map<int, String> pontasRotulo;
  final ValueChanged<FotoRegulagem>? onSave;
  final VoidCallback? onDelete;

  static Future<void> show({
    required BuildContext context,
    required File imageFile,
    required FotoRegulagem foto,
    required bool isNew,
    required bool readonly,
    Map<int, String> pontasRotulo = const {},
    ValueChanged<FotoRegulagem>? onSave,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => FotoRegulagemSheet(
        imageFile: imageFile,
        foto: foto,
        isNew: isNew,
        readonly: readonly,
        pontasRotulo: pontasRotulo,
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
  late final FocusNode _tituloFocus;
  late final FocusNode _observacaoFocus;
  final _tituloFieldKey = GlobalKey();
  final _observacaoFieldKey = GlobalKey();
  int? _pontaId;

  @override
  void initState() {
    super.initState();
    _titulo = TextEditingController(text: widget.foto.titulo ?? '');
    _observacao = TextEditingController(text: widget.foto.observacao ?? '');
    _pontaId = widget.foto.pontaId;
    _tituloFocus = FocusNode();
    _observacaoFocus = FocusNode();
    _tituloFocus.addListener(_onTituloFocus);
    _observacaoFocus.addListener(_onObservacaoFocus);
  }

  @override
  void dispose() {
    _tituloFocus.removeListener(_onTituloFocus);
    _observacaoFocus.removeListener(_onObservacaoFocus);
    _tituloFocus.dispose();
    _observacaoFocus.dispose();
    _titulo.dispose();
    _observacao.dispose();
    super.dispose();
  }

  void _onTituloFocus() => _scrollFieldIntoView(_tituloFocus, _tituloFieldKey);

  void _onObservacaoFocus() =>
      _scrollFieldIntoView(_observacaoFocus, _observacaoFieldKey);

  void _scrollFieldIntoView(FocusNode node, GlobalKey fieldKey) {
    if (!node.hasFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = fieldKey.currentContext;
      if (target == null || !mounted) return;
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        alignment: 0.15,
      );
    });
  }

  void _salvar() {
    var titulo = _titulo.text.trim();
    final observacao = _observacao.text.trim();
    if (titulo.isEmpty && _pontaId != null) {
      titulo = widget.pontasRotulo[_pontaId] ?? '';
    }
    widget.onSave?.call(
      widget.foto.copyWith(
        titulo: titulo.isEmpty ? null : titulo,
        observacao: observacao.isEmpty ? null : observacao,
        pontaId: _pontaId,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;
    final maxHeight = media.size.height - media.padding.top - AppSpacing.lg;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight - bottomInset),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.xl,
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
                  aspectRatio: 4 / 3,
                  child: Image.file(
                    widget.imageFile,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (widget.pontasRotulo.isNotEmpty) ...[
                Text('Ponta', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppSpacing.xs),
                DropdownButtonFormField<int?>(
                  value: _pontaId,
                  decoration: const InputDecoration(isDense: true),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Nenhuma'),
                    ),
                    for (final entry in widget.pontasRotulo.entries)
                      DropdownMenuItem<int?>(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                  ],
                  onChanged: widget.readonly
                      ? null
                      : (v) => setState(() => _pontaId = v),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Text('Título', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSpacing.xs),
              KeyedSubtree(
                key: _tituloFieldKey,
                child: TextField(
                  controller: _titulo,
                  focusNode: _tituloFocus,
                  enabled: !widget.readonly,
                  maxLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  autocorrect: true,
                  enableSuggestions: true,
                  textInputAction: TextInputAction.next,
                  scrollPadding: const EdgeInsets.only(bottom: 120),
                  onSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_observacaoFocus),
                  decoration: const InputDecoration(
                    hintText: 'Opcional',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Observação', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSpacing.xs),
              KeyedSubtree(
                key: _observacaoFieldKey,
                child: TextField(
                  controller: _observacao,
                  focusNode: _observacaoFocus,
                  enabled: !widget.readonly,
                  maxLines: 3,
                  minLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  autocorrect: true,
                  enableSuggestions: true,
                  textInputAction: TextInputAction.done,
                  scrollPadding: const EdgeInsets.only(bottom: 160),
                  decoration: const InputDecoration(
                    hintText: 'Opcional',
                    alignLabelWithHint: true,
                    isDense: true,
                  ),
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
        ),
      ),
    );
  }
}
