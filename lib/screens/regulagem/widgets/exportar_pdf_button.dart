import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../services/regulagem_pdf_service.dart';
import '../../../theme.dart';

enum ExportarPdfButtonVariant { icon, outlined }

class ExportarPdfButton extends StatefulWidget {
  const ExportarPdfButton({
    super.key,
    required this.data,
    this.variant = ExportarPdfButtonVariant.outlined,
  });

  final RegulagemPdfData data;
  final ExportarPdfButtonVariant variant;

  @override
  State<ExportarPdfButton> createState() => _ExportarPdfButtonState();
}

class _ExportarPdfButtonState extends State<ExportarPdfButton> {
  bool _loading = false;

  Future<void> _export() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final bytes = await RegulagemPdfService.generate(widget.data);
      final filename = RegulagemPdfService.suggestedFilename(widget.data);
      await Printing.sharePdf(bytes: bytes, filename: filename);
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
      return IconButton(
        onPressed: _export,
        tooltip: 'Exportar PDF',
        icon: _loading ? _spinner() : const Icon(Icons.ios_share),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _export,
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
    );
  }
}
