import 'dart:math' show max, min;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/extensions/double_extension.dart';
import '../../../core/utils/calculo_utils.dart';
import '../../../models/configuracoes.dart';
import '../../../models/regulagem.dart';
import '../../../theme.dart';
import '../../../widgets/status_badge.dart';

const _kIdWidth = 28.0;
const _kMedidoWidth = 128.0;
const _kPercentWidth = 48.0;

class PontasTable extends StatelessWidget {
  PontasTable({
    super.key,
    required this.medicoes,
    required this.ideal,
    required this.configuracoes,
    required this.manejo,
    required this.precoBico,
    required this.area,
    required this.readonly,
    required this.onMedicaoChanged,
  })  : _hasMedicoes = medicoes.any((item) => item.valorMedido != null),
        _resumoPontas = _ResumoPontasData.from(
          medicoes: medicoes,
          ideal: ideal,
          configuracoes: configuracoes,
        ),
        _percentuais = _percentuaisPorPonta(medicoes, ideal),
        _economiaResumo = _EconomiaResumo.from(
          medicoes: medicoes,
          ideal: ideal,
          manejo: manejo,
          precoBico: precoBico,
          area: area,
        ),
        _orientacoesResumo = _OrientacoesResumo.from(medicoes);

  final List<PontaMedicao> medicoes;
  final double ideal;
  final Configuracoes configuracoes;
  final double manejo;
  final double precoBico;
  final double area;
  final bool readonly;
  final ValueChanged<PontaInput> onMedicaoChanged;
  final bool _hasMedicoes;
  final _ResumoPontasData _resumoPontas;
  final Map<int, double> _percentuais;
  final _EconomiaResumo _economiaResumo;
  final _OrientacoesResumo _orientacoesResumo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ResumoPontas(resumo: _resumoPontas),
        const SizedBox(height: AppSpacing.lg),
        const _PontasHeader(),
        SizedBox(
          height: 360,
          child: ListView.builder(
            itemCount: medicoes.length,
            itemBuilder: (context, index) {
              final ponta = medicoes[index];
              return _PontaRow(
                ponta: ponta,
                ideal: ideal,
                percentual: _percentuais[ponta.id] ?? 0,
                readonly: readonly,
                onChanged: (value) =>
                    onMedicaoChanged(PontaInput(ponta.id, value)),
              );
            },
          ),
        ),
        if (_hasMedicoes) ...[
          const SizedBox(height: AppSpacing.xl),
          _EconomiaSection(resumo: _economiaResumo),
          const SizedBox(height: AppSpacing.xl),
          _GraficoPontasVazao(
            medicoes: medicoes,
            ideal: ideal,
            configuracoes: configuracoes,
          ),
          const SizedBox(height: AppSpacing.xl),
          _Orientacoes(resumo: _orientacoesResumo),
        ],
      ],
    );
  }

  static Map<int, double> _percentuaisPorPonta(
    List<PontaMedicao> medicoes,
    double ideal,
  ) {
    return {
      for (final item in medicoes)
        item.id: item.valorMedido == null
            ? 0
            : CalcUtils.calcularPercentualPonta(
                valorMedido: item.valorMedido!,
                litroMinIdeal: ideal,
              ),
    };
  }
}

class PontaInput {
  const PontaInput(this.id, this.value);
  final int id;
  final String value;
}

class _ResumoPontasData {
  const _ResumoPontasData({
    required this.desgaste,
    required this.irregular,
    required this.tolerancia,
    required this.acimaMin,
    required this.ideal,
  });

  factory _ResumoPontasData.from({
    required List<PontaMedicao> medicoes,
    required double ideal,
    required Configuracoes configuracoes,
  }) {
    final percentuais = medicoes.where((item) => item.valorMedido != null).map(
          (item) => CalcUtils.calcularPercentualPonta(
            valorMedido: item.valorMedido!,
            litroMinIdeal: ideal,
          ),
        );
    final tolerancia = CalcUtils.agregarTolerancia(
      percentuais: percentuais,
      configuracoes: configuracoes,
    );

    return _ResumoPontasData(
      desgaste:
          medicoes.where((item) => item.status == StatusPonta.desgaste).length,
      irregular:
          medicoes.where((item) => item.status == StatusPonta.irregular).length,
      tolerancia: tolerancia.entreTolerancias,
      acimaMin: tolerancia.acimaToleranciaMin,
      ideal: medicoes.where((item) => item.status == StatusPonta.ideal).length,
    );
  }

  final int desgaste;
  final int irregular;
  final int tolerancia;
  final int acimaMin;
  final int ideal;
}

class _EconomiaResumo {
  const _EconomiaResumo({
    required this.perdaTotal,
    required this.custo,
    required this.pontaRS,
    required this.trocarTudo,
  });

  factory _EconomiaResumo.from({
    required List<PontaMedicao> medicoes,
    required double ideal,
    required double manejo,
    required double precoBico,
    required double area,
  }) {
    final perdaTotal = medicoes.fold<double>(0, (total, item) {
      if (item.valorMedido == null) return total;
      final percentual = CalcUtils.calcularPercentualPonta(
        valorMedido: item.valorMedido!,
        litroMinIdeal: ideal,
      );
      return total +
          CalcUtils.calcularPerdaEstimada(
            percentual: percentual,
            manejoRS: manejo,
            numeroPontas: medicoes.length,
            areaHa: area,
          );
    });
    final custo = CalcUtils.calcularCustoTrocaTotal(
      precoBicoRS: precoBico,
      numeroPontas: medicoes.length,
    );
    final pontaRS = CalcUtils.calcularPontaRS(
      manejoRS: manejo,
      numeroPontas: medicoes.length,
    );

    return _EconomiaResumo(
      perdaTotal: perdaTotal,
      custo: custo,
      pontaRS: pontaRS,
      trocarTudo: CalcUtils.recomendarTrocaCompleta(
        perdaEstimadaTotal: perdaTotal,
        custoTrocaTotal: custo,
      ),
    );
  }

  final double perdaTotal;
  final double custo;
  final double pontaRS;
  final bool trocarTudo;
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

class _ResumoPontas extends StatelessWidget {
  const _ResumoPontas({required this.resumo});

  final _ResumoPontasData resumo;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.4,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      children: [
        _ResumoCard(
          label: 'Desgaste',
          value: resumo.desgaste,
          color: AppColors.danger,
          icon: Icons.trending_up,
        ),
        _ResumoCard(
          label: 'Entupido',
          value: resumo.irregular,
          color: AppColors.warning,
          icon: Icons.trending_down,
        ),
        _ResumoCard(
          label: 'Tolerância',
          value: resumo.tolerancia,
          color: AppColors.info,
          icon: Icons.check_circle,
        ),
        _ResumoCard(
          label: 'Acima Min',
          value: resumo.acimaMin,
          color: AppColors.primary,
          icon: Icons.trending_up,
        ),
        _ResumoCard(
          label: 'Ideal',
          value: resumo.ideal,
          color: AppColors.success,
          icon: Icons.check_circle,
        ),
      ],
    );
  }
}

class _ResumoCard extends StatelessWidget {
  const _ResumoCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          Text(
            '$value',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _PontasHeader extends StatelessWidget {
  const _PontasHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(width: _kIdWidth, child: Text('#', style: style)),
          SizedBox(width: _kMedidoWidth, child: Text('Medido', style: style)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text('Ideal', style: style)),
          SizedBox(
            width: _kPercentWidth,
            child: Text('%', style: style, textAlign: TextAlign.end),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text('Status', style: style, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

class _PontaRow extends StatefulWidget {
  const _PontaRow({
    required this.ponta,
    required this.ideal,
    required this.percentual,
    required this.readonly,
    required this.onChanged,
  });
  final PontaMedicao ponta;
  final double ideal;
  final double percentual;
  final bool readonly;
  final ValueChanged<String> onChanged;

  @override
  State<_PontaRow> createState() => _PontaRowState();
}

class _PontaRowState extends State<_PontaRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.ponta.valorMedido?.toStringAsFixed(3) ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _PontaRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ponta.valorMedido != widget.ponta.valorMedido &&
        widget.readonly) {
      _controller.text = widget.ponta.valorMedido?.toStringAsFixed(3) ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final numberStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimary,
        );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppThemeColors.of(context).border),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _kIdWidth,
            child: Text('${widget.ponta.id}', textAlign: TextAlign.center),
          ),
          SizedBox(
            width: _kMedidoWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'L/min',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 2),
                _MedidoField(
                  controller: _controller,
                  readonly: widget.readonly,
                  onChanged: widget.onChanged,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              widget.ideal.toStringAsFixed(3),
              maxLines: 1,
              style: numberStyle,
            ),
          ),
          SizedBox(
            width: _kPercentWidth,
            child: Text(
              widget.percentual == 0
                  ? '-'
                  : widget.percentual.toStringAsFixed(1),
              textAlign: TextAlign.end,
              maxLines: 1,
              style: numberStyle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: StatusBadge(status: widget.ponta.status),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedidoField extends StatelessWidget {
  const _MedidoField({
    required this.controller,
    required this.readonly,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool readonly;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: !readonly,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: '0,000',
        isDense: true,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.borderFocus),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      onChanged: onChanged,
    );
  }
}

class _EconomiaSection extends StatelessWidget {
  const _EconomiaSection({required this.resumo});

  final _EconomiaResumo resumo;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Análise econômica',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.md),
        _ResultadoMetricCard(
          icon: Icons.payments_outlined,
          iconColor: colors.primary,
          background: colors.primaryLight,
          label: 'Ponta R\$',
          value: resumo.pontaRS.toMoeda(),
        ),
        if (resumo.exibirResultado) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _ResultadoMetricCard(
                  icon: Icons.trending_down,
                  iconColor: colors.danger,
                  background: colors.dangerLight,
                  label: 'Perda estimada',
                  value: resumo.perdaTotal.toMoeda(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ResultadoMetricCard(
                  icon: Icons.build_outlined,
                  iconColor: colors.info,
                  background: colors.info.withValues(alpha: 0.12),
                  label: 'Custo de troca',
                  value: resumo.custo.toMoeda(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _RecomendacaoBanner(trocarTudo: resumo.trocarTudo),
        ],
      ],
    );
  }
}

class _ResultadoMetricCard extends StatelessWidget {
  const _ResultadoMetricCard({
    required this.icon,
    required this.iconColor,
    required this.background,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final Color background;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: iconColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _RecomendacaoBanner extends StatelessWidget {
  const _RecomendacaoBanner({required this.trocarTudo});

  final bool trocarTudo;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final color = trocarTudo ? colors.danger : colors.success;
    final background = trocarTudo ? colors.dangerLight : colors.successLight;
    final icon = trocarTudo ? Icons.warning_amber_rounded : Icons.check_circle_outline;
    final text = trocarTudo
        ? 'TROCA COMPLETA recomendada'
        : 'Troca seletiva das pontas problemáticas';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _GraficoPontasVazao extends StatelessWidget {
  const _GraficoPontasVazao({
    required this.medicoes,
    required this.ideal,
    required this.configuracoes,
  });

  final List<PontaMedicao> medicoes;
  final double ideal;
  final Configuracoes configuracoes;

  @override
  Widget build(BuildContext context) {
    if (ideal <= 0) return const SizedBox.shrink();

    const slotWidth = 36.0;
    final viewport = MediaQuery.sizeOf(context).width - AppSpacing.lg * 2;
    final chartWidth = max(viewport, medicoes.length * slotWidth + 52);

    final colors = AppThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vazão por ponta',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Faixa verde = ideal (${configuracoes.limiteIrregular.toStringAsFixed(0)}–${configuracoes.limiteDesgaste.toStringAsFixed(0)}%)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.border),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: chartWidth,
              height: 200,
              child: CustomPaint(
                painter: _GraficoPontasPainter(
                  medicoes: medicoes,
                  ideal: ideal,
                  limiteIrregular: configuracoes.limiteIrregular,
                  limiteDesgaste: configuracoes.limiteDesgaste,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GraficoPontasPainter extends CustomPainter {
  _GraficoPontasPainter({
    required this.medicoes,
    required this.ideal,
    required this.limiteIrregular,
    required this.limiteDesgaste,
  });

  final List<PontaMedicao> medicoes;
  final double ideal;
  final double limiteIrregular;
  final double limiteDesgaste;

  static const _leftPad = 40.0;
  static const _rightPad = 12.0;
  static const _topPad = 12.0;
  static const _bottomPad = 28.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (ideal <= 0 || medicoes.isEmpty) return;

    final chartW = size.width - _leftPad - _rightPad;
    final chartH = size.height - _topPad - _bottomPad;
    if (chartW <= 0 || chartH <= 0) return;

    final idealMin = ideal * (limiteIrregular / 100);
    final idealMax = ideal * (limiteDesgaste / 100);

    final measured = medicoes
        .where((item) => item.valorMedido != null)
        .map((item) => item.valorMedido!)
        .toList();
    if (measured.isEmpty) return;

    final yMax = max(measured.reduce(max), idealMax) * 1.12;
    const yMin = 0.0;

    double yToPx(double value) =>
        _topPad + chartH - ((value - yMin) / (yMax - yMin)) * chartH;

    final bandRect = Rect.fromLTRB(
      _leftPad,
      yToPx(idealMax),
      _leftPad + chartW,
      yToPx(idealMin),
    );
    canvas.drawRect(
      bandRect,
      Paint()..color = AppColors.success.withValues(alpha: 0.14),
    );

    final idealLine = Paint()
      ..color = AppColors.success
      ..strokeWidth = 1.5;
    final idealY = yToPx(ideal);
    canvas.drawLine(
      Offset(_leftPad, idealY),
      Offset(_leftPad + chartW, idealY),
      idealLine,
    );

    final slotWidth = chartW / medicoes.length;
    final barWidth = min(24.0, slotWidth * 0.62);

    for (var index = 0; index < medicoes.length; index++) {
      final ponta = medicoes[index];
      final centerX = _leftPad + slotWidth * index + slotWidth / 2;

      _paintLabel(
        canvas,
        '${ponta.id}',
        Offset(centerX, _topPad + chartH + 8),
      );

      final valor = ponta.valorMedido;
      if (valor == null) continue;

      final top = yToPx(valor);
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - barWidth / 2,
          top,
          barWidth,
          _topPad + chartH - top,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(
        barRect,
        Paint()..color = _colorForStatus(ponta.status),
      );
    }

    _paintYLabel(canvas, idealMax, yToPx(idealMax));
    _paintYLabel(canvas, ideal, idealY);
  }

  void _paintYLabel(Canvas canvas, double value, double y) {
    final painter = TextPainter(
      text: TextSpan(
        text: value.toStringAsFixed(2),
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.textSecondary,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    painter.layout();
    painter.paint(canvas, Offset(2, y - painter.height / 2));
  }

  void _paintLabel(Canvas canvas, String text, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.textSecondary,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    painter.layout();
    painter.paint(canvas, Offset(offset.dx - painter.width / 2, offset.dy));
  }

  Color _colorForStatus(StatusPonta status) {
    return switch (status) {
      StatusPonta.ideal => AppColors.success,
      StatusPonta.irregular => AppColors.warning,
      StatusPonta.desgaste => AppColors.danger,
      StatusPonta.pendente => AppColors.textTertiary,
    };
  }

  @override
  bool shouldRepaint(covariant _GraficoPontasPainter oldDelegate) {
    return oldDelegate.medicoes != medicoes ||
        oldDelegate.ideal != ideal ||
        oldDelegate.limiteIrregular != limiteIrregular ||
        oldDelegate.limiteDesgaste != limiteDesgaste;
  }
}

class _Orientacoes extends StatelessWidget {
  const _Orientacoes({required this.resumo});

  final _OrientacoesResumo resumo;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Orientações', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.md),
        _OrientacaoCard(
          count: resumo.ideal,
          title: 'Ideal',
          message: 'Sem ação imediata. Continue o monitoramento.',
          color: colors.success,
          background: colors.successLight,
          icon: Icons.check_circle_outline,
        ),
        _OrientacaoCard(
          count: resumo.irregular,
          title: 'Entupido',
          message: 'Limpar bicos e repetir teste. Verifique filtro e calda.',
          color: colors.warning,
          background: colors.warningLight,
          icon: Icons.trending_down,
        ),
        _OrientacaoCard(
          count: resumo.desgaste,
          title: 'Desgaste',
          message: 'Substituir urgentemente. Excesso de vazão compromete a aplicação.',
          color: colors.danger,
          background: colors.dangerLight,
          icon: Icons.trending_up,
        ),
      ],
    );
  }
}

class _OrientacaoCard extends StatelessWidget {
  const _OrientacaoCard({
    required this.count,
    required this.title,
    required this.message,
    required this.color,
    required this.background,
    required this.icon,
  });

  final int count;
  final String title;
  final String message;
  final Color color;
  final Color background;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$count',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'ponta(s) $title',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(message, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
