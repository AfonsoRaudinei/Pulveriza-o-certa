import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../services/regulagem_pdf_service.dart';
import '../../../theme.dart';

class ExportarPdfButton extends StatefulWidget {
  const ExportarPdfButton({super.key, required this.data});

  final RegulagemPdfData data;

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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _loading ? null : _export,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppThemeColors.of(context).textTertiary,
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
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else ...[
              const Icon(Icons.picture_as_pdf_outlined, size: AppSpacing.xl),
              const SizedBox(width: AppSpacing.sm),
            ],
            Text(_loading ? 'Gerando PDF…' : 'Exportar PDF'),
          ],
        ),
      ),
    );
  }
}
