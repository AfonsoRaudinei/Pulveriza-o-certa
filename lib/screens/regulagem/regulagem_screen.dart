import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/calculo_utils.dart';
import '../../models/configuracoes.dart';
import '../../models/regulagem.dart';
import '../../providers/configuracoes_provider.dart';
import '../../providers/regulagens_provider.dart';
import '../../theme.dart';
import '../../services/regulagem_pdf_service.dart';
import 'widgets/exportar_pdf_button.dart';
import 'widgets/pontas_table.dart';
import 'widgets/progressive_card.dart';

class RegulagemScreen extends StatefulWidget {
  const RegulagemScreen({
    super.key,
    this.regulagem,
    this.readonly = false,
  });

  final Regulagem? regulagem;
  final bool readonly;

  @override
  State<RegulagemScreen> createState() => _RegulagemScreenState();
}

class _RegulagemScreenState extends State<RegulagemScreen> {
  final _produtor = TextEditingController();
  final _fazenda = TextEditingController();
  final _talhao = TextEditingController();
  final _maquina = TextEditingController();
  final _consultor = TextEditingController();
  final _vazao = TextEditingController();
  final _velocidade = TextEditingController();
  final _espacamento = TextEditingController();
  final _numeroPontas = TextEditingController();
  final _pressao = TextEditingController();
  final _manejoCtrl = TextEditingController();
  final _precoBicoCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _limiteEntupido = TextEditingController();
  final _limiteDesgaste = TextEditingController();
  Timer? _limitesDebounce;

  DateTime _data = DateTime.now();
  double _litroMinIdeal = 0;
  double _manejo = 0;
  double _precoBico = 0;
  double _area = 0;
  List<PontaMedicao> _medicoes = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _produtor.dispose();
    _fazenda.dispose();
    _talhao.dispose();
    _maquina.dispose();
    _consultor.dispose();
    _vazao.dispose();
    _velocidade.dispose();
    _espacamento.dispose();
    _numeroPontas.dispose();
    _pressao.dispose();
    _manejoCtrl.dispose();
    _precoBicoCtrl.dispose();
    _areaCtrl.dispose();
    _limiteEntupido.dispose();
    _limiteDesgaste.dispose();
    _limitesDebounce?.cancel();
    super.dispose();
  }

  void _init() {
    final regulagem = widget.regulagem;
    if (regulagem != null) {
      _produtor.text = regulagem.produtor;
      _fazenda.text = regulagem.fazenda;
      _talhao.text = regulagem.talhao ?? '';
      _maquina.text = regulagem.maquina;
      _consultor.text = regulagem.consultor ?? '';
      _vazao.text = _value(regulagem.vazaoLha);
      _velocidade.text = _value(regulagem.velocidade);
      _espacamento.text = _value(regulagem.espacamentoCm);
      _numeroPontas.text =
          regulagem.numeroPontas == 0 ? '' : '${regulagem.numeroPontas}';
      _pressao.text = _value(regulagem.pressaoBar);
      _data = regulagem.dataRegulagem;
      _litroMinIdeal = regulagem.litroMinIdeal;
      _manejo = regulagem.manejoRS ?? 0;
      _precoBico = regulagem.precoBicoRS ?? 0;
      _area = regulagem.areaHa ?? 0;
      _manejoCtrl.text = _value(regulagem.manejoRS);
      _precoBicoCtrl.text = _value(regulagem.precoBicoRS);
      _areaCtrl.text = _value(regulagem.areaHa);
      _medicoes = List<PontaMedicao>.from(regulagem.medicoes);
    } else {
      _consultor.text =
          context.read<ConfiguracoesProvider>().configuracoes.nomeConsultor;
    }
    final limites = context.read<ConfiguracoesProvider>().configuracoes;
    _limiteEntupido.text = limites.limiteIrregular.toStringAsFixed(2);
    _limiteDesgaste.text = limites.limiteDesgaste.toStringAsFixed(2);
    _recalculate();
  }

  void _onLimiteChanged() {
    final entupido = _parse(_limiteEntupido.text);
    final desgaste = _parse(_limiteDesgaste.text);
    if (entupido > 0 && desgaste > 0) {
      _recalculate(
        context.read<ConfiguracoesProvider>().configuracoes.copyWith(
              limiteIrregular: entupido,
              limiteDesgaste: desgaste,
            ),
      );
    }
    _limitesDebounce?.cancel();
    _limitesDebounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(_persistLimites());
    });
  }

  Future<void> _persistLimites() async {
    if (!mounted || widget.readonly) return;
    final entupido = _parse(_limiteEntupido.text);
    final desgaste = _parse(_limiteDesgaste.text);
    if (entupido <= 0 || desgaste <= 0) return;
    try {
      await context.read<ConfiguracoesProvider>().saveLimites(
            limiteIrregular: entupido,
            limiteDesgaste: desgaste,
          );
    } catch (error) {
      debugPrint('Erro ao salvar limites de classificação: $error');
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível salvar os limites. Tente novamente.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _recalculate([Configuracoes? configOverride]) {
    final config = configOverride ?? _configParaClassificar();
    final numeroPontas = _parseInt(_numeroPontas.text);
    _litroMinIdeal = CalcUtils.calcularLitroMinIdeal(
      vazaoLha: _parse(_vazao.text),
      velocidade: _parse(_velocidade.text),
      espacamentoCm: _parse(_espacamento.text),
    );
    _syncPontas(numeroPontas, config);
    setState(() {});
  }

  Configuracoes _configParaClassificar() {
    final atual = context.read<ConfiguracoesProvider>().configuracoes;
    final entupido = _parse(_limiteEntupido.text);
    final desgaste = _parse(_limiteDesgaste.text);
    if (entupido <= 0 || desgaste <= 0) return atual;
    return atual.copyWith(
      limiteIrregular: entupido,
      limiteDesgaste: desgaste,
    );
  }

  void _syncPontas(int total, Configuracoes config) {
    if (total <= 0) {
      _medicoes = [];
      return;
    }
    final current = {for (final item in _medicoes) item.id: item};
    _medicoes = List.generate(total, (index) {
      final id = index + 1;
      final old = current[id];
      final value = old?.valorMedido;
      return PontaMedicao(
        id: id,
        valorMedido: value,
        status: CalcUtils.classificarPonta(
          valorMedido: value,
          litroMinIdeal: _litroMinIdeal,
          configuracoes: config,
        ),
      );
    });
  }

  void _updateMedicao(PontaInput input) {
    final config = _configParaClassificar();
    final value = _parseNullable(input.value);
    _medicoes = _medicoes.map((item) {
      if (item.id != input.id) return item;
      return PontaMedicao(
        id: item.id,
        valorMedido: value,
        status: CalcUtils.classificarPonta(
          valorMedido: value,
          litroMinIdeal: _litroMinIdeal,
          configuracoes: config,
        ),
      );
    }).toList();
    setState(() {});
  }

  void _updateEconomiaFromControllers() {
    _manejo = _parse(_manejoCtrl.text);
    _precoBico = _parse(_precoBicoCtrl.text);
    _area = _parse(_areaCtrl.text);
    setState(() {});
  }

  Future<void> _save() async {
    try {
      final now = DateTime.now();
      final regulagem = Regulagem(
        id: widget.regulagem?.id ?? const Uuid().v4(),
        produtor: _produtor.text.trim(),
        fazenda: _fazenda.text.trim(),
        talhao: _talhao.text.trim().isEmpty ? null : _talhao.text.trim(),
        maquina: _maquina.text.trim(),
        tipoOperacao: TipoOperacao.pulverizador,
        dataRegulagem: _data,
        consultor:
            _consultor.text.trim().isEmpty ? null : _consultor.text.trim(),
        vazaoLha: _parse(_vazao.text),
        velocidade: _parse(_velocidade.text),
        espacamentoCm: _parse(_espacamento.text),
        numeroPontas: _parseInt(_numeroPontas.text),
        pressaoBar: _parseNullable(_pressao.text),
        nLinhas: null,
        espacamentoLinhasM: null,
        eficiencia: null,
        populacaoDesejada: null,
        litroMinIdeal: _litroMinIdeal,
        medicoes: _medicoes,
        larguraUtil: null,
        rendimento: null,
        manejoRS: _manejo == 0 ? null : _manejo,
        precoBicoRS: _precoBico == 0 ? null : _precoBico,
        areaHa: _area == 0 ? null : _area,
        criadoEm: widget.regulagem?.criadoEm ?? now,
        atualizadoEm: now,
      );
      await context.read<RegulagensProvider>().save(regulagem);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Regulagem salva com sucesso ✓')),
      );
      Navigator.pop(context);
    } catch (error) {
      debugPrint('Erro ao salvar regulagem: $error');
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível salvar a regulagem. Tente novamente.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  bool get _etapa1Completa {
    return _produtor.text.trim().isNotEmpty &&
        _fazenda.text.trim().isNotEmpty &&
        _maquina.text.trim().isNotEmpty;
  }

  bool get _etapa2Completa {
    return _parse(_vazao.text) > 0 &&
        _parse(_velocidade.text) > 0 &&
        _parse(_espacamento.text) > 0 &&
        _parseInt(_numeroPontas.text) > 0;
  }

  bool get _temMedicao => _medicoes.any((item) => item.valorMedido != null);

  RegulagemPdfData _pdfData() {
    return RegulagemPdfData(
      produtor: _produtor.text.trim(),
      fazenda: _fazenda.text.trim(),
      talhao: _talhao.text.trim().isEmpty ? null : _talhao.text.trim(),
      maquina: _maquina.text.trim(),
      consultor: _consultor.text.trim().isEmpty ? null : _consultor.text.trim(),
      dataRegulagem: _data,
      vazaoLha: _parse(_vazao.text),
      velocidade: _parse(_velocidade.text),
      espacamentoCm: _parse(_espacamento.text),
      numeroPontas: _parseInt(_numeroPontas.text),
      pressaoBar: _parseNullable(_pressao.text),
      litroMinIdeal: _litroMinIdeal,
      medicoes: _medicoes,
      configuracoes: _configParaClassificar(),
      manejo: _manejo,
      precoBico: _precoBico,
      area: _area,
    );
  }

  double _parse(String text) {
    return double.tryParse(text.replaceAll(',', '.')) ?? 0;
  }

  double? _parseNullable(String text) {
    if (text.trim().isEmpty) return null;
    return double.tryParse(text.replaceAll(',', '.'));
  }

  int _parseInt(String text) {
    return int.tryParse(text) ?? 0;
  }

  String _value(double? value) {
    if (value == null || value == 0) return '';
    return value.toStringAsFixed(2);
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected == null) return;
    setState(() => _data = selected);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ConfiguracoesProvider>();
    final readonly = widget.readonly;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          readonly
              ? 'Visualizar Regulagem'
              : widget.regulagem != null
                  ? 'Editar Regulagem'
                  : 'Nova Regulagem',
        ),
        actions: [
          if (readonly && _temMedicao)
            ExportarPdfButton(
              data: _pdfData(),
              variant: ExportarPdfButtonVariant.icon,
            ),
          if (!readonly)
            TextButton(
              onPressed: _etapa1Completa ? _save : null,
              child: const Text('Salvar'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          ProgressiveCard(
            index: 1,
            title: 'Contexto da Operação',
            locked: false,
            complete: _etapa1Completa,
            child: _ContextStep(
              produtor: _produtor,
              fazenda: _fazenda,
              talhao: _talhao,
              maquina: _maquina,
              consultor: _consultor,
              area: _areaCtrl,
              manejo: _manejoCtrl,
              precoBico: _precoBicoCtrl,
              data: _data,
              readonly: readonly,
              onChanged: _recalculate,
              onEconomiaChanged: _updateEconomiaFromControllers,
              onPickDate: _pickDate,
            ),
          ),
          ProgressiveCard(
            index: 2,
            title: 'Parâmetros da Máquina',
            locked: !_etapa1Completa,
            complete: _etapa2Completa,
            child: _ParametrosStep(
              vazao: _vazao,
              velocidade: _velocidade,
              espacamento: _espacamento,
              numeroPontas: _numeroPontas,
              pressao: _pressao,
              readonly: readonly,
              onChanged: _recalculate,
            ),
          ),
          ProgressiveCard(
            index: 3,
            title: 'Cálculos Automáticos',
            locked: !_etapa2Completa,
            complete: _litroMinIdeal > 0,
            child: Column(
              children: [
                _ReadonlyResult(
                  label: 'Lt/min Ideal',
                  value: '${_litroMinIdeal.toStringAsFixed(3)} L/min',
                ),
                const SizedBox(height: AppSpacing.md),
                _FieldRow(
                  left: _LabeledField(
                    controller: _limiteEntupido,
                    label: 'Limite entupido (%)',
                    helper: 'Abaixo disso o bico fica Entupido. Salva sozinho.',
                    readonly: readonly,
                    onChanged: _onLimiteChanged,
                    decimal: true,
                  ),
                  right: _LabeledField(
                    controller: _limiteDesgaste,
                    label: 'Limite desgaste (%)',
                    helper: 'Acima disso o bico fica Desgaste. Salva sozinho.',
                    readonly: readonly,
                    onChanged: _onLimiteChanged,
                    decimal: true,
                  ),
                ),
              ],
            ),
          ),
          ProgressiveCard(
            index: 4,
            title: 'Medições das Pontas',
            locked: _litroMinIdeal <= 0,
            complete: _medicoes.any((item) => item.valorMedido != null),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PontasTable(
                  medicoes: _medicoes,
                  ideal: _litroMinIdeal,
                  configuracoes: _configParaClassificar(),
                  manejo: _manejo,
                  precoBico: _precoBico,
                  area: _area,
                  readonly: readonly,
                  onMedicaoChanged: _updateMedicao,
                ),
                if (_temMedicao && !readonly) ...[
                  const SizedBox(height: AppSpacing.lg),
                  ExportarPdfButton(
                    data: _pdfData(),
                    variant: ExportarPdfButtonVariant.outlined,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextStep extends StatelessWidget {
  const _ContextStep({
    required this.produtor,
    required this.fazenda,
    required this.talhao,
    required this.maquina,
    required this.consultor,
    required this.area,
    required this.manejo,
    required this.precoBico,
    required this.data,
    required this.readonly,
    required this.onChanged,
    required this.onEconomiaChanged,
    required this.onPickDate,
  });

  final TextEditingController produtor;
  final TextEditingController fazenda;
  final TextEditingController talhao;
  final TextEditingController maquina;
  final TextEditingController consultor;
  final TextEditingController area;
  final TextEditingController manejo;
  final TextEditingController precoBico;
  final DateTime data;
  final bool readonly;
  final VoidCallback onChanged;
  final VoidCallback onEconomiaChanged;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FieldRow(
          left: _LabeledField(
            controller: produtor,
            label: 'Produtor',
            readonly: readonly,
            onChanged: onChanged,
          ),
          right: _LabeledField(
            controller: fazenda,
            label: 'Fazenda',
            readonly: readonly,
            onChanged: onChanged,
          ),
        ),
        _FieldRow(
          left: _LabeledField(
            controller: talhao,
            label: 'Talhão',
            readonly: readonly,
            onChanged: onChanged,
          ),
          right: _LabeledField(
            controller: maquina,
            label: 'Máquina',
            readonly: readonly,
            onChanged: onChanged,
          ),
        ),
        _FieldRow(
          left: _LabeledField(
            controller: consultor,
            label: 'Consultor',
            readonly: readonly,
            onChanged: onChanged,
          ),
          right: _DateField(
            data: data,
            readonly: readonly,
            onPickDate: onPickDate,
          ),
        ),
        _FieldRow(
          left: _LabeledField(
            controller: area,
            label: 'Área (ha)',
            readonly: readonly,
            onChanged: onEconomiaChanged,
            decimal: true,
          ),
          right: _LabeledField(
            controller: manejo,
            label: 'Manejo (R\$)',
            readonly: readonly,
            onChanged: onEconomiaChanged,
            decimal: true,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _LabeledField(
            controller: precoBico,
            label: 'Preço do bico (R\$/un)',
            helper: 'Valor de um bico. Troca completa = preço × nº de pontas.',
            readonly: readonly,
            onChanged: onEconomiaChanged,
            decimal: true,
          ),
        ),
      ],
    );
  }
}

class _ParametrosStep extends StatelessWidget {
  const _ParametrosStep({
    required this.vazao,
    required this.velocidade,
    required this.espacamento,
    required this.numeroPontas,
    required this.pressao,
    required this.readonly,
    required this.onChanged,
  });

  final TextEditingController vazao;
  final TextEditingController velocidade;
  final TextEditingController espacamento;
  final TextEditingController numeroPontas;
  final TextEditingController pressao;
  final bool readonly;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FieldRow(
          left: _LabeledField(
            controller: vazao,
            label: 'Vazão (L/ha)',
            readonly: readonly,
            onChanged: onChanged,
            decimal: true,
          ),
          right: _LabeledField(
            controller: velocidade,
            label: 'Velocidade (km/h)',
            readonly: readonly,
            onChanged: onChanged,
            decimal: true,
          ),
        ),
        _FieldRow(
          left: _LabeledField(
            controller: espacamento,
            label: 'Espaçamento entre bicos (cm)',
            readonly: readonly,
            onChanged: onChanged,
            decimal: true,
          ),
          right: _LabeledField(
            controller: numeroPontas,
            label: 'Número de pontas',
            readonly: readonly,
            onChanged: onChanged,
            integer: true,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _LabeledField(
            controller: pressao,
            label: 'Pressão de trabalho (bar)',
            readonly: readonly,
            onChanged: onChanged,
            decimal: true,
          ),
        ),
      ],
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: right),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.controller,
    required this.label,
    required this.readonly,
    required this.onChanged,
    this.helper,
    this.decimal = false,
    this.integer = false,
  });

  final TextEditingController controller;
  final String label;
  final String? helper;
  final bool readonly;
  final VoidCallback onChanged;
  final bool decimal;
  final bool integer;

  @override
  Widget build(BuildContext context) {
    final TextInputType keyboardType;
    final List<TextInputFormatter> formatters;
    if (decimal) {
      keyboardType = const TextInputType.numberWithOptions(decimal: true);
      formatters = [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ];
    } else if (integer) {
      keyboardType = TextInputType.number;
      formatters = [FilteringTextInputFormatter.digitsOnly];
    } else {
      keyboardType = TextInputType.text;
      formatters = const [];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          enabled: !readonly,
          keyboardType: keyboardType,
          inputFormatters: formatters,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
          ),
          onChanged: (_) => onChanged(),
        ),
        if (helper != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(helper!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.data,
    required this.readonly,
    required this.onPickDate,
  });

  final DateTime data;
  final bool readonly;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat('dd/MM/yyyy', 'pt_BR').format(data);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data da regulagem',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            onTap: readonly ? null : onPickDate,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      formatted,
                      maxLines: 2,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadonlyResult extends StatelessWidget {
  const _ReadonlyResult({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
        ],
      ),
    );
  }
}
