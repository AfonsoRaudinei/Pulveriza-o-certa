import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/formatters/digitos_maximo_formatter.dart';
import '../../../core/marcadores_zona.dart';
import '../../../core/utils/calculo_utils.dart';
import '../../../domain/calculos/calc_diagnostico_regulagem.dart';
import '../../../domain/calculos/texto_pontas.dart';
import '../../../models/configuracoes.dart';
import '../../../models/regulagem.dart';
import '../../../theme.dart';
import '../../../widgets/status_badge.dart';
import 'medicoes_resumo_card.dart';

class PontasTable extends StatelessWidget {
  PontasTable({
    super.key,
    required this.medicoes,
    required this.ideal,
    required this.configuracoes,
    required this.manejo,
    required this.precoBico,
    required this.area,
    required this.ladoConferencia,
    required this.readonly,
    required this.onMedicaoChanged,
    this.onMovedToNextPonta,
    this.onLadoConferenciaChanged,
    this.exigirConfirmacaoTrocaLado = false,
  })  : _diagnostico = DiagnosticoRegulagem.calcular(
          medicoes: medicoes,
          litroMinIdeal: ideal,
          limites: configuracoes.limitesRegulagem,
          lado: ladoConferencia,
          manejoRS: manejo,
          precoBicoRS: precoBico,
          areaHa: area,
        ),
        _percentuais = _percentuaisPorPonta(medicoes, ideal);

  final List<PontaMedicao> medicoes;
  final double ideal;
  final Configuracoes configuracoes;
  final double manejo;
  final double precoBico;
  final double area;
  final LadoConferenciaPontas ladoConferencia;
  final bool readonly;
  final ValueChanged<PontaInput> onMedicaoChanged;
  final VoidCallback? onMovedToNextPonta;
  final ValueChanged<LadoConferenciaPontas>? onLadoConferenciaChanged;
  final bool exigirConfirmacaoTrocaLado;
  final DiagnosticoRegulagem _diagnostico;
  final Map<int, double> _percentuais;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LadoConferenciaToggle(
          value: ladoConferencia,
          readonly: readonly,
          exigirConfirmacao: exigirConfirmacaoTrocaLado,
          onChanged: onLadoConferenciaChanged,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          legendaLadosPontasLaudo(
            numeroPontas: medicoes.length,
            ladoConferencia: ladoConferencia,
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        MedicoesResumoCard(zonas: _diagnostico.zonasVisiveis),
        const SizedBox(height: AppSpacing.lg),
        if (medicoes.isNotEmpty)
          _PontasLista(
            medicoes: medicoes,
            ideal: ideal,
            percentuais: _percentuais,
            ladoConferencia: ladoConferencia,
            readonly: readonly,
            onMedicaoChanged: onMedicaoChanged,
            onMovedToNextPonta: onMovedToNextPonta,
          ),
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

class _LadoConferenciaToggle extends StatelessWidget {
  const _LadoConferenciaToggle({
    required this.value,
    required this.readonly,
    required this.exigirConfirmacao,
    required this.onChanged,
  });

  final LadoConferenciaPontas value;
  final bool readonly;
  final bool exigirConfirmacao;
  final ValueChanged<LadoConferenciaPontas>? onChanged;

  Future<void> _tentarAlterar(
    BuildContext context,
    LadoConferenciaPontas novo,
  ) async {
    if (novo == value || onChanged == null) return;
    if (exigirConfirmacao) {
      final confirmou = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Alterar lado da conferência?'),
          content: const Text(
            'Isso muda a numeração das pontas (1D/1E, 2D/2E…). '
            'Confirma a alteração?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );
      if (confirmou != true) return;
    }
    onChanged!(novo);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conferência iniciada por',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<LadoConferenciaPontas>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: LadoConferenciaPontas.direita,
                label: Text('Direita'),
              ),
              ButtonSegment(
                value: LadoConferenciaPontas.esquerda,
                label: Text('Esquerda'),
              ),
            ],
            selected: {value},
            onSelectionChanged: readonly || onChanged == null
                ? null
                : (selected) => _tentarAlterar(context, selected.first),
          ),
        ),
      ],
    );
  }
}

class _PontasLista extends StatefulWidget {
  const _PontasLista({
    required this.medicoes,
    required this.ideal,
    required this.percentuais,
    required this.ladoConferencia,
    required this.readonly,
    required this.onMedicaoChanged,
    required this.onMovedToNextPonta,
  });

  final List<PontaMedicao> medicoes;
  final double ideal;
  final Map<int, double> percentuais;
  final LadoConferenciaPontas ladoConferencia;
  final bool readonly;
  final ValueChanged<PontaInput> onMedicaoChanged;
  final VoidCallback? onMovedToNextPonta;

  @override
  State<_PontasLista> createState() => _PontasListaState();
}

class _PontasListaState extends State<_PontasLista> {
  Future<void> _abrirFolha(PontaMedicao ponta) async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => _MedicaoPontaSheet(
        ponta: ponta,
        ladoConferencia: widget.ladoConferencia,
        ideal: widget.ideal,
        readonly: widget.readonly,
        onChanged: (value) => widget.onMedicaoChanged(
          PontaInput(ponta.id, value),
        ),
      ),
    );
    if (!mounted || widget.readonly) return;
    widget.onMovedToNextPonta?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final dividerCount =
        widget.medicoes.length > 1 ? widget.medicoes.length - 1 : 0;
    final listHeight =
        widget.medicoes.length * _PontaLinha.altura + dividerCount;

    return SizedBox(
      height: listHeight.toDouble(),
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < widget.medicoes.length; i++) ...[
            if (i > 0) Divider(height: 1, color: colors.border),
            _PontaLinha(
              ponta: widget.medicoes[i],
              ladoConferencia: widget.ladoConferencia,
              percentual: widget.medicoes[i].valorMedido == null
                  ? null
                  : widget.percentuais[widget.medicoes[i].id],
              onTap: () => _abrirFolha(widget.medicoes[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _PontaLinha extends StatelessWidget {
  const _PontaLinha({
    required this.ponta,
    required this.ladoConferencia,
    required this.percentual,
    required this.onTap,
  });

  static const altura = 52.0;

  final PontaMedicao ponta;
  final LadoConferenciaPontas ladoConferencia;
  final double? percentual;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final medido = ponta.valorMedido;
    final rotulo = rotuloPonta(ponta.id, ladoConferencia);
    final medidoTexto =
        medido == null ? 'Sem medição' : '${medido.toStringAsFixed(3)} L/min';
    final corPct = MarcadoresZona.cor(ponta.status);
    return Material(
      color: colors.surface,
      child: InkWell(
        key: ValueKey('ponta-row-${ponta.id}'),
        onTap: onTap,
        child: SizedBox(
          height: altura,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$rotulo · $medidoTexto',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: medido == null
                                        ? colors.textSecondary
                                        : colors.textPrimary,
                                  ),
                        ),
                        if (percentual != null)
                          TextSpan(
                            text: ' · ${percentual!.toStringAsFixed(1)}%',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: corPct,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                StatusBadge(status: ponta.status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MedicaoPontaSheet extends StatefulWidget {
  const _MedicaoPontaSheet({
    required this.ponta,
    required this.ladoConferencia,
    required this.ideal,
    required this.readonly,
    required this.onChanged,
  });

  final PontaMedicao ponta;
  final LadoConferenciaPontas ladoConferencia;
  final double ideal;
  final bool readonly;
  final ValueChanged<String> onChanged;

  @override
  State<_MedicaoPontaSheet> createState() => _MedicaoPontaSheetState();
}

class _MedicaoPontaSheetState extends State<_MedicaoPontaSheet> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.ponta.valorMedido?.toStringAsFixed(3) ?? '',
    );
    if (!widget.readonly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        FocusScope.of(context).requestFocus(_focusNode);
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final rotulo = rotuloPonta(widget.ponta.id, widget.ladoConferencia);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$rotulo · L/min medido',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: 48,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: !widget.readonly,
              maxLines: 1,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                const DigitosMaximoFormatter(),
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
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
              onChanged: widget.onChanged,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Ideal: ${widget.ideal.toStringAsFixed(3)} L/min',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
