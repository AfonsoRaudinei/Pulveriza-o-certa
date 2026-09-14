import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../theme.dart';

class ImagemPerfilPicker extends StatelessWidget {
  const ImagemPerfilPicker({
    super.key,
    required this.label,
    required this.imagePath,
    required this.onPick,
    required this.onRemove,
    this.placeholder = 'Adicionar imagem',
  });

  final String label;
  final String? imagePath;
  final Future<void> Function(ImageSource source) onPick;
  final VoidCallback onRemove;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final temImagem = imagePath != null && File(imagePath!).existsSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.textPrimary,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            GestureDetector(
              onTap: () => _mostrarOrigem(context),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.iosDashedBorder,
                    style: BorderStyle.solid,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: temImagem
                    ? Image.file(File(imagePath!), fit: BoxFit.cover)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            color: colors.textTertiary,
                            size: 24,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            placeholder,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9,
                              color: colors.textTertiary,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (temImagem) ...[
              const SizedBox(width: AppSpacing.md),
              TextButton(
                onPressed: onRemove,
                child: const Text('Remover'),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _mostrarOrigem(BuildContext context) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              onPick(ImageSource.camera);
            },
            child: const Text('Câmera'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              onPick(ImageSource.gallery);
            },
            child: const Text('Galeria'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }
}
