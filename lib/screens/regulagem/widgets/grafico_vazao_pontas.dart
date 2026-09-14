import 'dart:math' show max, min;

import 'package:flutter/material.dart';

import '../../../core/charts/vazao_chart_data.dart';
import '../../../models/regulagem.dart';
import '../../../theme.dart';

/// Gráfico "Vazão por ponta".
///
/// Cada barra sai da linha do ideal (100%) e cresce para cima quando a ponta
/// joga mais calda que o previsto, para baixo quando joga menos. A faixa verde
/// é o intervalo aceitável e a legenda explica as cores.
class GraficoVazaoPontas extends StatelessWidget {
  const GraficoVazaoPontas({
    super.key,
    required this.data,
    this.ladoConferencia = LadoConferenciaPontas.direita,
  });

  final VazaoChartData data;
  final LadoConferenciaPontas ladoConferencia;

  static const _alturaCanvas = 200.0;

  @override
  Widget build(BuildContext context) {
    if (data.vazio) return const SizedBox.shrink();

    final colors = AppThemeColors.of(context);
    final theme = Theme.of(context);
    final viewport = MediaQuery.sizeOf(context).width - AppSpacing.lg * 2;
    final larguraGrafico = VazaoChartLayout.canvasWidthFor(
      data.pontas.length,
      maxAvailable: max(viewport - AppSpacing.lg * 2, 0),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vazão por ponta', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtituloGraficoVazao(data),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.border),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: RepaintBoundary(
                  child: SizedBox(
                    width: larguraGrafico,
                    height: _alturaCanvas,
                    child: CustomPaint(
                      painter: _GraficoVazaoPainter(
                        data: data,
                        colors: colors,
                        ladoConferencia: ladoConferencia,
                        estiloBase: theme.textTheme.labelSmall ??
                            const TextStyle(fontFamily: 'Inter'),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _Legenda(data: data),
            ],
          ),
        ),
      ],
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda({required this.data});

  final VazaoChartData data;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        for (final status in data.statusMedidos)
          _LegendaItem(
            color: corDoStatus(status, colors),
            fundo: _fundoDaLegenda(status, colors),
            label: rotuloStatusPonta(status),
          ),
        if (data.temPendente)
          _LegendaItem(
            color: colors.textTertiary,
            fundo: colors.surfaceAlt,
            label: rotuloStatusPonta(StatusPonta.pendente),
            vazado: true,
          ),
      ],
    );
  }
}

Color _fundoDaLegenda(StatusPonta status, AppThemeColors colors) {
  return switch (status) {
    StatusPonta.ideal => colors.successLight,
    StatusPonta.irregular => colors.warningLight,
    StatusPonta.desgaste => colors.dangerLight,
    StatusPonta.pendente => colors.surfaceAlt,
  };
}

class _LegendaItem extends StatelessWidget {
  const _LegendaItem({
    required this.color,
    required this.fundo,
    required this.label,
    this.vazado = false,
  });

  final Color color;
  final Color fundo;
  final String label;
  final bool vazado;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: vazado ? null : color,
              borderRadius: BorderRadius.circular(2),
              border: vazado ? Border.all(color: color, width: 1.5) : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppThemeColors.of(context).textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

/// Cor da barra/legenda de cada status.
Color corDoStatus(StatusPonta status, AppThemeColors colors) {
  return switch (status) {
    StatusPonta.ideal => colors.success,
    StatusPonta.irregular => colors.warning,
    StatusPonta.desgaste => colors.danger,
    StatusPonta.pendente => colors.textTertiary,
  };
}

class _GraficoVazaoPainter extends CustomPainter {
  _GraficoVazaoPainter({
    required this.data,
    required this.colors,
    required this.ladoConferencia,
    required this.estiloBase,
  });

  final VazaoChartData data;
  final AppThemeColors colors;
  final LadoConferenciaPontas ladoConferencia;
  final TextStyle estiloBase;

  static const _fontSize = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = VazaoChartLayout.from(
      n: data.pontas.length,
      canvasWidth: size.width,
      canvasHeight: size.height,
    );
    if (data.vazio || layout.plotWidth <= 0 || layout.plotHeight <= 0) return;

    final yIdeal = layout.yFlutter(100, data);
    final yEntupido = layout.yFlutter(data.limiteIrregular, data);
    final yDesgaste = layout.yFlutter(data.limiteDesgaste, data);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(layout.left, yDesgaste, layout.right, yEntupido),
        const Radius.circular(4),
      ),
      Paint()..color = colors.success.withValues(alpha: 0.12),
    );

    canvas.drawLine(
      Offset(layout.left, yIdeal),
      Offset(layout.right, yIdeal),
      Paint()
        ..color = colors.success
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    _rotuloEixo(
        canvas, layout, '100%', yIdeal, colors.success, FontWeight.w600);

    for (var index = 0; index < data.pontas.length; index++) {
      final ponta = data.pontas[index];
      final centerX = layout.centerX(index);
      final medida = ponta.medida;

      _texto(
        canvas,
        rotuloPonta(ponta.id, ladoConferencia),
        centro: centerX,
        top: layout.plotBottomFlutter + 10,
        color: medida ? colors.textSecondary : colors.textTertiary,
      );

      final percentual = ponta.percentual;
      if (percentual == null) {
        canvas.drawCircle(
          Offset(centerX, yIdeal),
          4,
          Paint()
            ..color = colors.textTertiary
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke,
        );
        continue;
      }

      final cor = corDoStatus(ponta.status, colors);
      final yValor = layout.yFlutter(data.percentualNoEixo(percentual), data);
      final noIdeal = (percentual - 100).abs() < 0.5;
      final subiu = yValor <= yIdeal;
      final topo = noIdeal ? yIdeal - 3 : min(yValor, yIdeal);
      final altura = noIdeal ? 6.0 : max(3.0, (yValor - yIdeal).abs());
      final raio = Radius.circular(
        min(VazaoChartLayout.barRadius, altura / 2),
      );

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(
              centerX - layout.barWidth / 2, topo, layout.barWidth, altura),
          topLeft: subiu || noIdeal ? raio : Radius.zero,
          topRight: subiu || noIdeal ? raio : Radius.zero,
          bottomLeft: !subiu || noIdeal ? raio : Radius.zero,
          bottomRight: !subiu || noIdeal ? raio : Radius.zero,
        ),
        Paint()..color = cor,
      );

      if (!layout.mostraRotulosNasBarras) continue;

      _texto(
        canvas,
        '${percentual.toStringAsFixed(0)}%',
        centro: centerX,
        top: subiu
            ? topo - _fontSize - 5
            : min(topo + altura + 3, layout.plotBottomFlutter - _fontSize - 3),
        color: cor,
        peso: FontWeight.w600,
      );
    }
  }

  void _rotuloEixo(
    Canvas canvas,
    VazaoChartLayout layout,
    String texto,
    double y,
    Color color,
    FontWeight peso,
  ) {
    final painter = _painterDe(texto, color, peso);
    painter.paint(
      canvas,
      Offset(layout.left - 8 - painter.width, y - painter.height / 2),
    );
  }

  void _texto(
    Canvas canvas,
    String texto, {
    required double centro,
    required double top,
    required Color color,
    FontWeight peso = FontWeight.w400,
  }) {
    final painter = _painterDe(texto, color, peso);
    painter.paint(canvas, Offset(centro - painter.width / 2, top));
  }

  TextPainter _painterDe(String texto, Color color, FontWeight peso) {
    return TextPainter(
      text: TextSpan(
        text: texto,
        style: estiloBase.copyWith(
          fontSize: _fontSize,
          color: color,
          fontWeight: peso,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  bool shouldRepaint(covariant _GraficoVazaoPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.colors != colors ||
        oldDelegate.estiloBase != estiloBase;
  }
}
