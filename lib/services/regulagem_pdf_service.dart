import 'dart:math' show max, min;
import 'dart:typed_data';

import 'package:flutter/material.dart' show Color;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/charts/vazao_chart_data.dart';
import '../core/constants/app_constants.dart';
import '../core/extensions/double_extension.dart';
import '../core/utils/calculo_utils.dart';
import '../domain/calculos/calc_perda_zona_atencao.dart';
import '../models/configuracoes.dart';
import '../models/regulagem.dart';
import '../theme.dart';

class RegulagemPdfData {
  const RegulagemPdfData({
    required this.produtor,
    required this.fazenda,
    this.talhao,
    required this.maquina,
    this.consultor,
    required this.dataRegulagem,
    required this.vazaoLha,
    required this.velocidade,
    required this.espacamentoCm,
    required this.numeroPontas,
    this.pressaoBar,
    required this.litroMinIdeal,
    required this.medicoes,
    required this.configuracoes,
    required this.manejo,
    required this.precoBico,
    required this.area,
  });

  final String produtor;
  final String fazenda;
  final String? talhao;
  final String maquina;
  final String? consultor;
  final DateTime dataRegulagem;
  final double vazaoLha;
  final double velocidade;
  final double espacamentoCm;
  final int numeroPontas;
  final double? pressaoBar;
  final double litroMinIdeal;
  final List<PontaMedicao> medicoes;
  final Configuracoes configuracoes;
  final double manejo;
  final double precoBico;
  final double area;
}

class RegulagemPdfService {
  RegulagemPdfService._();

  static pw.Font? _regular;
  static pw.Font? _semiBold;
  static pw.Font? _bold;

  static Future<Uint8List> generate(RegulagemPdfData data) async {
    await _ensureFonts();
    final resumo = _ResumoPontasData.from(data);
    final economia = _EconomiaResumo.from(data);
    final orientacoes = _OrientacoesResumo.from(data.medicoes);
    final percentuais = _percentuaisPorPonta(data);

    final pdf = pw.Document(
      title: 'Laudo Técnico — Regulagem de Pulverizador',
      author: AppConstants.appName,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        theme: pw.ThemeData.withFont(
          base: _regular!,
          bold: _bold!,
        ),
        footer: (context) => _buildFooter(data, context),
        build: (context) {
          final chartFont = _regular!.getFont(context);
          final orientacoesWidget = _buildOrientacoes(orientacoes);
          return [
            _buildTitle(),
            pw.SizedBox(height: 16),
            _buildHeaderGrid(data),
            pw.SizedBox(height: 16),
            _buildMachineSummary(data),
            pw.SizedBox(height: 16),
            _buildStatusIndicators(resumo),
            pw.SizedBox(height: 16),
            _buildPontasTable(data, percentuais),
            if (economia.exibirResultado ||
                economia.zona.qtdPontasNaZona > 0) ...[
              pw.SizedBox(height: 20),
              _buildEconomiaSection(economia),
            ],
            pw.SizedBox(height: 20),
            _buildChart(data, chartFont),
            if (orientacoesWidget != null) ...[
              pw.SizedBox(height: 20),
              orientacoesWidget,
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  static String suggestedFilename(RegulagemPdfData data) {
    final base = data.fazenda.trim().isNotEmpty
        ? data.fazenda.trim()
        : data.produtor.trim();
    final sanitized = base
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]', unicode: true), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final slug = sanitized.isEmpty ? 'export' : sanitized;
    final date = DateFormat('yyyy-MM-dd').format(data.dataRegulagem);
    return 'regulagem_${slug}_$date.pdf';
  }

  static Future<void> _ensureFonts() async {
    if (_regular != null) return;
    final regularData = await rootBundle.load('assets/fonts/Inter-Regular.ttf');
    final semiBoldData =
        await rootBundle.load('assets/fonts/Inter-SemiBold.ttf');
    final boldData = await rootBundle.load('assets/fonts/Inter-Bold.ttf');
    _regular = pw.Font.ttf(regularData);
    _semiBold = pw.Font.ttf(semiBoldData);
    _bold = pw.Font.ttf(boldData);
  }

  static pw.Widget _buildTitle() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          AppConstants.appName,
          style: pw.TextStyle(
            font: _semiBold,
            fontSize: 12,
            color: _pdfColor(AppColors.primary),
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          height: 4,
          width: double.infinity,
          color: _pdfColor(AppColors.primary),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Laudo Técnico — Regulagem de Pulverizador',
          style: pw.TextStyle(font: _bold, fontSize: 17),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter(RegulagemPdfData data, pw.Context context) {
    final style = pw.TextStyle(
      font: _regular,
      fontSize: 8,
      color: _pdfColor(AppColors.textSecondary),
    );
    final dateStr =
        DateFormat('dd/MM/yyyy', 'pt_BR').format(data.dataRegulagem);
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(AppConstants.appName, style: style),
          pw.Text(
            'página ${context.pageNumber} de ${context.pagesCount}',
            style: style,
          ),
          pw.Text(dateStr, style: style),
        ],
      ),
    );
  }

  static pw.Widget _buildHeaderGrid(RegulagemPdfData data) {
    final dateStr =
        DateFormat('dd/MM/yyyy', 'pt_BR').format(data.dataRegulagem);
    final fields = <(String, String)>[
      ('Produtor', data.produtor),
      ('Fazenda', data.fazenda),
      ('Máquina', data.maquina),
      ('Data', dateStr),
    ];
    if (data.talhao != null && data.talhao!.trim().isNotEmpty) {
      fields.insert(2, ('Talhão', data.talhao!.trim()));
    }
    if (data.consultor != null && data.consultor!.trim().isNotEmpty) {
      fields.add(('Consultor', data.consultor!.trim()));
    }

    final rows = <List<(String, String)>>[];
    for (var i = 0; i < fields.length; i += 2) {
      final left = fields[i];
      final right = i + 1 < fields.length ? fields[i + 1] : ('', '');
      rows.add([left, right]);
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _pdfColor(AppColors.border)),
        borderRadius: pw.BorderRadius.circular(8),
        color: _pdfColor(AppColors.surfaceAlt),
      ),
      child: pw.Column(
        children: [
          for (final row in rows)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(child: _headerCell(row[0].$1, row[0].$2)),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: row[1].$1.isEmpty
                        ? pw.SizedBox()
                        : _headerCell(row[1].$1, row[1].$2),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _headerCell(String label, String value) {
    if (label.isEmpty) return pw.SizedBox();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: _regular,
            fontSize: 9,
            color: _pdfColor(AppColors.textSecondary),
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(font: _semiBold, fontSize: 11),
        ),
      ],
    );
  }

  static pw.Widget _buildMachineSummary(RegulagemPdfData data) {
    final items = <(String, String)>[
      ('Lt/min ideal', '${data.litroMinIdeal.toStringAsFixed(3)} L/min'),
      ('Vazão', '${data.vazaoLha.toStringAsFixed(1)} L/ha'),
      ('Velocidade', '${data.velocidade.toStringAsFixed(1)} km/h'),
      ('Espaçamento', '${data.espacamentoCm.toStringAsFixed(1)} cm'),
      ('Pontas', '${data.numeroPontas}'),
      if (data.pressaoBar != null)
        ('Pressão', '${data.pressaoBar!.toStringAsFixed(1)} bar'),
      if (data.area > 0) ('Área', '${data.area.toStringAsFixed(1)} ha'),
    ];

    const columns = 4;
    final rows = <List<(String, String)>>[];
    for (var i = 0; i < items.length; i += columns) {
      rows.add(items.sublist(i, min(i + columns, items.length)));
    }

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _pdfColor(AppColors.primaryLight),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          for (var r = 0; r < rows.length; r++)
            pw.Padding(
              padding: pw.EdgeInsets.only(bottom: r == rows.length - 1 ? 0 : 8),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  for (var c = 0; c < columns; c++)
                    pw.Expanded(
                      child: c < rows[r].length
                          ? _machineSummaryCell(rows[r][c].$1, rows[r][c].$2)
                          : pw.SizedBox(),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _machineSummaryCell(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: _regular,
            fontSize: 9,
            color: _pdfColor(AppColors.textSecondary),
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(font: _semiBold, fontSize: 12),
        ),
      ],
    );
  }

  static pw.Widget _buildStatusIndicators(_ResumoPontasData resumo) {
    final stats = [
      ('Ideal', resumo.ideal, AppColors.success, AppColors.successLight),
      ('Entupido', resumo.irregular, AppColors.warning, AppColors.warningLight),
      ('Desgaste', resumo.desgaste, AppColors.danger, AppColors.dangerLight),
    ];

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: stats
          .map(
            (stat) => pw.Expanded(
              child: pw.Container(
                margin: const pw.EdgeInsets.symmetric(horizontal: 2),
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: _pdfColor(stat.$4),
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(
                    color: _pdfColor(stat.$3).flatten(),
                  ),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      '${stat.$2}',
                      style: pw.TextStyle(
                        font: _bold,
                        fontSize: 16,
                        color: _pdfColor(stat.$3),
                      ),
                    ),
                    pw.Text(
                      stat.$1,
                      style: pw.TextStyle(
                        font: _regular,
                        fontSize: 8,
                        color: _pdfColor(AppColors.textSecondary),
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  static pw.Widget _buildPontasTable(
    RegulagemPdfData data,
    Map<int, double> percentuais,
  ) {
    final headerStyle = pw.TextStyle(
      font: _semiBold,
      fontSize: 9,
      color: _pdfColor(AppColors.textSecondary),
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Medições das pontas',
          style: pw.TextStyle(font: _semiBold, fontSize: 13),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder(
            top: pw.BorderSide(color: _pdfColor(AppColors.border), width: 0.5),
            bottom:
                pw.BorderSide(color: _pdfColor(AppColors.border), width: 0.5),
            horizontalInside:
                pw.BorderSide(color: _pdfColor(AppColors.border), width: 0.5),
          ),
          columnWidths: {
            0: const pw.FixedColumnWidth(28),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FixedColumnWidth(40),
            4: const pw.FlexColumnWidth(2.5),
          },
          children: [
            pw.TableRow(
              decoration:
                  pw.BoxDecoration(color: _pdfColor(AppColors.surfaceAlt)),
              children: [
                _tableHeaderCell('#', headerStyle),
                _tableHeaderCell('Medido (L/min)', headerStyle),
                _tableHeaderCell('Ideal', headerStyle),
                _tableHeaderCell('%', headerStyle, align: pw.TextAlign.right),
                _tableHeaderCell('Status', headerStyle),
              ],
            ),
            for (final ponta in data.medicoes)
              _buildPontaRow(
                  ponta, data.litroMinIdeal, percentuais[ponta.id] ?? 0),
          ],
        ),
      ],
    );
  }

  static pw.TableRow _buildPontaRow(
    PontaMedicao ponta,
    double ideal,
    double percentual,
  ) {
    final (bg, fg) = _statusColors(ponta.status);
    final medido = ponta.valorMedido?.toStringAsFixed(3) ?? '-';
    final pct = percentual == 0 ? '-' : percentual.toStringAsFixed(1);

    return pw.TableRow(
      children: [
        _tableCell('${ponta.id}'),
        _tableCell(medido),
        _tableCell(ideal.toStringAsFixed(3)),
        _tableCell(pct, align: pw.TextAlign.right),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: pw.Align(
            alignment: pw.Alignment.centerLeft,
            child: pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: pw.BoxDecoration(
                color: bg,
                borderRadius: pw.BorderRadius.circular(999),
              ),
              child: pw.Text(
                _statusLabel(ponta.status),
                style: pw.TextStyle(font: _semiBold, fontSize: 9, color: fg),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _tableHeaderCell(
    String text,
    pw.TextStyle style, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: style, textAlign: align),
    );
  }

  static pw.Widget _tableCell(String text,
      {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: _regular, fontSize: 9),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _buildEconomiaSection(_EconomiaResumo economia) {
    final recomendacao = economia.trocarTudo
        ? 'Troca completa recomendada'
        : 'Troca seletiva das pontas problemáticas';
    final recBg = economia.trocarTudo
        ? _pdfColor(AppColors.dangerLight)
        : _pdfColor(AppColors.successLight);
    final recFg = economia.trocarTudo
        ? _pdfColor(AppColors.danger)
        : _pdfColor(AppColors.success);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Análise econômica',
          style: pw.TextStyle(font: _semiBold, fontSize: 13),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: _pdfColor(AppColors.primaryLight),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            'Ponta R\$: ${economia.pontaRS.toMoeda()}',
            style: pw.TextStyle(font: _semiBold, fontSize: 11),
          ),
        ),
        pw.SizedBox(height: 6),
        if (economia.zona.qtdPontasNaZona > 0) ...[
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: _pdfColor(AppColors.orangeBackground),
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(
                color: _pdfColor(AppColors.orangeBorder).flatten(),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Zona de Atenção',
                  style: pw.TextStyle(
                    font: _semiBold,
                    fontSize: 11,
                    color: _pdfColor(AppColors.orangeText),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '${economia.zona.qtdPontasNaZona} ponta(s) entre 100% e o limite de desgaste',
                  style: pw.TextStyle(font: _regular, fontSize: 9),
                ),
                pw.Text(
                  'Prejuízo estimado: ${economia.zona.perdaEstimada.toMoeda()}',
                  style: pw.TextStyle(
                    font: _semiBold,
                    fontSize: 11,
                    color: _pdfColor(AppColors.orangeText),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 6),
        ],
        if (economia.exibirResultado) ...[
          pw.Row(
            children: [
              if (economia.perdaDesgaste > 0) ...[
                pw.Expanded(
                  child: _metricBox(
                    'Perda por desgaste',
                    economia.perdaDesgaste.toMoeda(),
                    AppColors.dangerLight,
                    AppColors.danger,
                  ),
                ),
                pw.SizedBox(width: 8),
              ],
              pw.Expanded(
                child: _metricBox(
                  'Custo de troca',
                  economia.custo.toMoeda(),
                  AppColors.infoLight,
                  AppColors.info,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: recBg,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: recFg.flatten()),
            ),
            child: pw.Text(
              recomendacao,
              style: pw.TextStyle(font: _semiBold, fontSize: 11, color: recFg),
            ),
          ),
        ],
      ],
    );
  }

  static pw.Widget _metricBox(
    String label,
    String value,
    Color bg,
    Color fg,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _pdfColor(bg),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _pdfColor(fg).flatten()),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: _regular,
              fontSize: 9,
              color: _pdfColor(AppColors.textSecondary),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
                font: _semiBold, fontSize: 11, color: _pdfColor(fg)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildChart(RegulagemPdfData data, PdfFont chartFont) {
    final chart = VazaoChartData.from(
      medicoes: data.medicoes,
      litroMinIdeal: data.litroMinIdeal,
      limiteIrregular: data.configuracoes.limiteIrregular,
      limiteDesgaste: data.configuracoes.limiteDesgaste,
    );
    if (chart.vazio) return pw.SizedBox();

    // Ocupa toda a largura útil da página, descontando a borda do cartão.
    final chartWidth = PdfPageFormat.a4.width - 72 - 16;
    const chartHeight = 172.0;
    final subtitle = 'Ideal ${data.litroMinIdeal.toLitroMin()} = 100%. '
        'Faixa verde ${chart.limiteIrregular.toStringAsFixed(0)}–${chart.limiteDesgaste.toStringAsFixed(0)}% é aceitável.';

    // Mantém título, gráfico e legenda na mesma página do laudo.
    return pw.Inseparable(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Vazão por ponta',
            style: pw.TextStyle(font: _semiBold, fontSize: 13),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            subtitle,
            style: pw.TextStyle(
              font: _regular,
              fontSize: 9,
              color: _pdfColor(AppColors.textSecondary),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _pdfColor(AppColors.border)),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: chartWidth,
                  height: chartHeight,
                  child: pw.CustomPaint(
                    size: PdfPoint(chartWidth, chartHeight),
                    painter: (canvas, size) {
                      _paintChart(
                        canvas: canvas,
                        size: size,
                        chart: chart,
                        font: chartFont,
                      );
                    },
                  ),
                ),
                pw.SizedBox(height: 6),
                _buildChartLegenda(chart),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildChartLegenda(VazaoChartData chart) {
    final itens = <({PdfColor cor, String rotulo, bool vazado})>[
      for (final status in chart.statusMedidos)
        (
          cor: _statusBarColor(status),
          rotulo: rotuloStatusPonta(status),
          vazado: false,
        ),
      if (chart.temPendente)
        (
          cor: _pdfColor(AppColors.textTertiary),
          rotulo: rotuloStatusPonta(StatusPonta.pendente),
          vazado: true,
        ),
    ];

    return pw.Row(
      children: [
        for (final item in itens)
          pw.Padding(
            padding: const pw.EdgeInsets.only(right: 12),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 6,
                  height: 6,
                  decoration: pw.BoxDecoration(
                    color: item.vazado ? null : item.cor,
                    borderRadius: pw.BorderRadius.circular(3),
                    border: item.vazado ? pw.Border.all(color: item.cor) : null,
                  ),
                ),
                pw.SizedBox(width: 4),
                pw.Text(
                  item.rotulo,
                  style: pw.TextStyle(
                    font: _regular,
                    fontSize: 8,
                    color: _pdfColor(AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Desenha o mesmo gráfico da tela de regulagem.
  ///
  /// Atenção: no PDF o eixo Y cresce de baixo para cima, ao contrário do
  /// `Canvas` do Flutter — todas as coordenadas aqui são medidas a partir da
  /// base do gráfico.
  static void _paintChart({
    required PdfGraphics canvas,
    required PdfPoint size,
    required VazaoChartData chart,
    required PdfFont font,
  }) {
    const leftPad = 40.0;
    const rightPad = 10.0;
    const topPad = 20.0;
    const bottomPad = 26.0;
    const fontSize = 8.0;

    final chartW = size.x - leftPad - rightPad;
    final chartH = size.y - topPad - bottomPad;
    if (chart.vazio || chartW <= 0 || chartH <= 0) return;

    double yDe(double percentual) =>
        bottomPad +
        ((percentual - chart.minPercent) / chart.amplitude) * chartH;

    final yIdeal = yDe(100);
    final yEntupido = yDe(chart.limiteIrregular);
    final yDesgaste = yDe(chart.limiteDesgaste);

    // No PDF `setFillColor` ignora o alfa: as cores translúcidas precisam ser
    // achatadas sobre o branco.
    canvas
      ..setFillColor(_pdfColorWithAlpha(AppColors.success, 0.10).flatten())
      ..drawRect(leftPad, yEntupido, chartW, yDesgaste - yEntupido)
      ..fillPath();

    _paintLinhaTracejada(
      canvas,
      leftPad,
      chartW,
      yDesgaste,
      _pdfColorWithAlpha(AppColors.danger, 0.45).flatten(),
    );
    _paintLinhaTracejada(
      canvas,
      leftPad,
      chartW,
      yEntupido,
      _pdfColorWithAlpha(AppColors.warning, 0.45).flatten(),
    );

    canvas
      ..setStrokeColor(_pdfColor(AppColors.success))
      ..setLineWidth(1.2)
      ..moveTo(leftPad, yIdeal)
      ..lineTo(leftPad + chartW, yIdeal)
      ..strokePath()
      ..setStrokeColor(_pdfColor(AppColors.border))
      ..setLineWidth(0.8)
      ..moveTo(leftPad, bottomPad)
      ..lineTo(leftPad + chartW, bottomPad)
      ..strokePath();

    // Um limite colado no ideal teria o rótulo sobreposto: nesse caso só o
    // ideal é escrito.
    const folga = 11.0;
    _paintChartYLabel(canvas, font, '100%', yIdeal, AppColors.success);
    if ((yDesgaste - yIdeal).abs() >= folga) {
      _paintChartYLabel(
        canvas,
        font,
        '${chart.limiteDesgaste.toStringAsFixed(0)}%',
        yDesgaste,
        AppColors.textTertiary,
      );
    }
    if ((yEntupido - yIdeal).abs() >= folga) {
      _paintChartYLabel(
        canvas,
        font,
        '${chart.limiteIrregular.toStringAsFixed(0)}%',
        yEntupido,
        AppColors.textTertiary,
      );
    }

    final slotWidth = chartW / chart.pontas.length;
    final barWidth = min(20.0, slotWidth * 0.52);

    for (var index = 0; index < chart.pontas.length; index++) {
      final ponta = chart.pontas[index];
      final centerX = leftPad + slotWidth * index + slotWidth / 2;

      _paintChartLabel(
        canvas,
        font,
        '${ponta.id}',
        centerX,
        bottomPad - 12,
        ponta.medida ? AppColors.textSecondary : AppColors.textTertiary,
      );

      final percentual = ponta.percentual;
      if (percentual == null) {
        canvas
          ..setStrokeColor(_pdfColor(AppColors.textTertiary))
          ..setLineWidth(1)
          ..drawEllipse(centerX, yIdeal, 3.5, 3.5)
          ..strokePath();
        continue;
      }

      final yValor = yDe(chart.percentualNoEixo(percentual));
      final subiu = yValor >= yIdeal;
      final base = min(yValor, yIdeal);
      final altura = max(2.0, (yValor - yIdeal).abs());

      canvas
        ..setFillColor(_statusBarColor(ponta.status))
        ..drawRRect(centerX - barWidth / 2, base, barWidth, altura, 3, 3)
        ..fillPath();

      _paintChartLabel(
        canvas,
        font,
        '${percentual.toStringAsFixed(0)}%',
        centerX,
        subiu
            ? base + altura + 3
            : max(base - fontSize - 2, bottomPad + fontSize / 2),
        _statusLabelColor(ponta.status),
      );
    }
  }

  static void _paintLinhaTracejada(
    PdfGraphics canvas,
    double xInicial,
    double largura,
    double y,
    PdfColor cor,
  ) {
    canvas
      ..setStrokeColor(cor)
      ..setLineWidth(0.8)
      ..setLineDashPattern([3, 3])
      ..moveTo(xInicial, y)
      ..lineTo(xInicial + largura, y)
      ..strokePath()
      ..setLineDashPattern();
  }

  static void _paintChartYLabel(
    PdfGraphics canvas,
    PdfFont font,
    String text,
    double y,
    Color color,
  ) {
    const fontSize = 8.0;
    final metrics = font.stringMetrics(text) * fontSize;
    canvas
      ..setFillColor(_pdfColor(color))
      ..drawString(font, fontSize, text, 32 - metrics.width, y - 3);
  }

  static void _paintChartLabel(
    PdfGraphics canvas,
    PdfFont font,
    String text,
    double centerX,
    double y,
    Color color,
  ) {
    const fontSize = 8.0;
    final metrics = font.stringMetrics(text) * fontSize;
    canvas
      ..setFillColor(_pdfColor(color))
      ..drawString(font, fontSize, text, centerX - metrics.width / 2, y);
  }

  static pw.Widget? _buildOrientacoes(_OrientacoesResumo resumo) {
    final cards = [
      (
        resumo.ideal,
        'Ideal',
        'Sem ação imediata. Continue o monitoramento.',
        AppColors.success,
        AppColors.successLight,
      ),
      (
        resumo.irregular,
        'Entupido',
        'Limpar bicos e repetir teste. Verifique filtro e calda.',
        AppColors.warning,
        AppColors.warningLight,
      ),
      (
        resumo.desgaste,
        'Desgaste',
        'Substituir urgentemente. Excesso de vazão compromete a aplicação.',
        AppColors.danger,
        AppColors.dangerLight,
      ),
    ].where((card) => card.$1 > 0).toList();

    if (cards.isEmpty) return null;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Orientações',
          style: pw.TextStyle(font: _semiBold, fontSize: 13),
        ),
        pw.SizedBox(height: 8),
        for (final card in cards)
          pw.Container(
            width: double.infinity,
            margin: const pw.EdgeInsets.only(bottom: 6),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: _pdfColor(card.$5),
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: _pdfColor(card.$4).flatten()),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${card.$1} ponta(s) ${card.$2}',
                  style: pw.TextStyle(
                    font: _semiBold,
                    fontSize: 11,
                    color: _pdfColor(card.$4),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  card.$3,
                  style: pw.TextStyle(font: _regular, fontSize: 10),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static Map<int, double> _percentuaisPorPonta(RegulagemPdfData data) {
    return {
      for (final item in data.medicoes)
        item.id: item.valorMedido == null
            ? 0
            : CalcUtils.calcularPercentualPonta(
                valorMedido: item.valorMedido!,
                litroMinIdeal: data.litroMinIdeal,
              ),
    };
  }

  static String _statusLabel(StatusPonta status) {
    return switch (status) {
      StatusPonta.ideal => 'Ideal',
      StatusPonta.irregular => 'Entupido',
      StatusPonta.desgaste => 'Desgaste',
      StatusPonta.pendente => 'Pendente',
    };
  }

  static (PdfColor bg, PdfColor fg) _statusColors(StatusPonta status) {
    return switch (status) {
      StatusPonta.ideal => (
          _pdfColor(AppColors.successLight),
          _pdfColor(AppColors.success),
        ),
      StatusPonta.irregular => (
          _pdfColor(AppColors.warningLight),
          _pdfColor(AppColors.warning),
        ),
      StatusPonta.desgaste => (
          _pdfColor(AppColors.dangerLight),
          _pdfColor(AppColors.danger),
        ),
      StatusPonta.pendente => (
          _pdfColor(AppColors.surfaceAlt),
          _pdfColor(AppColors.textTertiary),
        ),
    };
  }

  static PdfColor _statusBarColor(StatusPonta status) {
    return _pdfColor(_statusLabelColor(status));
  }

  static Color _statusLabelColor(StatusPonta status) {
    return switch (status) {
      StatusPonta.ideal => AppColors.success,
      StatusPonta.irregular => AppColors.warning,
      StatusPonta.desgaste => AppColors.danger,
      StatusPonta.pendente => AppColors.textTertiary,
    };
  }

  static PdfColor _pdfColor(Color color) {
    return PdfColor.fromInt(color.toARGB32());
  }

  static PdfColor _pdfColorWithAlpha(Color color, double alpha) {
    return PdfColor(color.r, color.g, color.b, alpha);
  }
}

class _ResumoPontasData {
  const _ResumoPontasData({
    required this.desgaste,
    required this.irregular,
    required this.ideal,
  });

  factory _ResumoPontasData.from(RegulagemPdfData data) {
    return _ResumoPontasData(
      desgaste: data.medicoes
          .where((item) => item.status == StatusPonta.desgaste)
          .length,
      irregular: data.medicoes
          .where((item) => item.status == StatusPonta.irregular)
          .length,
      ideal: data.medicoes
          .where((item) => item.status == StatusPonta.ideal)
          .length,
    );
  }

  final int desgaste;
  final int irregular;
  final int ideal;
}

class _EconomiaResumo {
  const _EconomiaResumo({
    required this.perdaTotal,
    required this.perdaDesgaste,
    required this.custo,
    required this.pontaRS,
    required this.trocarTudo,
    required this.zona,
  });

  factory _EconomiaResumo.from(RegulagemPdfData data) {
    final limite = data.configuracoes.limiteDesgaste;
    var perdaTotal = 0.0;
    var perdaDesgaste = 0.0;
    final percentuais = <double>[];
    for (final item in data.medicoes) {
      if (item.valorMedido == null) continue;
      final percentual = CalcUtils.calcularPercentualPonta(
        valorMedido: item.valorMedido!,
        litroMinIdeal: data.litroMinIdeal,
      );
      percentuais.add(percentual);
      final perda = CalcUtils.calcularPerdaEstimada(
        percentual: percentual,
        manejoRS: data.manejo,
        numeroPontas: data.medicoes.length,
        areaHa: data.area,
      );
      perdaTotal += perda;
      if (percentual > limite) {
        perdaDesgaste += perda;
      }
    }
    final custo = CalcUtils.calcularCustoTrocaTotal(
      precoBicoRS: data.precoBico,
      numeroPontas: data.medicoes.length,
    );
    final pontaRS = CalcUtils.calcularPontaRS(
      manejoRS: data.manejo,
      numeroPontas: data.medicoes.length,
    );
    final zona = CalcUtils.calcularPerdaZonaAtencao(
      percentuais: percentuais,
      manejoRS: data.manejo,
      numeroPontas: data.medicoes.length,
      areaHa: data.area,
      limiteDesgaste: limite,
    );

    return _EconomiaResumo(
      perdaTotal: perdaTotal,
      perdaDesgaste: perdaDesgaste,
      custo: custo,
      pontaRS: pontaRS,
      trocarTudo: CalcUtils.recomendarTrocaCompleta(
        perdaEstimadaTotal: perdaTotal,
        custoTrocaTotal: custo,
      ),
      zona: zona,
    );
  }

  final double perdaTotal;
  final double perdaDesgaste;
  final double custo;
  final double pontaRS;
  final bool trocarTudo;
  final ResultadoZonaAtencao zona;

  bool get exibirResultado => perdaTotal > 0 && custo > 0;
}

class _OrientacoesResumo {
  const _OrientacoesResumo({
    required this.ideal,
    required this.irregular,
    required this.desgaste,
  });

  factory _OrientacoesResumo.from(List<PontaMedicao> medicoes) {
    return _OrientacoesResumo(
      ideal: medicoes.where((item) => item.status == StatusPonta.ideal).length,
      irregular:
          medicoes.where((item) => item.status == StatusPonta.irregular).length,
      desgaste:
          medicoes.where((item) => item.status == StatusPonta.desgaste).length,
    );
  }

  final int ideal;
  final int irregular;
  final int desgaste;
}
