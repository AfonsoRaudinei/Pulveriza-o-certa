import 'package:flutter/material.dart';

import '../core/iconografia/zona_icon.dart';
import '../core/marcadores_zona.dart';
import '../domain/calculos/calc_diagnostico_recomendacao_laudo.dart';
import '../domain/calculos/calc_layout_laudo_pdf.dart';
import '../models/regulagem.dart';
import '../theme.dart';

/// Seção única "Diagnóstico e Recomendação" (tela e mesma estrutura que o PDF).
class DiagnosticoRecomendacaoLaudoView extends StatelessWidget {
  const DiagnosticoRecomendacaoLaudoView({
    super.key,
    required this.conteudo,
  });

  final DiagnosticoRecomendacaoLaudo conteudo;

  @override
  Widget build(BuildContext context) {
    if (conteudo.linhasPorZona.isEmpty &&
        conteudo.textoRecomendacaoFinal.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TituloSecao(),
        const SizedBox(height: AppSpacing.sm),
        for (final linha in conteudo.linhasPorZona) ...[
          _LinhaZona(linha: linha),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (conteudo.textoBridging != null) ...[
          Text(
            conteudo.textoBridging!,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Text(
          conteudo.textoRecomendacaoFinal,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
        ),
        if (conteudo.comparativo != null) ...[
          const SizedBox(height: AppSpacing.md),
          _ComparativoLaudo(comparativo: conteudo.comparativo!),
        ],
      ],
    );
  }
}

class _TituloSecao extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        'Diagnóstico e Recomendação',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _LinhaZona extends StatelessWidget {
  const _LinhaZona({required this.linha});

  final LinhaZonaDiagnosticoRecomendacaoLaudo linha;

  @override
  Widget build(BuildContext context) {
    final accent = MarcadoresZona.cor(linha.status);
    final base = Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ZonaIcon(status: linha.status, size: 11, color: accent),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                for (final t in linha.trechos)
                  TextSpan(
                    text: t.texto,
                    style: base?.copyWith(
                      fontWeight: t.negrito ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ComparativoLaudo extends StatelessWidget {
  const _ComparativoLaudo({required this.comparativo});

  final ComparativoLaudo comparativo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final header = theme.textTheme.labelSmall?.copyWith(
      color: colors.textSecondary,
      fontWeight: FontWeight.w400,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: SizedBox()),
            SizedBox(
              width: 72,
              child:
                  Text('Você gasta', style: header, textAlign: TextAlign.right),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Continua perdendo por aplicação',
                style: header,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        _LinhaComparativo(linha: comparativo.naoFazer),
        Divider(color: colors.border, height: 8),
        _LinhaComparativo(linha: comparativo.seguir),
        const SizedBox(height: AppSpacing.xs),
        Text(
          comparativo.rodape,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.textTertiary,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _LinhaComparativo extends StatelessWidget {
  const _LinhaComparativo({required this.linha});

  final LinhaComparativoLaudo linha;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final destaque = linha.valorPerdaDestaque > 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            linha.titulo,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        SizedBox(
          width: 72,
          child: Text(
            linha.voceGasta,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            linha.continuaPerdendo,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w400,
              color: destaque ? AppColors.zonaDesgaste : null,
            ),
          ),
        ),
      ],
    );
  }
}
