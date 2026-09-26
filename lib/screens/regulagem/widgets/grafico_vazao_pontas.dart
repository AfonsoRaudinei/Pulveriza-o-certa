import 'dart:math' show max, min;

import 'package:flutter/material.dart';

import '../../../core/charts/vazao_chart_data.dart';
import '../../../core/formatters/laudo_numero_format.dart';
import '../../../core/iconografia/zona_icon.dart';
import '../../../core/zona_visual.dart';
import '../../../models/regulagem.dart';
import '../../../theme.dart';
import '../../../widgets/secao_laudo_titulo.dart';

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
        SecaoLaudoTitulo(
          titulo: 'Vazão por ponta',
          subtitulo: subtituloGraficoVazao(data),
        ),
        const SizedBox(height: AppSpacing.md),
        Column(
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
      ],
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda({required this.data});

  final VazaoChartData data;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        for (final status in data.statusMedidos)
          _LegendaItem(
            status: status,
            label: rotuloStatusPonta(status),
          ),
        if (data.temPendente)
          _LegendaItem(
            status: StatusPonta.pendente,
            label: rotuloStatusPonta(StatusPonta.pendente),
          ),
      ],
    );
  }
}

/// Cor da barra de cada status.
Color corDoStatus(StatusPonta status, AppThemeColors colors) {
  return corZona(status);
}

class _LegendaItem extends StatelessWidget {
  const _LegendaItem({
    required this.status,
    required this.label,
  });

  final StatusPonta status;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ZonaIcon(status: status, size: 11),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppThemeColors.of(context).textSecondary,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
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

    if (data.limiteIrregular < 100) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(layout.left, yIdeal, layout.right, yEntupido),
          const Radius.circular(4),
        ),
        Paint()..color = AppColors.zonaIdeal.withValues(alpha: 0.16),
      );
    }
    if (data.limiteDesgaste > 100) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(layout.left, yDesgaste, layout.right, yIdeal),
          const Radius.circular(4),
        ),
        Paint()..color = AppColors.zonaAtencao.withValues(alpha: 0.14),
      );
    }

    canvas.drawLine(
      Offset(layout.left, yIdeal),
      Offset(layout.right, yIdeal),
      Paint()
        ..color = colors.textSecondary
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    _rotuloEixo(
        canvas, layout, '100%', yIdeal, colors.textSecondary, FontWeight.w600);
    _rotuloIdealReferencia(canvas, layout, yIdeal, colors.textSecondary);

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

      final rotuloTop = subiu
          ? topo - _fontSize * 2 - 6
          : min(
              topo + altura + 3, layout.plotBottomFlutter - _fontSize * 2 - 2);
      _texto(
        canvas,
        LaudoNumeroFormat.percentual(percentual, casas: 1),
        centro: centerX,
        top: rotuloTop,
        color: cor,
        peso: FontWeight.w600,
      );
    }
  }

  void _rotuloIdealReferencia(
    Canvas canvas,
    VazaoChartLayout layout,
    double yIdeal,
    Color color,
  ) {
    final texto = LaudoNumeroFormat.rotuloIdealGrafico(data.litroMinIdeal);
    final painter = _painterDe(texto, color, FontWeight.w500);
    painter.paint(
      canvas,
      Offset(layout.right + 6, yIdeal - painter.height / 2),
    );
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
        oldDelegate.ladoConferencia != ladoConferencia ||
        oldDelegate.estiloBase != estiloBase;
  }
}
