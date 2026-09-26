import 'package:flutter/material.dart';

import '../../models/regulagem.dart';
import '../marcadores_zona.dart';

/// Marcador geométrico sólido da zona (▼ ● ◆ ▲ ○), vetorial, 10–12 pt.
class ZonaIcon extends StatelessWidget {
  const ZonaIcon({
    super.key,
    required this.status,
    this.size = 11,
    this.color,
  });

  final StatusPonta status;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cor = color ?? MarcadoresZona.cor(status);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ZonaMarcadorPainter(status: status, color: cor),
      ),
    );
  }
}

class _ZonaMarcadorPainter extends CustomPainter {
  _ZonaMarcadorPainter({required this.status, required this.color});

  final StatusPonta status;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    paintMarcadorZona(canvas, size, status, color);
  }

  @override
  bool shouldRepaint(covariant _ZonaMarcadorPainter oldDelegate) {
    return oldDelegate.status != status || oldDelegate.color != color;
  }
}

void paintMarcadorZona(
  Canvas canvas,
  Size size,
  StatusPonta status,
  Color color,
) {
  final fill = Paint()
    ..color = color
    ..style = PaintingStyle.fill;
  final stroke = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = size.shortestSide * 0.12;

  final w = size.width;
  final h = size.height;
  final cx = w / 2;
  final cy = h / 2;
  final pad = size.shortestSide * 0.12;

  switch (status) {
    case StatusPonta.irregular:
      final path = Path()
        ..moveTo(cx, h - pad)
        ..lineTo(pad, pad)
        ..lineTo(w - pad, pad)
        ..close();
      canvas.drawPath(path, fill);
    case StatusPonta.desgaste:
      final path = Path()
        ..moveTo(cx, pad)
        ..lineTo(pad, h - pad)
        ..lineTo(w - pad, h - pad)
        ..close();
      canvas.drawPath(path, fill);
    case StatusPonta.ideal:
      canvas.drawCircle(Offset(cx, cy), w / 2 - pad, fill);
    case StatusPonta.atencao:
      final path = Path()
        ..moveTo(cx, pad)
        ..lineTo(w - pad, cy)
        ..lineTo(cx, h - pad)
        ..lineTo(pad, cy)
        ..close();
      canvas.drawPath(path, fill);
    case StatusPonta.pendente:
      canvas.drawCircle(Offset(cx, cy), w / 2 - pad, stroke);
  }
}
