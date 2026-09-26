import 'package:flutter/material.dart';

import '../../../core/charts/vazao_chart_data.dart';
import '../../../core/iconografia/zona_icon.dart';
import '../../../core/zona_visual.dart';
import '../../../domain/calculos/calc_diagnostico_regulagem.dart';
import '../../../domain/calculos/calc_layout_laudo_pdf.dart';
import '../../../models/configuracoes.dart';
import '../../../models/regulagem.dart';
import '../../../theme.dart';
import '../../../widgets/orientacoes_zona_laudo.dart';
import '../../../widgets/secao_laudo_titulo.dart';
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
    this.ladoConferencia = LadoConferenciaPontas.direita,
  });

  final List<PontaMedicao> medicoes;
  final double ideal;
  final Configuracoes configuracoes;
  final double manejo;
  final double precoBico;
  final double area;
  final LadoConferenciaPontas ladoConferencia;

  @override
  State<PontasAnaliseSection> createState() => _PontasAnaliseSectionState();
}

class _PontasAnaliseSectionState extends State<PontasAnaliseSection> {
  late bool _hasMedicoes;
  late VazaoChartData _chartData;
  late DiagnosticoRegulagem _diagnostico;

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
    );
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
        OrientacoesZonaLaudo(
          orientacoes: _diagnostico.orientacoes,
          atencao: _diagnostico.atencao,
        ),
        const SizedBox(height: AppSpacing.xl),
        _Veredito(diagnostico: _diagnostico),
        const SizedBox(height: AppSpacing.xl),
        _LaudoPosVeredito(diagnostico: _diagnostico),
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

class _Veredito extends StatelessWidget {
  const _Veredito({required this.diagnostico});

  final DiagnosticoRegulagem diagnostico;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SecaoLaudoTitulo(titulo: 'Recomendação'),
        const SizedBox(height: AppSpacing.sm),
        Text(
          diagnostico.vereditoLaudo,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _LaudoPosVeredito extends StatelessWidget {
  const _LaudoPosVeredito({required this.diagnostico});

  final DiagnosticoRegulagem diagnostico;

  @override
  Widget build(BuildContext context) {
    final d = diagnostico;
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final plano = d.planoLaudo;
    final oQueFazer = montarOQueFazerLaudo(
      plano: plano,
      desgaste: d.desgaste,
      entupida: d.entupida,
      atencao: d.atencao,
    );
    final comparativo = montarComparativoLaudo(plano);
    final motivo = montarFraseMotivoTrocaLaudo(plano);
    final dados = montarDadosCalculoLaudo(
      manejoRS: d.manejoRS,
      manejoPorPonta: d.manejoPorPonta,
      precoBicoRS: d.precoBicoRS,
      areaHa: d.areaHa,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('O que fazer', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        for (final item in oQueFazer) ...[
          _LinhaOQueFazer(item: item),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (comparativo != null) ...[
          const SizedBox(height: AppSpacing.md),
          _ComparativoLaudo(comparativo: comparativo),
        ],
        if (motivo != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(motivo, style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: AppSpacing.lg),
        Divider(color: colors.border, height: 1),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Dados usados no cálculo',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        _DadoCalculo(
            label: 'Custo do defensivo por ha', value: dados.manejoPorHa),
        _DadoCalculo(label: 'Manejo por ponta', value: dados.manejoPorPonta),
        _DadoCalculo(label: 'Preço do bico', value: dados.precoBico),
        _DadoCalculo(label: 'Área', value: dados.area),
      ],
    );
  }
}

class _LinhaOQueFazer extends StatelessWidget {
  const _LinhaOQueFazer({required this.item});

  final ItemOQueFazerLaudo item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final pontas =
        item.todosOsBicos ? 'todos os bicos' : rotulosPontasLinha(item.rotulos);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ZonaIcon(status: item.marcador, size: 11),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${item.verbo} ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (pontas.isNotEmpty)
                  TextSpan(
                    text: '$pontas ',
                    style: theme.textTheme.bodyMedium,
                  ),
                if (item.complemento != null && item.complemento!.isNotEmpty)
                  TextSpan(
                    text: '— ${item.complemento}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
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
        Expanded(child: Text(linha.titulo, style: theme.textTheme.bodySmall)),
        SizedBox(
          width: 72,
          child: Text(
            linha.voceGasta,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            linha.continuaPerdendo,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: destaque ? FontWeight.w600 : FontWeight.w400,
              color: destaque ? AppColors.zonaDesgaste : null,
            ),
          ),
        ),
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
