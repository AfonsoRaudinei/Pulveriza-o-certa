import 'dart:io';

import 'package:flutter/material.dart';

import '../../../models/perfil_relatorio.dart';
import '../../../theme.dart';
import 'settings_card.dart';

class RelatorioHeaderPreview extends StatelessWidget {
  const RelatorioHeaderPreview({super.key, required this.perfil});

  final PerfilRelatorio perfil;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final temLogo =
        perfil.logoPath != null && File(perfil.logoPath!).existsSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prévia do cabeçalho',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.textPrimary,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SettingsCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              if (temLogo)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Image.file(
                    File(perfil.logoPath!),
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: colors.border),
                  ),
                  child: Icon(Icons.business, color: colors.textTertiary),
                ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      perfil.empresaNome.isEmpty
                          ? 'Nome da Empresa'
                          : perfil.empresaNome,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (perfil.nomeConsultor.isNotEmpty)
                      Text(
                        perfil.nomeConsultor,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
