import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/marcadores_zona.dart';
import '../models/regulagem.dart';

/// Desenho vetorial dos marcadores de zona no PDF (mesmas formas da tela).
class PdfMarcadorZona {
  static PdfColor pdfCor(StatusPonta status) {
    return PdfColor.fromInt(MarcadoresZona.cor(status).toARGB32());
  }

  static pw.Widget widget(StatusPonta status, {double size = 11}) {
    final cor = pdfCor(status);
    return pw.SizedBox(
      width: size,
      height: size,
      child: pw.CustomPaint(
        size: PdfPoint(size, size),
        painter: (canvas, s) => desenhar(canvas, status, s.x, s.y, cor),
      ),
    );
  }

  static void desenhar(
    PdfGraphics canvas,
    StatusPonta status,
    double w,
    double h,
    PdfColor color,
  ) {
    final cx = w / 2;
    final cy = h / 2;
    final pad = w * 0.12;

    switch (status) {
      case StatusPonta.irregular:
        canvas.setFillColor(color);
        canvas
          ..moveTo(cx, h - pad)
          ..lineTo(pad, pad)
          ..lineTo(w - pad, pad)
          ..closePath()
          ..fillPath();
      case StatusPonta.desgaste:
        canvas.setFillColor(color);
        canvas
          ..moveTo(cx, pad)
          ..lineTo(pad, h - pad)
          ..lineTo(w - pad, h - pad)
          ..closePath()
          ..fillPath();
      case StatusPonta.ideal:
        canvas.setFillColor(color);
        canvas.drawEllipse(cx, cy, w / 2 - pad, h / 2 - pad);
        canvas.fillPath();
      case StatusPonta.atencao:
        canvas.setFillColor(color);
        canvas
          ..moveTo(cx, pad)
          ..lineTo(w - pad, cy)
          ..lineTo(cx, h - pad)
          ..lineTo(pad, cy)
          ..closePath()
          ..fillPath();
      case StatusPonta.pendente:
        canvas
          ..setStrokeColor(color)
          ..setLineWidth(1.1);
        canvas.drawEllipse(cx, cy, w / 2 - pad, h / 2 - pad);
        canvas.strokePath();
    }
  }

  static pw.Widget legendaCompacta({double size = 10}) {
    return pw.Wrap(
      spacing: 10,
      runSpacing: 4,
      children: [
        for (var i = 0; i < MarcadoresZona.ordemLegenda.length; i++) ...[
          if (i > 0)
            pw.Text(
              ' · ',
              style: pw.TextStyle(fontSize: 8),
            ),
          pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              widget(MarcadoresZona.ordemLegenda[i], size: size),
              pw.SizedBox(width: 3),
              pw.Text(
                MarcadoresZona.rotulo(MarcadoresZona.ordemLegenda[i]),
                style: pw.TextStyle(fontSize: 8),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
