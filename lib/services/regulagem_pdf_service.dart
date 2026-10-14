import 'dart:math' show max, min, pi;

import 'package:vector_math/vector_math_64.dart' show Matrix4;
import 'dart:typed_data';

import 'package:flutter/material.dart' show Color;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/charts/vazao_chart_data.dart';
import '../core/charts/vazao_chart_pdf_plan.dart';
import '../core/constants/app_constants.dart';
import '../core/formatters/laudo_numero_format.dart';
import '../core/layout_faixa_cabecalho_laudo.dart';
import '../core/marca_cabecalho_laudo.dart';
import '../domain/calculos/subtitulos_laudo_pdf.dart';
import '../core/extensions/double_extension.dart';
import '../core/utils/calculo_utils.dart';
import '../core/zona_visual.dart';
import '../domain/calculos/calc_diagnostico_regulagem.dart';
import '../domain/calculos/calc_diagnostico_recomendacao_laudo.dart';
import '../domain/calculos/calc_layout_laudo_pdf.dart';
import '../domain/calculos/calc_texto_analise_economica_laudo.dart';
import '../domain/calculos/texto_pontas.dart';
import '../models/configuracoes.dart';
import '../models/marca_pdf.dart';
import '../models/tipo_cabecalho_laudo.dart';
import '../models/foto_regulagem.dart';
import '../models/regulagem.dart';
import '../theme.dart';
import 'fotos_regulagem_service.dart';
import 'pdf_marcador_zona.dart';
import 'soloforte_logo_pdf_service.dart';

class RegulagemPdfData {
  const RegulagemPdfData({
    required this.produtor,
    required this.fazenda,
    this.talhao,
    this.cultura,
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
    this.numeroAplicacoes,
    this.tipoPonta,
    this.fotos = const [],
    this.marcaLogoBytes,
    this.marcaFundoCabecalhoBytes,
  });

  final String produtor;
  final String fazenda;
  final String? talhao;
  final CulturaCultivo? cultura;
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
  final int? numeroAplicacoes;
  final TipoPontaBico? tipoPonta;
  final List<FotoRegulagem> fotos;
  final Uint8List? marcaLogoBytes;
  final Uint8List? marcaFundoCabecalhoBytes;
}

class RegulagemPdfService {
  RegulagemPdfService._();

  static pw.Font? _regular;
  static pw.Font? _semiBold;
  static pw.Font? _bold;

  static const _corTituloOrientacao = PdfColor.fromInt(0xFF1D1D1F);
  static const _corDescricaoOrientacao = PdfColor.fromInt(0xFF86868B);
  static const _corTextoRodapeLaudo = PdfColor.fromInt(0xFF86868B);

  static Future<Uint8List> generate(
    RegulagemPdfData data, {
    FotosRegulagemService? fotosService,
    bool carregarLogoRodape = true,
  }) async {
    await _ensureFonts();
    final logoRodape = carregarLogoRodape
        ? await SoloForteLogoPdfService.carregarParaPdf()
        : null;
    final diagnostico = DiagnosticoRegulagem.calcular(
      medicoes: data.medicoes,
      litroMinIdeal: data.litroMinIdeal,
      limites: data.configuracoes.limitesRegulagem,
      lado: data.ladoConferenciaPontas,
      manejoRS: data.manejo,
      precoBicoRS: data.precoBico,
      areaHa: data.area,
      numeroAplicacoes: data.numeroAplicacoes,
      tipoPonta: data.tipoPonta,
    );
    final percentuais = _percentuaisPorPonta(data);
    final fotosWidgets = await _buildFotosSectionWidgets(
      data.fotos,
      medicoes: data.medicoes,
      fotosService: fotosService,
    );

    final pdf = pw.Document(
      title: 'Laudo Técnico — Regulagem de Pulverizador',
      author: AppConstants.pdfDocumentAuthor,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 48),
        theme: pw.ThemeData.withFont(
          base: _regular!,
          bold: _bold!,
        ),
        footer: (context) => _buildFooter(
          data,
          context,
          logoRodape: logoRodape,
        ),
        build: (context) {
          final chartFont = _regular!.getFont(context);
          return [
            _buildTitle(data),
            pw.SizedBox(height: 8),
            _buildFichaLabeled(data),
            if (diagnostico.avisoMedicao != null) ...[
              pw.SizedBox(height: 8),
              _avisoIncompleta(diagnostico),
            ],
            pw.SizedBox(height: 8),
            _buildMachineSummary(data, diagnostico),
            pw.SizedBox(height: 10),
            _buildStatusIndicators(diagnostico, data),
            pw.SizedBox(height: 10),
            ..._buildPontasTable(data, percentuais, diagnostico),
            pw.SizedBox(height: 8),
            _buildLegendaMarcadores(),
            pw.SizedBox(height: 10),
            ..._buildCharts(data, chartFont),
            _buildAnaliseEconomicaLaudo(diagnostico),
            pw.SizedBox(height: 14),
            _buildDiagnosticoRecomendacaoLaudo(diagnostico),
            if (fotosWidgets.isNotEmpty) ...[
              pw.SizedBox(height: 12),
              ...fotosWidgets,
            ],
            pw.SizedBox(height: 12),
            _buildComoCalculamos(diagnostico),
            pw.SizedBox(height: 10),
            _buildAssinaturaProfissional(data),
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
    return 'Laudo_Regulagem_${slug}_$date.pdf';
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

  static const _overlayImagemCabecalhoPdf = PdfColor.fromInt(0x8A000000);

  static pw.Widget _buildTitle(RegulagemPdfData data) {
    final config = data.configuracoes;
    final marca = config.textoMarcaCabecalho();
    final corTexto = textoSobreCabecalhoLaudo(config);
    final linha = _conteudoLinhaCabecalho(data, marca, corTexto);
    final padding = pw.EdgeInsets.symmetric(
      horizontal: LayoutFaixaCabecalhoLaudo.paddingHorizontal,
      vertical: LayoutFaixaCabecalhoLaudo.paddingVertical,
    );
    final raio = pw.BorderRadius.circular(LayoutFaixaCabecalhoLaudo.raioBorda);

    final pw.Widget faixa = switch (config.tipoCabecalhoLaudo) {
      TipoCabecalhoLaudo.solida => pw.Container(
          width: double.infinity,
          padding: padding,
          decoration: pw.BoxDecoration(
            color: _pdfColor(corMarcaCabecalhoLaudo(config)),
            borderRadius: raio,
          ),
          child: linha,
        ),
      TipoCabecalhoLaudo.gradiente => pw.Container(
          width: double.infinity,
          padding: padding,
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              begin: pw.Alignment.centerLeft,
              end: pw.Alignment.centerRight,
              colors: [
                _pdfColor(corMarcaGradienteInicioLaudo(config)),
                _pdfColor(corMarcaGradienteFimLaudo(config)),
              ],
            ),
            borderRadius: raio,
          ),
          child: linha,
        ),
      TipoCabecalhoLaudo.imagem => _faixaCabecalhoImagem(
          data: data,
          linha: linha,
          config: config,
          padding: padding,
          raio: raio,
        ),
    };

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        faixa,
        pw.SizedBox(height: 8),
        pw.Text(
          'Laudo Técnico — Regulagem de Pulverizador',
          style: pw.TextStyle(font: _bold, fontSize: 17),
        ),
      ],
    );
  }

  static pw.Widget _faixaCabecalhoImagem({
    required RegulagemPdfData data,
    required pw.Widget linha,
    required Configuracoes config,
    required pw.EdgeInsets padding,
    required pw.BorderRadius raio,
  }) {
    final bytes = data.marcaFundoCabecalhoBytes;
    if (bytes == null || bytes.isEmpty) {
      return pw.Container(
        width: double.infinity,
        padding: padding,
        decoration: pw.BoxDecoration(
          color: _pdfColor(corMarcaCabecalhoLaudo(config)),
          borderRadius: raio,
        ),
        child: linha,
      );
    }

    final raioPt = LayoutFaixaCabecalhoLaudo.raioBorda;
    return pw.ClipRRect(
      horizontalRadius: raioPt,
      verticalRadius: raioPt,
      child: pw.Stack(
        alignment: pw.Alignment.centerLeft,
        children: [
          pw.SizedBox(
            width: double.infinity,
            height: LayoutFaixaCabecalhoLaudo.alturaFaixaImagem(config),
            child: pw.Image(
              pw.MemoryImage(bytes),
              fit: pw.BoxFit.cover,
            ),
          ),
          pw.Positioned.fill(
            child: pw.Container(color: _overlayImagemCabecalhoPdf),
          ),
          pw.Padding(padding: padding, child: linha),
        ],
      ),
    );
  }

  static pw.Widget _conteudoLinhaCabecalho(
    RegulagemPdfData data,
    String marca,
    Color corTexto,
  ) {
    final config = data.configuracoes;
    final linhaContato = config.linhaContatoPerfilLaudo();
    final corSecundaria = _corTextoSecundarioSobreCabecalhoPdf(corTexto);

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (data.marcaLogoBytes != null)
          pw.Container(
            padding: const pw.EdgeInsets.all(2),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Image(
              pw.MemoryImage(data.marcaLogoBytes!),
              height: 24,
              fit: pw.BoxFit.contain,
            ),
          ),
        if (data.marcaLogoBytes != null) pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                marca,
                style: pw.TextStyle(
                  font: _semiBold,
                  fontSize: 12,
                  color: _pdfColor(corTexto),
                ),
              ),
              if (linhaContato != null) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  linhaContato,
                  style: pw.TextStyle(
                    font: _regular,
                    fontSize: 9,
                    color: corSecundaria,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static PdfColor _corTextoSecundarioSobreCabecalhoPdf(Color corPrimaria) {
    if (corPrimaria.computeLuminance() > 0.55) {
      return _corDescricaoOrientacao;
    }
    return _pdfColorWithAlpha(corPrimaria, 0.72);
  }

  static const _alturaLogoRodape = SoloForteLogoPdfService.alturaExibicaoPt;

  static pw.Widget _buildFooter(
    RegulagemPdfData data,
    pw.Context context, {
    Uint8List? logoRodape,
  }) {
    final style = pw.TextStyle(
      font: _regular,
      fontSize: 8,
      color: _corTextoRodapeLaudo,
    );
    final dateStr =
        DateFormat('dd/MM/yyyy', 'pt_BR').format(data.dataRegulagem);

    pw.Widget marcaEsquerda;
    if (logoRodape != null && logoRodape.isNotEmpty) {
      marcaEsquerda = pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Image(
            pw.MemoryImage(logoRodape),
            height: _alturaLogoRodape,
            fit: pw.BoxFit.contain,
          ),
          pw.SizedBox(width: 5),
          pw.Text(AppConstants.nomeMarcaRodapePdf, style: style),
        ],
      );
    } else {
      marcaEsquerda = pw.Text(AppConstants.nomeMarcaRodapePdf, style: style);
    }

    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          height: 0.5,
          width: double.infinity,
          color: _pdfColor(AppColors.border),
        ),
        pw.SizedBox(height: 6),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Expanded(child: marcaEsquerda),
            pw.Text(
              'página ${context.pageNumber} de ${context.pagesCount}',
              style: style,
              textAlign: pw.TextAlign.center,
            ),
            pw.Expanded(
              child: pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(dateStr, style: style),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildFichaLabeled(RegulagemPdfData data) {
    final dateStr =
        DateFormat('dd/MM/yyyy', 'pt_BR').format(data.dataRegulagem);
    final marcaCabecalho = data.configuracoes.textoMarcaCabecalho();
    final consultor = data.consultor?.trim() ?? '';
    final consultorVisivel = consultor.isNotEmpty && consultor != marcaCabecalho
        ? consultor
        : consultor;
    final linhas = montarLinhasFichaCabecalhoLaudo(
      produtor: data.produtor,
      fazenda: data.fazenda,
      talhao: data.talhao,
      cultura: data.cultura?.label,
      maquina: data.maquina,
      consultor: consultorVisivel,
      data: dateStr,
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Table(
          children: [
            for (final linha in linhas)
              pw.TableRow(
                children: [
                  _fichaCelula(linha.$1.$1, linha.$1.$2),
                  if (linha.$2 != null)
                    _fichaCelula(linha.$2!.$1, linha.$2!.$2)
                  else
                    pw.SizedBox(),
                ],
              ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          data.configuracoes.limitesRegulagem.linhaCabecalho,
          style: pw.TextStyle(
            font: _regular,
            fontSize: 9,
            color: _pdfColor(AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  static pw.Widget _fichaCelula(String label, String value) {
    final texto = value.isEmpty ? '—' : value;
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6, right: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: _regular,
              fontSize: 8,
              color: _pdfColor(AppColors.textSecondary),
            ),
          ),
          pw.Text(
            texto,
            style: pw.TextStyle(font: _semiBold, fontSize: 10),
          ),
        ],
      ),
    );
  }

  static pw.Widget _avisoIncompleta(DiagnosticoRegulagem diagnostico) {
    return pw.Text(
      '${diagnostico.avisoMedicao} — análise parcial',
      style: pw.TextStyle(
        font: _semiBold,
        fontSize: 10,
        color: _pdfColor(AppColors.zonaAtencao),
      ),
    );
  }

  static pw.Widget _buildMachineSummary(
    RegulagemPdfData data,
    DiagnosticoRegulagem diagnostico,
  ) {
    final dadosCalculo = montarDadosCalculoLaudo(
      manejoRS: diagnostico.manejoRS,
      manejoPorPonta: diagnostico.manejoPorPonta,
      precoBicoRS: diagnostico.precoBicoRS,
      areaHa: diagnostico.areaHa,
    );

    final items = <(String, String)>[
      ('L/min ideal', LaudoNumeroFormat.litroMin(data.litroMinIdeal)),
      ('Vazão', LaudoNumeroFormat.vazaoLha(data.vazaoLha)),
      ('Velocidade', LaudoNumeroFormat.kmh(data.velocidade)),
      ('Espaçamento', LaudoNumeroFormat.cm(data.espacamentoCm)),
      ('Pontas', '${data.numeroPontas}'),
      if (data.pressaoBar != null)
        ('Pressão', LaudoNumeroFormat.bar(data.pressaoBar!)),
      if (data.area > 0) ('Área', LaudoNumeroFormat.hectares(data.area)),
      ('Custo do defensivo por ha', dadosCalculo.manejoPorHa),
      ('Produto por ponta', dadosCalculo.manejoPorPonta),
      ('Preço do bico', dadosCalculo.precoBico),
    ];

    const columns = 4;
    final rows = <List<(String, String)>>[];
    for (var i = 0; i < items.length; i += columns) {
      rows.add(items.sublist(i, min(i + columns, items.length)));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _secaoTitulo(
          titulo: 'Parâmetros da regulagem',
          subtitulo: SubtitulosLaudoPdf.parametros,
        ),
        pw.SizedBox(height: 8),
        pw.Column(
          children: [
            for (var r = 0; r < rows.length; r++)
              pw.Padding(
                padding: pw.EdgeInsets.only(
                  bottom: r == rows.length - 1 ? 0 : 8,
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    for (var c = 0; c < columns; c++)
                      pw.Expanded(
                        child: c < rows[r].length
                            ? _machineSummaryCell(
                                rows[r][c].$1,
                                rows[r][c].$2,
                              )
                            : pw.SizedBox(),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ],
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
            fontSize: 8,
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

  static pw.Widget _buildStatusIndicators(
    DiagnosticoRegulagem diagnostico,
    RegulagemPdfData data,
  ) {
    final zonas = diagnostico.zonasVisiveis;
    if (zonas.isEmpty) return pw.SizedBox();
    const divisor = PdfColor.fromInt(0xFFE5E5E7);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _secaoTitulo(
          titulo: 'Resumo das zonas',
          subtitulo: SubtitulosLaudoPdf.zonas,
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            for (var i = 0; i < zonas.length; i++) ...[
              if (i > 0)
                pw.Container(
                  width: 1,
                  height: 44,
                  color: divisor,
                ),
              pw.Expanded(
                child: _statusStatCell(
                  zona: zonas[i],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  static pw.Widget _statusStatCell({required ZonaDiagnostico zona}) {
    return pw.Column(
      children: [
        PdfMarcadorZona.widget(zona.status, size: 11),
        pw.SizedBox(height: 4),
        pw.Text(
          '${zona.quantidade}',
          style: pw.TextStyle(
            font: _semiBold,
            fontSize: 18,
            color: _corTituloOrientacao,
          ),
        ),
        pw.Text(
          rotuloZona(zona.status),
          style: pw.TextStyle(
            font: _semiBold,
            fontSize: 9,
            color: _corTituloOrientacao,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.Text(
          zona.faixa,
          style: pw.TextStyle(
            font: _regular,
            fontSize: 8.5,
            color: _pdfColor(AppColors.textSecondary),
          ),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  static pw.Widget _secaoTitulo({
    required String titulo,
    String? subtitulo,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          titulo,
          style: pw.TextStyle(font: _semiBold, fontSize: 13),
        ),
        if (subtitulo != null) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            subtitulo,
            style: pw.TextStyle(
              font: _regular,
              fontSize: 8.5,
              color: _pdfColor(AppColors.textSecondary),
            ),
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildLegendaMarcadores() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 4),
        PdfMarcadorZona.legendaCompacta(size: 10),
      ],
    );
  }

  /// Largura mínima da coluna # (ex.: 20D, 22D) sem quebra de linha.
  static const _larguraColunaRotuloPonta = 46.0;
  static const _larguraColunaPercentual = 50.0;

  /// Título e tabela em widgets separados para a tabela poder quebrar entre páginas.
  static List<pw.Widget> _buildPontasTable(
    RegulagemPdfData data,
    Map<int, double> percentuais,
    DiagnosticoRegulagem diagnostico,
  ) {
    final statusPorId = {
      for (final ponta in diagnostico.pontas) ponta.id: ponta.status,
    };
    final headerStyle = pw.TextStyle(
      font: _semiBold,
      fontSize: 9,
      color: _pdfColor(AppColors.textSecondary),
    );

    return [
      _secaoTitulo(
        titulo: 'Medições das pontas',
        subtitulo: SubtitulosLaudoPdf.tabela,
      ),
      pw.SizedBox(height: 8),
      pw.Table(
        border: pw.TableBorder(
          top: pw.BorderSide(color: _pdfColor(AppColors.border), width: 0.5),
          bottom: pw.BorderSide(color: _pdfColor(AppColors.border), width: 0.5),
          horizontalInside:
              pw.BorderSide(color: _pdfColor(AppColors.border), width: 0.5),
        ),
        columnWidths: {
          0: const pw.FixedColumnWidth(_larguraColunaRotuloPonta),
          1: const pw.FlexColumnWidth(3),
          2: const pw.FlexColumnWidth(2.5),
          3: const pw.FixedColumnWidth(_larguraColunaPercentual),
          4: const pw.FlexColumnWidth(3),
        },
        children: [
          pw.TableRow(
            repeat: true,
            children: [
              _tableHeaderCellRotulo('#', headerStyle),
              _tableHeaderCell('Medido (L/min)', headerStyle),
              _tableHeaderCell('Ideal', headerStyle),
              _tableHeaderCellRotulo(
                '%',
                headerStyle,
                align: pw.TextAlign.right,
              ),
              _tableHeaderCell('Status', headerStyle),
            ],
          ),
          for (final ponta in data.medicoes)
            _buildPontaRow(
              ponta,
              data.litroMinIdeal,
              percentuais[ponta.id] ?? 0,
              data.ladoConferenciaPontas,
              statusPorId[ponta.id] ??
                  (ponta.valorMedido == null
                      ? StatusPonta.pendente
                      : ponta.status),
            ),
        ],
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        legendaLadosPontasLaudo(
          numeroPontas: data.medicoes.length,
          ladoConferencia: data.ladoConferenciaPontas,
        ),
        style: pw.TextStyle(
          font: _regular,
          fontSize: 8,
          color: _pdfColor(AppColors.textSecondary),
        ),
      ),
    ];
  }

  static pw.TableRow _buildPontaRow(
    PontaMedicao ponta,
    double ideal,
    double percentual,
    LadoConferenciaPontas lado,
    StatusPonta status,
  ) {
    final medido = ponta.valorMedido == null
        ? '-'
        : LaudoNumeroFormat.decimal(ponta.valorMedido!, casas: 3);
    final pct = percentual == 0
        ? '-'
        : LaudoNumeroFormat.percentual(percentual, casas: 1);

    return pw.TableRow(
      children: [
        _tableCellRotuloPonta(rotuloPonta(ponta.id, lado)),
        _tableCell(medido),
        _tableCell(LaudoNumeroFormat.decimal(ideal, casas: 3)),
        _tableCellDestaque(
          pct,
          cor: percentual == 0
              ? _pdfColor(AppColors.textSecondary)
              : _pdfColor(_statusLabelColor(status)),
          align: pw.TextAlign.right,
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: pw.Row(
            children: [
              PdfMarcadorZona.widget(status, size: 11),
              pw.SizedBox(width: 4),
              pw.Text(
                rotuloZona(status),
                style: pw.TextStyle(
                  font: _semiBold,
                  fontSize: 9,
                  color: _pdfColor(_statusLabelColor(status)),
                ),
              ),
            ],
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

  static pw.Widget _tableHeaderCellRotulo(
    String text,
    pw.TextStyle style, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: style,
        textAlign: align,
        softWrap: false,
        maxLines: 1,
      ),
    );
  }

  static pw.Widget _tableCellRotuloPonta(String rotulo) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        rotulo,
        style: pw.TextStyle(font: _regular, fontSize: 9),
        softWrap: false,
        maxLines: 1,
      ),
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

  static pw.Widget _tableCellDestaque(
    String text, {
    required PdfColor cor,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: _semiBold, fontSize: 9, color: cor),
        textAlign: align,
        softWrap: false,
        maxLines: 1,
      ),
    );
  }

  static pw.Widget _buildAnaliseEconomicaLaudo(DiagnosticoRegulagem d) {
    final blocos = montarBlocosAnaliseEconomicaLaudo(d);
    if (blocos.mensagemIncompleta != null) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _secaoTitulo(titulo: 'Análise econômica'),
          pw.SizedBox(height: 8),
          pw.Text(
            blocos.mensagemIncompleta!,
            style: pw.TextStyle(
              font: _regular,
              fontSize: 10,
              height: 1.45,
              color: _pdfColor(AppColors.textPrimary),
            ),
          ),
        ],
      );
    }

    final corDestaque = blocos.perdaTotal > 0
        ? _pdfColor(AppColors.iosDestructive)
        : _pdfColor(AppColors.zonaIdeal);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _secaoTitulo(titulo: 'Análise econômica'),
        pw.SizedBox(height: 8),
        pw.Text(
          blocos.destaquePerda,
          style: pw.TextStyle(
            font: _semiBold,
            fontSize: 12,
            height: 1.45,
            color: corDestaque,
          ),
        ),
        pw.SizedBox(height: 6),
        for (final linha in blocos.bullets) ...[
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '•  ',
                style: pw.TextStyle(
                  font: _regular,
                  fontSize: 10,
                  height: 1.45,
                  color: _pdfColor(AppColors.textPrimary),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  linha,
                  style: pw.TextStyle(
                    font: _regular,
                    fontSize: 10,
                    height: 1.45,
                    color: _pdfColor(AppColors.textPrimary),
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
        ],
        if (blocos.fechamento.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.RichText(
            text: pw.TextSpan(
              children: [
                for (final trecho in blocos.fechamento)
                  pw.TextSpan(
                    text: trecho.texto,
                    style: pw.TextStyle(
                      font: trecho.negrito ? _semiBold : _regular,
                      fontSize: 10,
                      height: 1.45,
                      color: _pdfColor(AppColors.textPrimary),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildDiagnosticoRecomendacaoLaudo(DiagnosticoRegulagem d) {
    final vm = montarDiagnosticoRecomendacaoLaudo(d);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _secaoTitulo(titulo: 'Diagnóstico e Recomendação'),
        pw.SizedBox(height: 8),
        for (final linha in vm.linhasPorZona) ...[
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              PdfMarcadorZona.widget(linha.status, size: 11),
              pw.SizedBox(width: 6),
              pw.Expanded(
                child: pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      for (final t in linha.trechos)
                        pw.TextSpan(
                          text: t.texto,
                          style: pw.TextStyle(
                            font: t.negrito ? _semiBold : _regular,
                            fontSize: 10,
                            height: 1.45,
                            color: _pdfColor(AppColors.textPrimary),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
        ],
        pw.Text(
          vm.textoRecomendacaoFinal,
          style: pw.TextStyle(
            font: _semiBold,
            fontSize: 10,
            height: 1.45,
            color: _pdfColor(AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  static double _alturaGraficoVazaoPdf(int totalPontas) =>
      totalPontas <= 10 ? 118.0 : 160.0;

  static List<pw.Widget> _buildCharts(
      RegulagemPdfData data, PdfFont chartFont) {
    final escalaGlobal = VazaoChartData.from(
      medicoes: data.medicoes,
      litroMinIdeal: data.litroMinIdeal,
      limiteIrregular: data.configuracoes.limiteIrregular,
      limiteDesgaste: data.configuracoes.limiteDesgaste,
    );
    if (escalaGlobal.vazio) return [pw.SizedBox()];

    final blocos = planejarGraficosVazaoPdf(
      medicoes: data.medicoes,
      ladoConferencia: data.ladoConferenciaPontas,
    );
    final pageWidth = PdfPageFormat.a4.width - 64;
    final widgets = <pw.Widget>[];
    final alturaGrafico = _alturaGraficoVazaoPdf(data.medicoes.length);

    for (var i = 0; i < blocos.length; i++) {
      final bloco = blocos[i];
      final chart = VazaoChartData.fatiaComEscala(
        medicoes: bloco.medicoes,
        litroMinIdeal: data.litroMinIdeal,
        limiteIrregular: data.configuracoes.limiteIrregular,
        limiteDesgaste: data.configuracoes.limiteDesgaste,
        escalaReferencia: escalaGlobal,
      );
      if (chart.vazio) continue;

      final n = chart.pontas.length;
      final rotacionarEixo = n >= maxPontasPorGraficoPdf;
      final bottomPad = rotacionarEixo
          ? VazaoChartLayout.bottomPadRotuloVertical
          : VazaoChartLayout.bottomPad;
      final chartWidth = VazaoChartLayout.canvasWidthFor(
        n,
        maxAvailable: pageWidth,
        podeEstourar: false,
      );

      widgets.add(
        pw.Inseparable(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _secaoTitulo(
                titulo: bloco.titulo,
                subtitulo: i == 0
                    ? '${SubtitulosLaudoPdf.grafico} ${subtituloGraficoVazao(escalaGlobal)}'
                    : null,
              ),
              pw.SizedBox(height: 8),
              pw.SizedBox(
                width: chartWidth,
                height: alturaGrafico,
                child: pw.CustomPaint(
                  size: PdfPoint(chartWidth, alturaGrafico),
                  painter: (canvas, size) {
                    _paintChart(
                      canvas: canvas,
                      size: size,
                      chart: chart,
                      font: chartFont,
                      lado: bloco.lado,
                      indiceInicioNoLado: bloco.indiceInicioNoLado,
                      rotacionarRotulosEixoX: rotacionarEixo,
                      mostrarSimboloPercentual: n <= 10,
                      bottomPad: bottomPad,
                    );
                  },
                ),
              ),
              if (bloco.mostrarLegendaMarcadores) ...[
                pw.SizedBox(height: 6),
                _buildChartLegenda(escalaGlobal),
              ],
              pw.SizedBox(height: 8),
            ],
          ),
        ),
      );
    }
    return widgets;
  }

  static pw.Widget _buildChartLegenda(VazaoChartData chart) {
    final statuses = <StatusPonta>[...chart.statusMedidos];
    if (chart.temPendente) {
      statuses.add(StatusPonta.pendente);
    }

    return pw.Wrap(
      spacing: 10,
      runSpacing: 4,
      children: [
        for (final status in statuses)
          pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              PdfMarcadorZona.widget(status, size: 11),
              pw.SizedBox(width: 4),
              pw.Text(
                rotuloStatusPonta(status),
                style: pw.TextStyle(
                  font: _regular,
                  fontSize: 8,
                  color: _pdfColor(AppColors.textSecondary),
                ),
              ),
            ],
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
    required LadoConferenciaPontas lado,
    required int indiceInicioNoLado,
    required bool rotacionarRotulosEixoX,
    required bool mostrarSimboloPercentual,
    required double bottomPad,
  }) {
    final layout = VazaoChartLayout.from(
      n: chart.pontas.length,
      canvasWidth: size.x,
      canvasHeight: size.y,
      bottomPadOverride: bottomPad,
    );
    if (chart.vazio || layout.plotWidth <= 0 || layout.plotHeight <= 0) {
      return;
    }

    const fontSize = 8.5;
    final yIdeal = layout.yPdf(100, chart);
    final yEntupido = layout.yPdf(chart.limiteIrregular, chart);
    final yDesgaste = layout.yPdf(chart.limiteDesgaste, chart);
    final yTopo = layout.yPdf(chart.maxPercent, chart);
    final yBase = layout.yPdf(chart.minPercent, chart);

    if (chart.limiteIrregular < 100) {
      canvas
        ..setFillColor(_pdfColorWithAlpha(AppColors.zonaIdeal, 0.16).flatten())
        ..drawRRect(
          layout.left,
          min(yIdeal, yEntupido),
          layout.plotWidth,
          (yIdeal - yEntupido).abs(),
          3,
          3,
        )
        ..fillPath();
    }
    if (chart.limiteDesgaste > 100) {
      canvas
        ..setFillColor(
            _pdfColorWithAlpha(AppColors.zonaAtencao, 0.14).flatten())
        ..drawRRect(
          layout.left,
          min(yIdeal, yDesgaste),
          layout.plotWidth,
          (yDesgaste - yIdeal).abs(),
          3,
          3,
        )
        ..fillPath();
    }

    canvas
      ..setStrokeColor(_pdfColor(AppColors.textSecondary))
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
      AppColors.textSecondary,
    );
    _paintChartIdealReferencia(
      canvas,
      font,
      chart.litroMinIdeal,
      layout.right,
      yIdeal,
    );

    for (var index = 0; index < chart.pontas.length; index++) {
      final ponta = chart.pontas[index];
      final centerX = layout.centerX(index);
      final rotuloEixo = rotuloPonta(indiceInicioNoLado + index, lado);
      final corEixo =
          ponta.medida ? AppColors.textSecondary : AppColors.textTertiary;
      final yEixo = bottomPad - (rotacionarRotulosEixoX ? 6 : 12);

      if (rotacionarRotulosEixoX) {
        _paintChartLabelRotated(
          canvas,
          font,
          rotuloEixo,
          centerX,
          yEixo,
          corEixo,
        );
      } else {
        _paintChartLabel(canvas, font, rotuloEixo, centerX, yEixo, corEixo);
      }

      final percentual = ponta.percentual;
      if (percentual == null) {
        canvas
          ..setStrokeColor(_pdfColor(AppColors.textTertiary))
          ..setLineWidth(1)
          ..drawEllipse(centerX, yIdeal, 3.5, 3.5)
          ..strokePath();
        continue;
      }

      final cortouTopo = percentual > chart.maxPercent;
      final cortouBase = percentual < chart.minPercent;
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

      if (cortouTopo) {
        _paintIndicadorContinua(canvas, centerX, yTopo + 2, true);
      } else if (cortouBase) {
        _paintIndicadorContinua(canvas, centerX, yBase - 2, false);
      }

      if (!layout.mostraRotulosNasBarras) continue;

      final pctTexto = mostrarSimboloPercentual
          ? LaudoNumeroFormat.percentual(percentual, casas: 1)
          : LaudoNumeroFormat.decimal(percentual, casas: 1);
      final yRotulo =
          subiu ? base + altura + 3 : max(base - fontSize - 2, bottomPad);
      _paintChartLabel(
        canvas,
        font,
        pctTexto,
        centerX,
        yRotulo,
        _statusLabelColor(ponta.status),
        fontSize: fontSize,
      );
    }
  }

  static void _paintChartIdealReferencia(
    PdfGraphics canvas,
    PdfFont font,
    double litroMinIdeal,
    double plotRight,
    double yIdeal,
  ) {
    const fontSize = 8.0;
    final texto = LaudoNumeroFormat.rotuloIdealGrafico(litroMinIdeal);
    canvas
      ..setFillColor(_pdfColor(AppColors.textSecondary))
      ..drawString(font, fontSize, texto, plotRight + 4, yIdeal - 3);
  }

  static void _paintIndicadorContinua(
    PdfGraphics canvas,
    double centerX,
    double y,
    bool paraCima,
  ) {
    canvas
      ..setFillColor(_pdfColor(AppColors.textSecondary))
      ..setLineWidth(0.8);
    if (paraCima) {
      canvas
        ..moveTo(centerX, y + 4)
        ..lineTo(centerX - 2.5, y)
        ..lineTo(centerX + 2.5, y)
        ..closePath()
        ..fillPath();
    } else {
      canvas
        ..moveTo(centerX, y - 4)
        ..lineTo(centerX - 2.5, y)
        ..lineTo(centerX + 2.5, y)
        ..closePath()
        ..fillPath();
    }
  }

  static void _paintChartLabelRotated(
    PdfGraphics canvas,
    PdfFont font,
    String text,
    double centerX,
    double y,
    Color color,
  ) {
    const fontSize = 8.5;
    final metrics = font.stringMetrics(text) * fontSize;
    canvas.saveContext();
    final m = Matrix4.identity();
    m.translateByDouble(centerX, y, 0, 1);
    m.rotateZ(-pi / 2);
    canvas.setTransform(m);
    canvas
      ..setFillColor(_pdfColor(color))
      ..drawString(font, fontSize, text, -metrics.width / 2, 0);
    canvas.restoreContext();
  }

  static void _paintChartYLabel(
    PdfGraphics canvas,
    PdfFont font,
    String text,
    double left,
    double y,
    Color color,
  ) {
    const fontSize = 8.5;
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
    Color color, {
    double fontSize = 8.5,
  }) {
    final metrics = font.stringMetrics(text) * fontSize;
    canvas
      ..setFillColor(_pdfColor(color))
      ..drawString(font, fontSize, text, centerX - metrics.width / 2, y);
  }

  /// Widgets soltos para o [pw.MultiPage] paginar linha a linha e permitir que
  /// o conteúdo seguinte (ex.: Como calculamos) preencha o restante da página.
  static Future<List<pw.Widget>> _buildFotosSectionWidgets(
    List<FotoRegulagem> fotos, {
    required List<PontaMedicao> medicoes,
    FotosRegulagemService? fotosService,
  }) async {
    if (fotos.isEmpty) return const [];

    final service = fotosService ?? FotosRegulagemService();
    final itens = <({FotoRegulagem foto, Uint8List bytes})>[];
    for (final foto in fotos) {
      final file = await service.resolverArquivo(foto);
      if (!await file.exists()) continue;
      itens.add((foto: foto, bytes: await file.readAsBytes()));
    }
    if (itens.isEmpty) return const [];

    final widgets = <pw.Widget>[
      _secaoTitulo(
        titulo: 'Fotos da Regulagem',
        subtitulo: SubtitulosLaudoPdf.fotos,
      ),
      pw.SizedBox(height: 8),
    ];

    for (var i = 0; i < itens.length; i += 2) {
      widgets.add(
        _buildFotoGridRow(
          left: itens[i],
          right: i + 1 < itens.length ? itens[i + 1] : null,
          medicoes: medicoes,
        ),
      );
      if (i + 2 < itens.length) {
        widgets.add(pw.SizedBox(height: 12));
      }
    }

    return widgets;
  }

  static const _fotoGridGap = 12.0;

  static pw.Widget _buildFotoGridRow({
    required ({FotoRegulagem foto, Uint8List bytes}) left,
    required ({FotoRegulagem foto, Uint8List bytes})? right,
    required List<PontaMedicao> medicoes,
  }) {
    return pw.LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints?.maxWidth ??
            (PdfPageFormat.a4.width - 32 - 32);
        final colWidth = (totalWidth - _fotoGridGap) / 2;

        return pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: colWidth,
              child: _buildFotoCelula(left, medicoes: medicoes),
            ),
            if (right != null) ...[
              pw.SizedBox(width: _fotoGridGap),
              pw.SizedBox(
                width: colWidth,
                child: _buildFotoCelula(right, medicoes: medicoes),
              ),
            ],
          ],
        );
      },
    );
  }

  /// Largura ÷ altura do quadro da foto no laudo (retrato, alinhado ao celular).
  static const _fotoLaudoAspectRatio = 3 / 4;

  static pw.Widget _buildFotoCelula(
    ({FotoRegulagem foto, Uint8List bytes}) item, {
    required List<PontaMedicao> medicoes,
  }) {
    final titulo = item.foto.titulo?.trim();
    final observacao = item.foto.observacao?.trim();
    final selo = _seloPonta(titulo);
    final statusPonta = _statusDaFoto(titulo, medicoes);
    final legenda = <pw.Widget>[];

    if (selo.isNotEmpty) {
      legenda.add(
        pw.Row(
          children: [
            if (statusPonta != null) ...[
              PdfMarcadorZona.widget(statusPonta, size: 11),
              pw.SizedBox(width: 6),
            ],
            pw.Text(
              selo,
              style: pw.TextStyle(font: _semiBold, fontSize: 12),
            ),
          ],
        ),
      );
    }
    final obs = _normalizarLegendaFoto(observacao);
    if (obs != null && obs.isNotEmpty) {
      if (legenda.isNotEmpty) legenda.add(pw.SizedBox(height: 4));
      legenda.add(
        pw.Text(
          obs,
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
          child: pw.AspectRatio(
            aspectRatio: _fotoLaudoAspectRatio,
            child: pw.Container(
              alignment: pw.Alignment.center,
              color: _pdfColor(AppColors.surfaceAlt),
              child: pw.Image(
                pw.MemoryImage(item.bytes),
                fit: pw.BoxFit.contain,
              ),
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

  static StatusPonta? _statusDaFoto(
    String? titulo,
    List<PontaMedicao> medicoes,
  ) {
    if (titulo == null || titulo.trim().isEmpty) return null;
    final match = RegExp(r'(\d+)\s*[DE]?', caseSensitive: false)
        .firstMatch(titulo.replaceAll('Ponta', '').trim());
    if (match == null) return null;
    final id = int.tryParse(match.group(1)!);
    if (id == null) return null;
    for (final ponta in medicoes) {
      if (ponta.id == id) return ponta.status;
    }
    return null;
  }

  static String? _normalizarLegendaFoto(String? texto) {
    if (texto == null) return null;
    final t = texto.trim();
    if (t.isEmpty) return null;
    return t.replaceAll(
      RegExp(r'limpenza\s+se\s+bico', caseSensitive: false),
      'Limpeza do bico',
    );
  }

  static pw.Widget _buildAssinaturaProfissional(RegulagemPdfData data) {
    final config = data.configuracoes;
    final empresa = config.empresaNome.trim();
    final crea = config.registroProfissional.trim();

    final linhas = <pw.Widget>[
      pw.Container(
        margin: const pw.EdgeInsets.only(top: 16, bottom: 8),
        height: 0.5,
        color: _pdfColor(AppColors.border),
      ),
      pw.SizedBox(height: 4),
    ];

    if (empresa.isNotEmpty) {
      linhas.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 2),
          child: pw.Text(
            empresa,
            style: pw.TextStyle(
              font: _regular,
              fontSize: 9,
              color: _pdfColor(AppColors.textSecondary),
            ),
          ),
        ),
      );
    }
    if (crea.isNotEmpty) {
      linhas.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 2),
          child: pw.Text(
            crea,
            style: pw.TextStyle(
              font: _regular,
              fontSize: 9,
              color: _pdfColor(AppColors.textSecondary),
            ),
          ),
        ),
      );
    }
    if (linhas.length <= 2) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: linhas,
    );
  }

  static pw.Widget _buildComoCalculamos(DiagnosticoRegulagem diagnostico) {
    final linhas = montarLinhasComoCalculamosLaudo(
      uniformidade: diagnostico.uniformidade,
    );
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Como calculamos',
          style: pw.TextStyle(font: _semiBold, fontSize: 13),
        ),
        pw.SizedBox(height: 6),
        for (final linha in linhas)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Text(
              linha,
              style: pw.TextStyle(
                font: _regular,
                fontSize: 9,
                height: 1.45,
                color: _pdfColor(AppColors.textSecondary),
              ),
            ),
          ),
      ],
    );
  }

  static String _seloPonta(String? titulo) {
    if (titulo == null || titulo.trim().isEmpty) return '';
    final t = titulo.trim();
    if (t.toLowerCase().startsWith('ponta')) return t;
    return 'Ponta $t';
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

  static PdfColor _statusBarColor(StatusPonta status) {
    return _pdfColor(corZona(status));
  }

  static Color _statusLabelColor(StatusPonta status) => corZona(status);

  static PdfColor _pdfColor(Color color) {
    return PdfColor.fromInt(color.toARGB32());
  }

  static PdfColor _pdfColorWithAlpha(Color color, double alpha) {
    return PdfColor(color.r, color.g, color.b, alpha);
  }
}
