import 'dart:io';
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
import '../models/perfil_relatorio.dart';
import '../models/foto_regulagem.dart';
import '../models/regulagem.dart';
import '../theme.dart';
import 'fotos_regulagem_service.dart';

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
    this.ladoConferenciaPontas = LadoConferenciaPontas.direita,
    required this.configuracoes,
    required this.manejo,
    required this.precoBico,
    required this.area,
    this.fotos = const [],
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
  final LadoConferenciaPontas ladoConferenciaPontas;
  final Configuracoes configuracoes;
  final double manejo;
  final double precoBico;
  final double area;
  final List<FotoRegulagem> fotos;
}

class RegulagemPdfService {
  RegulagemPdfService._();

  static pw.Font? _regular;
  static pw.Font? _semiBold;
  static pw.Font? _bold;

  static Future<Uint8List> generate(
    RegulagemPdfData data, {
    FotosRegulagemService? fotosService,
  }) async {
    await _ensureFonts();
    final resumo = _ResumoPontasData.from(data);
    final economia = _EconomiaResumo.from(data);
    final orientacoes = _OrientacoesResumo.from(data.medicoes);
    final percentuais = _percentuaisPorPonta(data);
    final fotosWidget = await _buildFotosSection(
      data.fotos,
      fotosService: fotosService,
    );
    final perfil = data.configuracoes.perfilRelatorio;
    final logoBytes = await _loadImageBytes(perfil.logoPath);
    final assinaturaBytes = await _loadImageBytes(perfil.assinaturaPath);

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
        footer: (context) =>
            _buildFooter(data, context, assinaturaBytes: assinaturaBytes),
        build: (context) {
          final chartFont = _regular!.getFont(context);
          final orientacoesWidget = _buildOrientacoes(orientacoes);
          return [
            if (_temBrandingPerfil(perfil, logoBytes))
              ...[
                _buildPerfilBranding(perfil, logoBytes),
                pw.SizedBox(height: 12),
              ],
            _buildTitle(),
            pw.SizedBox(height: 16),
            _buildHeaderGrid(data, perfil),
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
            if (fotosWidget != null) ...[
              pw.SizedBox(height: 20),
              fotosWidget,
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

  static pw.Widget _buildFooter(
    RegulagemPdfData data,
    pw.Context context, {
    Uint8List? assinaturaBytes,
  }) {
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
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(AppConstants.appName, style: style),
          pw.Text(
            'página ${context.pageNumber} de ${context.pagesCount}',
            style: style,
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (assinaturaBytes != null) ...[
                pw.Image(
                  pw.MemoryImage(assinaturaBytes),
                  width: 72,
                  height: 28,
                  fit: pw.BoxFit.contain,
                ),
                pw.Text('Assinatura', style: style),
              ] else
                pw.Text(dateStr, style: style),
            ],
          ),
        ],
      ),
    );
  }

  static bool _temBrandingPerfil(
    PerfilRelatorio perfil,
    Uint8List? logoBytes,
  ) {
    return logoBytes != null ||
        perfil.empresaNome.trim().isNotEmpty ||
        perfil.nomeConsultor.trim().isNotEmpty;
  }

  static pw.Widget _buildPerfilBranding(
    PerfilRelatorio perfil,
    Uint8List? logoBytes,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (logoBytes != null)
          pw.Container(
            margin: const pw.EdgeInsets.only(right: 10),
            child: pw.Image(
              pw.MemoryImage(logoBytes),
              width: 44,
              height: 44,
              fit: pw.BoxFit.contain,
            ),
          ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (perfil.empresaNome.trim().isNotEmpty)
                pw.Text(
                  perfil.empresaNome.trim(),
                  style: pw.TextStyle(font: _semiBold, fontSize: 13),
                ),
              if (perfil.nomeConsultor.trim().isNotEmpty)
                pw.Text(
                  perfil.nomeConsultor.trim(),
                  style: pw.TextStyle(
                    font: _regular,
                    fontSize: 10,
                    color: _pdfColor(AppColors.textSecondary),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static Future<Uint8List?> _loadImageBytes(String? path) async {
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  static pw.Widget _buildHeaderGrid(
    RegulagemPdfData data,
    PerfilRelatorio perfil,
  ) {
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
    final consultor = data.consultor?.trim().isNotEmpty == true
        ? data.consultor!.trim()
        : perfil.nomeConsultor.trim();
    if (consultor.isNotEmpty) {
      fields.add(('Consultor', consultor));
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
                ponta,
                data.litroMinIdeal,
                percentuais[ponta.id] ?? 0,
                data.ladoConferenciaPontas,
              ),
          ],
        ),
      ],
    );
  }

  static pw.TableRow _buildPontaRow(
    PontaMedicao ponta,
    double ideal,
    double percentual,
    LadoConferenciaPontas lado,
  ) {
    final (bg, fg) = _statusColors(ponta.status);
    final medido = ponta.valorMedido?.toStringAsFixed(3) ?? '-';
    final pct = percentual == 0 ? '-' : percentual.toStringAsFixed(1);

    return pw.TableRow(
      children: [
        _tableCell(rotuloPonta(ponta.id, lado)),
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
          if (economia.perdaTolerancia > 0) ...[
            _metricBox(
              'Perda por Tolerância',
              economia.perdaTolerancia.toMoeda(),
              AppColors.infoLight,
              AppColors.info,
            ),
            pw.SizedBox(height: 6),
          ],
          if (economia.perdaDesgaste > 0) ...[
            _metricBox(
              'Perda por Desgaste',
              economia.perdaDesgaste.toMoeda(),
              AppColors.dangerLight,
              AppColors.danger,
            ),
            pw.SizedBox(height: 6),
          ],
          _metricBox(
            'Perda Total Estimada',
            economia.perdaTotal.toMoeda(),
            AppColors.primaryLight,
            AppColors.primary,
          ),
          pw.SizedBox(height: 6),
          _metricBox(
            'Custo de troca',
            economia.custo.toMoeda(),
            AppColors.infoLight,
            AppColors.info,
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

    final pageWidth = PdfPageFormat.a4.width - 72 - 16;
    final chartWidth = VazaoChartLayout.canvasWidthFor(
      chart.pontas.length,
      maxAvailable: pageWidth,
      podeEstourar: false,
    );
    const chartHeight = 176.0;

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
            subtituloGraficoVazao(chart),
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
                        ladoConferencia: data.ladoConferenciaPontas,
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

    return pw.Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final item in itens)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: pw.BoxDecoration(
              color: item.vazado
                  ? _pdfColor(AppColors.surfaceAlt)
                  : _legendaFundo(item.rotulo),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Container(
                  width: 6,
                  height: 6,
                  decoration: pw.BoxDecoration(
                    color: item.vazado ? null : item.cor,
                    borderRadius: pw.BorderRadius.circular(2),
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

  static PdfColor _legendaFundo(String rotulo) {
    return switch (rotulo) {
      'Ideal' => _pdfColor(AppColors.successLight),
      'Entupido' => _pdfColor(AppColors.warningLight),
      'Desgaste' => _pdfColor(AppColors.dangerLight),
      _ => _pdfColor(AppColors.surfaceAlt),
    };
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
    required LadoConferenciaPontas ladoConferencia,
  }) {
    final layout = VazaoChartLayout.from(
      n: chart.pontas.length,
      canvasWidth: size.x,
      canvasHeight: size.y,
    );
    if (chart.vazio || layout.plotWidth <= 0 || layout.plotHeight <= 0) {
      return;
    }

    const fontSize = 8.0;
    final yIdeal = layout.yPdf(100, chart);
    final yEntupido = layout.yPdf(chart.limiteIrregular, chart);
    final yDesgaste = layout.yPdf(chart.limiteDesgaste, chart);

    // No PDF `setFillColor` ignora o alfa: as cores translúcidas precisam ser
    // achatadas sobre o branco.
    canvas
      ..setFillColor(_pdfColorWithAlpha(AppColors.success, 0.12).flatten())
      ..drawRRect(
        layout.left,
        yEntupido,
        layout.plotWidth,
        yDesgaste - yEntupido,
        3,
        3,
      )
      ..fillPath();

    canvas
      ..setStrokeColor(_pdfColor(AppColors.success))
      ..setLineWidth(1.2)
      ..setLineCap(PdfLineCap.round)
      ..moveTo(layout.left, yIdeal)
      ..lineTo(layout.right, yIdeal)
      ..strokePath();

    _paintChartYLabel(
      canvas,
      font,
      '100%',
      layout.left,
      yIdeal,
      AppColors.success,
    );

    for (var index = 0; index < chart.pontas.length; index++) {
      final ponta = chart.pontas[index];
      final centerX = layout.centerX(index);

      _paintChartLabel(
        canvas,
        font,
        rotuloPonta(ponta.id, ladoConferencia),
        centerX,
        VazaoChartLayout.bottomPad - 12,
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

      final yValor = layout.yPdf(chart.percentualNoEixo(percentual), chart);
      final noIdeal = (percentual - 100).abs() < 0.5;
      final subiu = yValor >= yIdeal;
      final base = noIdeal ? yIdeal - 3 : min(yValor, yIdeal);
      final altura = noIdeal ? 6.0 : max(3.0, (yValor - yIdeal).abs());
      final raio = min(VazaoChartLayout.barRadius, altura / 2);

      canvas
        ..setFillColor(_statusBarColor(ponta.status))
        ..drawRRect(
          centerX - layout.barWidth / 2,
          base,
          layout.barWidth,
          altura,
          raio,
          raio,
        )
        ..fillPath();

      if (!layout.mostraRotulosNasBarras) continue;

      _paintChartLabel(
        canvas,
        font,
        '${percentual.toStringAsFixed(0)}%',
        centerX,
        subiu
            ? base + altura + 3
            : max(
                base - fontSize - 2, VazaoChartLayout.bottomPad + fontSize / 2),
        _statusLabelColor(ponta.status),
      );
    }
  }

  static void _paintChartYLabel(
    PdfGraphics canvas,
    PdfFont font,
    String text,
    double left,
    double y,
    Color color,
  ) {
    const fontSize = 8.0;
    final metrics = font.stringMetrics(text) * fontSize;
    canvas
      ..setFillColor(_pdfColor(color))
      ..drawString(font, fontSize, text, left - 8 - metrics.width, y - 3);
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

  static Future<pw.Widget?> _buildFotosSection(
    List<FotoRegulagem> fotos, {
    FotosRegulagemService? fotosService,
  }) async {
    if (fotos.isEmpty) return null;

    final service = fotosService ?? FotosRegulagemService();
    final itens = <({FotoRegulagem foto, Uint8List bytes})>[];
    for (final foto in fotos) {
      final file = await service.resolverArquivo(foto);
      if (!await file.exists()) continue;
      itens.add((foto: foto, bytes: await file.readAsBytes()));
    }
    if (itens.isEmpty) return null;

    final rows = <pw.Widget>[];
    for (var i = 0; i < itens.length; i += 2) {
      rows.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: _buildFotoCelula(itens[i])),
            if (i + 1 < itens.length) ...[
              pw.SizedBox(width: 12),
              pw.Expanded(child: _buildFotoCelula(itens[i + 1])),
            ] else
              pw.Spacer(),
          ],
        ),
      );
      if (i + 2 < itens.length) {
        rows.add(pw.SizedBox(height: 12));
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Fotos da Regulagem',
          style: pw.TextStyle(font: _semiBold, fontSize: 13),
        ),
        pw.SizedBox(height: 8),
        ...rows,
      ],
    );
  }

  static pw.Widget _buildFotoCelula(
      ({FotoRegulagem foto, Uint8List bytes}) item) {
    final titulo = item.foto.titulo?.trim();
    final observacao = item.foto.observacao?.trim();
    final legenda = <pw.Widget>[];

    if (titulo != null && titulo.isNotEmpty) {
      legenda.add(
        pw.Text(
          titulo,
          style: pw.TextStyle(font: _semiBold, fontSize: 10),
        ),
      );
    }
    if (observacao != null && observacao.isNotEmpty) {
      if (legenda.isNotEmpty) legenda.add(pw.SizedBox(height: 2));
      legenda.add(
        pw.Text(
          observacao,
          style: pw.TextStyle(
            font: _regular,
            fontSize: 9,
            color: _pdfColor(AppColors.textSecondary),
          ),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.ClipRRect(
          horizontalRadius: 6,
          verticalRadius: 6,
          child: pw.SizedBox(
            height: 140,
            child: pw.Image(
              pw.MemoryImage(item.bytes),
              fit: pw.BoxFit.cover,
            ),
          ),
        ),
        if (legenda.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          ...legenda,
        ],
      ],
    );
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
    required this.perdaTolerancia,
    required this.perdaDesgaste,
    required this.custo,
    required this.pontaRS,
    required this.trocarTudo,
    required this.zona,
  });

  factory _EconomiaResumo.from(RegulagemPdfData data) {
    final limite = data.configuracoes.limiteDesgaste;
    final percentuais = data.medicoes
        .where((item) => item.valorMedido != null)
        .map(
          (item) => CalcUtils.calcularPercentualPonta(
            valorMedido: item.valorMedido!,
            litroMinIdeal: data.litroMinIdeal,
          ),
        )
        .toList();
    final resultado = CalcUtils.analisarEconomia(
      percentuais: percentuais,
      manejoRS: data.manejo,
      numeroPontas: data.medicoes.length,
      areaHa: data.area,
      precoBicoRS: data.precoBico,
      limiteDesgaste: limite,
    );
    final zona = CalcUtils.calcularPerdaZonaAtencao(
      percentuais: percentuais,
      manejoRS: data.manejo,
      numeroPontas: data.medicoes.length,
      areaHa: data.area,
      limiteDesgaste: limite,
    );

    return _EconomiaResumo(
      perdaTotal: resultado.perdaTotal,
      perdaTolerancia: resultado.perdaTolerancia,
      perdaDesgaste: resultado.perdaDesgaste,
      custo: resultado.custoTrocaTotal,
      pontaRS: resultado.pontaRS,
      trocarTudo: resultado.recomendarTroca,
      zona: zona,
    );
  }

  final double perdaTotal;
  final double perdaTolerancia;
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
