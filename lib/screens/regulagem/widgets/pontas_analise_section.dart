import 'package:flutter/material.dart';

import '../../../core/charts/vazao_chart_data.dart';
import '../../../domain/calculos/calc_diagnostico_recomendacao_laudo.dart';
import '../../../domain/calculos/calc_diagnostico_regulagem.dart';
import '../../../domain/calculos/calc_layout_laudo_pdf.dart';
import '../../../domain/calculos/calc_texto_analise_economica_laudo.dart';
import '../../../models/configuracoes.dart';
import '../../../models/regulagem.dart';
import '../../../theme.dart';
import '../../../widgets/diagnostico_recomendacao_laudo.dart';
import 'grafico_vazao_pontas.dart';

/// Gráfico, economia e orientações — fora do card de medições.
class PontasAnaliseSection extends StatefulWidget {
  const PontasAnaliseSection({
    super.key,
    required this.medicoes,
    required this.ideal,
    required this.configuracoes,
    required this.manejo,
    required this.precoBico,
    required this.area,
    this.numeroAplicacoes,
    this.tipoPonta,
    this.ladoConferencia = LadoConferenciaPontas.direita,
  });

  final List<PontaMedicao> medicoes;
  final double ideal;
  final Configuracoes configuracoes;
  final double manejo;
  final double precoBico;
  final double area;
  final int? numeroAplicacoes;
  final TipoPontaBico? tipoPonta;
  final LadoConferenciaPontas ladoConferencia;

  @override
  State<PontasAnaliseSection> createState() => _PontasAnaliseSectionState();
}

class _PontasAnaliseSectionState extends State<PontasAnaliseSection> {
  late bool _hasMedicoes;
  late VazaoChartData _chartData;
  late DiagnosticoRegulagem _diagnostico;
  late DiagnosticoRecomendacaoLaudo _diagnosticoRecomendacao;
  late BlocosAnaliseEconomicaLaudo _analiseEconomica;

  @override
  void initState() {
    super.initState();
    _recomputeDerived();
  }

  @override
  void didUpdateWidget(covariant PontasAnaliseSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_inputsChanged(oldWidget)) {
      _recomputeDerived();
    }
  }

  bool _inputsChanged(PontasAnaliseSection oldWidget) {
    return oldWidget.ideal != widget.ideal ||
        oldWidget.manejo != widget.manejo ||
        oldWidget.precoBico != widget.precoBico ||
        oldWidget.area != widget.area ||
        oldWidget.numeroAplicacoes != widget.numeroAplicacoes ||
        oldWidget.tipoPonta != widget.tipoPonta ||
        oldWidget.ladoConferencia != widget.ladoConferencia ||
        oldWidget.configuracoes.limiteIrregular !=
            widget.configuracoes.limiteIrregular ||
        oldWidget.configuracoes.limiteDesgaste !=
            widget.configuracoes.limiteDesgaste ||
        !_medicoesIguais(oldWidget.medicoes, widget.medicoes);
  }

  bool _medicoesIguais(List<PontaMedicao> a, List<PontaMedicao> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].valorMedido != b[i].valorMedido ||
          a[i].status != b[i].status) {
        return false;
      }
    }
    return true;
  }

  void _recomputeDerived() {
    _hasMedicoes = widget.medicoes.any((item) => item.valorMedido != null);
    final limites = widget.configuracoes.limitesRegulagem;
    _chartData = VazaoChartData.from(
      medicoes: widget.medicoes,
      litroMinIdeal: widget.ideal,
      limiteIrregular: limites.limiteEntupido,
      limiteDesgaste: limites.limiteDesgaste,
    );
    _diagnostico = DiagnosticoRegulagem.calcular(
      medicoes: widget.medicoes,
      litroMinIdeal: widget.ideal,
      limites: limites,
      lado: widget.ladoConferencia,
      manejoRS: widget.manejo,
      precoBicoRS: widget.precoBico,
      areaHa: widget.area,
      numeroAplicacoes: widget.numeroAplicacoes,
      tipoPonta: widget.tipoPonta,
    );
    _diagnosticoRecomendacao = montarDiagnosticoRecomendacaoLaudo(_diagnostico);
    _analiseEconomica = montarBlocosAnaliseEconomicaLaudo(_diagnostico);
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasMedicoes) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_diagnostico.avisoMedicao != null) ...[
          _AvisoMedicao(texto: _diagnostico.avisoMedicao!),
          const SizedBox(height: AppSpacing.md),
        ],
        Text(
          _diagnostico.limites.linhaCabecalho,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        GraficoVazaoPontas(
          data: _chartData,
          ladoConferencia: widget.ladoConferencia,
        ),
        const SizedBox(height: AppSpacing.xl),
        DiagnosticoRecomendacaoLaudoView(
          conteudo: _diagnosticoRecomendacao,
        ),
        const SizedBox(height: AppSpacing.xl),
        _AnaliseEconomicaLaudo(blocos: _analiseEconomica),
        const SizedBox(height: AppSpacing.xl),
        _DadosCalculoLaudo(diagnostico: _diagnostico),
      ],
    );
  }
}

class _AvisoMedicao extends StatelessWidget {
  const _AvisoMedicao({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$texto — análise parcial',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.zonaAtencao,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _AnaliseEconomicaLaudo extends StatelessWidget {
  const _AnaliseEconomicaLaudo({required this.blocos});

  final BlocosAnaliseEconomicaLaudo blocos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (blocos.mensagemIncompleta != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TituloAnaliseEconomica(),
          const SizedBox(height: AppSpacing.sm),
          Text(
            blocos.mensagemIncompleta!,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
          ),
        ],
      );
    }

    final corDestaque = blocos.perdaTotal > 0
        ? AppColors.iosDestructive
        : AppColors.zonaIdeal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TituloAnaliseEconomica(),
        const SizedBox(height: AppSpacing.sm),
        Text(
          blocos.destaquePerda,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.35,
            fontWeight: FontWeight.w700,
            color: corDestaque,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final linha in blocos.bullets) ...[
          Text(
            '• $linha',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        if (blocos.fechamento.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text.rich(
            TextSpan(
              children: [
                for (final t in blocos.fechamento)
                  TextSpan(
                    text: t.texto,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.35,
                      fontWeight: t.negrito ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _TituloAnaliseEconomica extends StatelessWidget {
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
        'Análise econômica',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _DadosCalculoLaudo extends StatelessWidget {
  const _DadosCalculoLaudo({required this.diagnostico});

  final DiagnosticoRegulagem diagnostico;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final dados = montarDadosCalculoLaudo(
      manejoRS: diagnostico.manejoRS,
      manejoPorPonta: diagnostico.manejoPorPonta,
      precoBicoRS: diagnostico.precoBicoRS,
      areaHa: diagnostico.areaHa,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: colors.border, height: 1),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Dados usados no cálculo',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        _DadoCalculo(
            label: 'Custo do defensivo por ha', value: dados.manejoPorHa),
        _DadoCalculo(label: 'Produto por ponta', value: dados.manejoPorPonta),
        _DadoCalculo(label: 'Preço do bico', value: dados.precoBico),
        _DadoCalculo(label: 'Área', value: dados.area),
      ],
    );
  }
}

class _DadoCalculo extends StatelessWidget {
  const _DadoCalculo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
