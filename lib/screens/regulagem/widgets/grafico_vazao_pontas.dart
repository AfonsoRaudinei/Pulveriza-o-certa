import 'dart:math' show max, min;

import 'package:flutter/material.dart';

import '../../../core/charts/vazao_chart_data.dart';
import '../../../core/extensions/double_extension.dart';
import '../../../models/regulagem.dart';
import '../../../theme.dart';

/// Gráfico "Vazão por ponta".
///
/// Cada barra sai da linha do ideal (100%) e cresce para cima quando a ponta
/// joga mais calda que o previsto, para baixo quando joga menos. A faixa verde
/// é o intervalo aceitável e a legenda explica as cores.
class GraficoVazaoPontas extends StatelessWidget {
  const GraficoVazaoPontas({super.key, required this.data});

  final VazaoChartData data;

  static const _alturaCanvas = 196.0;

  /// Largura mínima de cada ponta: abaixo disso o gráfico rola na horizontal.
  static const _larguraSlot = 34.0;

  @override
  Widget build(BuildContext context) {
    if (data.vazio) return const SizedBox.shrink();

    final colors = AppThemeColors.of(context);
    final theme = Theme.of(context);
    final viewport = MediaQuery.sizeOf(context).width - AppSpacing.lg * 2;
    final larguraGrafico = max(
      viewport - AppSpacing.md * 2,
      data.pontas.length * _larguraSlot + _GraficoVazaoPainter.leftPad,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vazão por ponta', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Ideal ${data.litroMinIdeal.toLitroMin()} = 100%. '
          'Faixa verde ${data.limiteIrregular.toStringAsFixed(0)}–${data.limiteDesgaste.toStringAsFixed(0)}% é aceitável.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.border),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: larguraGrafico,
                  height: _alturaCanvas,
                  child: CustomPaint(
                    painter: _GraficoVazaoPainter(
                      data: data,
                      colors: colors,
                      // Os rótulos desenhados no canvas não herdam o tema.
                      estiloBase: theme.textTheme.labelSmall ??
                          const TextStyle(fontFamily: 'Inter'),
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
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        for (final status in data.statusMedidos)
          _LegendaItem(
            color: corDoStatus(status, colors),
            label: rotuloStatusPonta(status),
          ),
        if (data.temPendente)
          _LegendaItem(
            color: colors.textTertiary,
            label: rotuloStatusPonta(StatusPonta.pendente),
            vazado: true,
          ),
      ],
    );
  }
}

class _LegendaItem extends StatelessWidget {
  const _LegendaItem({
    required this.color,
    required this.label,
    this.vazado = false,
  });

  final Color color;
  final String label;
  final bool vazado;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: vazado ? null : color,
            shape: BoxShape.circle,
            border: vazado ? Border.all(color: color, width: 1.5) : null,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: AppThemeColors.of(context).textSecondary),
        ),
      ],
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
    required this.estiloBase,
  });

  final VazaoChartData data;
  final AppThemeColors colors;
  final TextStyle estiloBase;

  static const leftPad = 44.0;
  static const _rightPad = 12.0;
  static const _topPad = 22.0;
  static const _bottomPad = 26.0;
  static const _fontSize = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final chartW = size.width - leftPad - _rightPad;
    final chartH = size.height - _topPad - _bottomPad;
    if (data.vazio || chartW <= 0 || chartH <= 0) return;

    final base = _topPad + chartH;
    double yDe(double percentual) =>
        base - ((percentual - data.minPercent) / data.amplitude) * chartH;

    final yIdeal = yDe(100);
    final yEntupido = yDe(data.limiteIrregular);
    final yDesgaste = yDe(data.limiteDesgaste);

    canvas.drawRect(
      Rect.fromLTRB(leftPad, yDesgaste, leftPad + chartW, yEntupido),
      Paint()..color = colors.success.withValues(alpha: 0.10),
    );

    final tracejado = Paint()
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    _linhaTracejada(
      canvas,
      yDesgaste,
      leftPad,
      chartW,
      tracejado..color = colors.danger.withValues(alpha: 0.45),
    );
    _linhaTracejada(
      canvas,
      yEntupido,
      leftPad,
      chartW,
      tracejado..color = colors.warning.withValues(alpha: 0.45),
    );

    canvas.drawLine(
      Offset(leftPad, yIdeal),
      Offset(leftPad + chartW, yIdeal),
      Paint()
        ..color = colors.success
        ..strokeWidth = 1.5,
    );

    canvas.drawLine(
      Offset(leftPad, base),
      Offset(leftPad + chartW, base),
      Paint()
        ..color = colors.border
        ..strokeWidth = 1,
    );

    _rotulosDoEixo(canvas, yIdeal, yEntupido, yDesgaste);

    final slotWidth = chartW / data.pontas.length;
    final barWidth = min(22.0, slotWidth * 0.52);

    for (var index = 0; index < data.pontas.length; index++) {
      final ponta = data.pontas[index];
      final centerX = leftPad + slotWidth * index + slotWidth / 2;
      final medida = ponta.medida;

      _texto(
        canvas,
        '${ponta.id}',
        centro: centerX,
        top: base + 10,
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
      final yValor = yDe(data.percentualNoEixo(percentual));
      final subiu = yValor <= yIdeal;
      final topo = min(yValor, yIdeal);
      final altura = max(2.5, (yValor - yIdeal).abs());
      const raio = Radius.circular(4);

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(centerX - barWidth / 2, topo, barWidth, altura),
          topLeft: subiu ? raio : Radius.zero,
          topRight: subiu ? raio : Radius.zero,
          bottomLeft: subiu ? Radius.zero : raio,
          bottomRight: subiu ? Radius.zero : raio,
        ),
        Paint()..color = cor,
      );

      _texto(
        canvas,
        '${percentual.toStringAsFixed(0)}%',
        centro: centerX,
        // Barra cortada no piso do eixo: mantém o rótulo dentro da área do
        // gráfico para não colidir com o número da ponta.
        top: subiu
            ? topo - _fontSize - 6
            : min(topo + altura + 4, base - _fontSize - 4),
        color: cor,
        peso: FontWeight.w600,
      );
    }
  }

  /// Só desenha o rótulo de um limite quando ele não encosta no rótulo do
  /// ideal — era isso que fazia dois números se sobreporem no eixo.
  void _rotulosDoEixo(
    Canvas canvas,
    double yIdeal,
    double yEntupido,
    double yDesgaste,
  ) {
    const folga = 13.0;
    _rotuloEixo(canvas, '100%', yIdeal, colors.success, FontWeight.w600);
    if ((yDesgaste - yIdeal).abs() >= folga) {
      _rotuloEixo(
        canvas,
        '${data.limiteDesgaste.toStringAsFixed(0)}%',
        yDesgaste,
        colors.textTertiary,
        FontWeight.w400,
      );
    }
    if ((yEntupido - yIdeal).abs() >= folga) {
      _rotuloEixo(
        canvas,
        '${data.limiteIrregular.toStringAsFixed(0)}%',
        yEntupido,
        colors.textTertiary,
        FontWeight.w400,
      );
    }
  }

  void _rotuloEixo(
    Canvas canvas,
    String texto,
    double y,
    Color color,
    FontWeight peso,
  ) {
    final painter = _painterDe(texto, color, peso);
    painter.paint(
      canvas,
      Offset(leftPad - 8 - painter.width, y - painter.height / 2),
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

  void _linhaTracejada(
    Canvas canvas,
    double y,
    double xInicial,
    double largura,
    Paint paint,
  ) {
    const traco = 4.0;
    const vao = 4.0;
    var x = xInicial;
    final fim = xInicial + largura;
    while (x < fim) {
      final proximo = min(x + traco, fim);
      canvas.drawLine(Offset(x, y), Offset(proximo, y), paint);
      x = proximo + vao;
    }
  }

  @override
  bool shouldRepaint(covariant _GraficoVazaoPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.colors != colors ||
        oldDelegate.estiloBase != estiloBase;
  }
}
