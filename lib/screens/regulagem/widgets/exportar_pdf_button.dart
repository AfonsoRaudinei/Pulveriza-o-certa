import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../services/regulagem_pdf_service.dart';
import '../../../theme.dart';

enum ExportarPdfButtonVariant { icon, outlined }

class ExportarPdfButton extends StatefulWidget {
  const ExportarPdfButton({
    super.key,
    required this.buildData,
    this.variant = ExportarPdfButtonVariant.outlined,
    this.onShareFlowStarted,
  });

  /// Monta [RegulagemPdfData] só no momento da exportação (evita trabalho no build).
  final Future<RegulagemPdfData> Function() buildData;
  final ExportarPdfButtonVariant variant;

  /// Chamado imediatamente antes de abrir a folha de compartilhamento (iOS).
  final VoidCallback? onShareFlowStarted;

  @override
  State<ExportarPdfButton> createState() => _ExportarPdfButtonState();
}

class _ExportarPdfButtonState extends State<ExportarPdfButton>
    with WidgetsBindingObserver {
  bool _loading = false;
  final _anchorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _loading && mounted) {
      setState(() => _loading = false);
      _scheduleRepaint();
    }
  }

  Rect? _shareOrigin() {
    final box = _anchorKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _scheduleRepaint() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    });
  }

  Future<void> _export() async {
    if (_loading) return;
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final data = await widget.buildData();
      if (!mounted) return;
      final bytes = await RegulagemPdfService.generate(data);
      if (!mounted) return;
      final filename = RegulagemPdfService.suggestedFilename(data);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      widget.onShareFlowStarted?.call();
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf', name: filename)],
        sharePositionOrigin: _shareOrigin(),
      );
      if (!mounted) return;
      _scheduleRepaint();
    } catch (error) {
      debugPrint('Erro ao exportar PDF: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível gerar o PDF. Tente novamente.',
            ),
            backgroundColor: AppColors.danger,
          ),
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _spinner({double size = 20}) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: IconTheme.of(context).color ??
            DefaultTextStyle.of(context).style.color ??
            AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.variant == ExportarPdfButtonVariant.icon) {
      return KeyedSubtree(
        key: _anchorKey,
        child: IconButton(
          onPressed: _loading ? null : _export,
          tooltip: 'Exportar PDF',
          icon: _loading ? _spinner() : const Icon(Icons.ios_share),
        ),
      );
    }

    return KeyedSubtree(
      key: _anchorKey,
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _loading ? null : _export,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.all(AppSpacing.lg),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_loading)
                _spinner()
              else
                const Icon(Icons.ios_share, size: AppSpacing.xl),
              const SizedBox(width: AppSpacing.sm),
              Text(_loading ? 'Gerando PDF…' : 'Exportar PDF'),
            ],
          ),
        ),
      ),
    );
  }
}
