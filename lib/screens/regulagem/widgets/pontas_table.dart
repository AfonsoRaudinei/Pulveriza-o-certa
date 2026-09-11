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
          label: 'Irregular',
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
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
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Análise econômica',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Ponta R\$: ${resumo.pontaRS.toMoeda()}'),
        if (resumo.exibirResultado) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Perda estimada total: ${resumo.perdaTotal.toMoeda()}'),
          Text('Custo de troca total: ${resumo.custo.toMoeda()}'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            resumo.trocarTudo
                ? 'TROCA COMPLETA recomendada'
                : 'Troca seletiva das pontas problemáticas',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color:
                      resumo.trocarTudo ? AppColors.danger : AppColors.success,
                ),
          ),
        ],
      ],
    );
  }
}

class _Orientacoes extends StatelessWidget {
  const _Orientacoes({required this.resumo});

  final _OrientacoesResumo resumo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Orientações', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${resumo.ideal} ponta(s) ideal: sem ação imediata. Continue o monitoramento.',
        ),
        Text(
          '${resumo.irregular} ponta(s) irregular: limpar bicos e repetir teste.',
        ),
        Text(
          '${resumo.desgaste} ponta(s) com desgaste: substituir urgentemente.',
        ),
      ],
    );
  }
}
