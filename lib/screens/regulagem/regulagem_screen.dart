import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/calculo_utils.dart';
import '../../models/configuracoes.dart';
import '../../models/regulagem.dart';
import '../../providers/configuracoes_provider.dart';
import '../../providers/regulagens_provider.dart';
import '../../theme.dart';
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
  final _linhas = TextEditingController();
  final _espacamentoLinhas = TextEditingController();
  final _eficiencia = TextEditingController();
  final _populacao = TextEditingController();

  TipoOperacao _tipo = TipoOperacao.pulverizador;
  DateTime _data = DateTime.now();
  double _litroMinIdeal = 0;
  double _larguraUtil = 0;
  double _rendimento = 0;
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
    _linhas.dispose();
    _espacamentoLinhas.dispose();
    _eficiencia.dispose();
    _populacao.dispose();
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
      _linhas.text = regulagem.nLinhas == null ? '' : '${regulagem.nLinhas}';
      _espacamentoLinhas.text = _value(regulagem.espacamentoLinhasM);
      _eficiencia.text = _value(regulagem.eficiencia);
      _populacao.text = regulagem.populacaoDesejada == null
          ? ''
          : '${regulagem.populacaoDesejada}';
      _tipo = regulagem.tipoOperacao;
      _data = regulagem.dataRegulagem;
      _litroMinIdeal = regulagem.litroMinIdeal;
      _larguraUtil = regulagem.larguraUtil ?? 0;
      _rendimento = regulagem.rendimento ?? 0;
      _manejo = regulagem.manejoRS ?? 0;
      _precoBico = regulagem.precoBicoRS ?? 0;
      _area = regulagem.areaHa ?? 0;
      _medicoes = List<PontaMedicao>.from(regulagem.medicoes);
    } else {
      _consultor.text =
          context.read<ConfiguracoesProvider>().configuracoes.nomeConsultor;
    }
    _recalculate();
  }

  void _recalculate() {
    final config = context.read<ConfiguracoesProvider>().configuracoes;
    final numeroPontas = _parseInt(_numeroPontas.text);
    _litroMinIdeal = CalcUtils.calcularLitroMinIdeal(
      vazaoLha: _parse(_vazao.text),
      velocidade: _parse(_velocidade.text),
      espacamentoCm: _parse(_espacamento.text),
    );
    _larguraUtil = CalcUtils.calcularLarguraUtil(
      nLinhas: _parseInt(_linhas.text),
      espacamentoLinhasM: _parse(_espacamentoLinhas.text),
    );
    _rendimento = CalcUtils.calcularRendimentoOperacional(
      larguraUtil: _larguraUtil,
      velocidade: _parse(_velocidade.text),
      eficiencia: _parse(_eficiencia.text),
    );
    if (_tipo == TipoOperacao.pulverizador) {
      _syncPontas(numeroPontas, config);
    }
    setState(() {});
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
    final config = context.read<ConfiguracoesProvider>().configuracoes;
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

  void _updateEconomia(EconomiaInput input) {
    _manejo = _parse(input.manejo);
    _precoBico = _parse(input.precoBico);
    _area = _parse(input.area);
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
        tipoOperacao: _tipo,
        dataRegulagem: _data,
        consultor:
            _consultor.text.trim().isEmpty ? null : _consultor.text.trim(),
        vazaoLha: _tipo == TipoOperacao.pulverizador ? _parse(_vazao.text) : 0,
        velocidade: _parse(_velocidade.text),
        espacamentoCm:
            _tipo == TipoOperacao.pulverizador ? _parse(_espacamento.text) : 0,
        numeroPontas: _tipo == TipoOperacao.pulverizador
            ? _parseInt(_numeroPontas.text)
            : 0,
        pressaoBar: _parseNullable(_pressao.text),
        nLinhas:
            _tipo == TipoOperacao.plantadeira ? _parseInt(_linhas.text) : null,
        espacamentoLinhasM: _tipo == TipoOperacao.plantadeira
            ? _parse(_espacamentoLinhas.text)
            : null,
        eficiencia:
            _tipo == TipoOperacao.plantadeira ? _parse(_eficiencia.text) : null,
        populacaoDesejada: _parseIntNullable(_populacao.text),
        litroMinIdeal: _litroMinIdeal,
        medicoes: _tipo == TipoOperacao.pulverizador ? _medicoes : [],
        larguraUtil: _tipo == TipoOperacao.plantadeira ? _larguraUtil : null,
        rendimento: _tipo == TipoOperacao.plantadeira ? _rendimento : null,
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
    }
  }

  bool get _etapa1Completa {
    return _produtor.text.trim().isNotEmpty &&
        _fazenda.text.trim().isNotEmpty &&
        _maquina.text.trim().isNotEmpty;
  }

  bool get _etapa2Completa {
    if (_tipo == TipoOperacao.pulverizador) {
      return _parse(_vazao.text) > 0 &&
          _parse(_velocidade.text) > 0 &&
          _parse(_espacamento.text) > 0 &&
          _parseInt(_numeroPontas.text) > 0;
    }
    return _parseInt(_linhas.text) > 0 &&
        _parse(_espacamentoLinhas.text) > 0 &&
        _parse(_velocidade.text) > 0 &&
        _parse(_eficiencia.text) > 0;
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

  int? _parseIntNullable(String text) {
    if (text.trim().isEmpty) return null;
    return int.tryParse(text);
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
    final config = context.watch<ConfiguracoesProvider>().configuracoes;
    final readonly = widget.readonly;

    return Scaffold(
      appBar: AppBar(
        title: Text(readonly ? 'Visualizar Regulagem' : 'Nova Regulagem'),
        actions: [
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
              tipo: _tipo,
              data: _data,
              readonly: readonly,
              onChanged: _recalculate,
              onTipoChanged: (value) {
                _tipo = value;
                _recalculate();
              },
              onPickDate: _pickDate,
            ),
          ),
          ProgressiveCard(
            index: 2,
            title: 'Parâmetros da Máquina',
            locked: !_etapa1Completa,
            complete: _etapa2Completa,
            child: _ParametrosStep(
              tipo: _tipo,
              vazao: _vazao,
              velocidade: _velocidade,
              espacamento: _espacamento,
              numeroPontas: _numeroPontas,
              pressao: _pressao,
              linhas: _linhas,
              espacamentoLinhas: _espacamentoLinhas,
              eficiencia: _eficiencia,
              populacao: _populacao,
              readonly: readonly,
              onChanged: _recalculate,
            ),
          ),
          ProgressiveCard(
            index: 3,
            title: 'Cálculos Automáticos',
            locked: !_etapa2Completa,
            complete: _tipo == TipoOperacao.pulverizador
                ? _litroMinIdeal > 0
                : _rendimento > 0,
            child: _ResultadosStep(
              tipo: _tipo,
              litroMinIdeal: _litroMinIdeal,
              larguraUtil: _larguraUtil,
              rendimento: _rendimento,
            ),
          ),
          ProgressiveCard(
            index: 4,
            title: 'Medições das Pontas',
            locked: _tipo == TipoOperacao.pulverizador
                ? _litroMinIdeal <= 0
                : _rendimento <= 0,
            complete: _medicoes.any((item) => item.valorMedido != null),
            child: _tipo == TipoOperacao.pulverizador
                ? PontasTable(
                    medicoes: _medicoes,
                    ideal: _litroMinIdeal,
                    configuracoes: config,
                    manejo: _manejo,
                    precoBico: _precoBico,
                    area: _area,
                    readonly: readonly,
                    onMedicaoChanged: _updateMedicao,
                    onEconomiaChanged: _updateEconomia,
                  )
                : const Text(
                    'Plantadeira salva com largura útil e rendimento operacional.'),
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
    required this.tipo,
    required this.data,
    required this.readonly,
    required this.onChanged,
    required this.onTipoChanged,
    required this.onPickDate,
  });

  final TextEditingController produtor;
  final TextEditingController fazenda;
  final TextEditingController talhao;
  final TextEditingController maquina;
  final TextEditingController consultor;
  final TipoOperacao tipo;
  final DateTime data;
  final bool readonly;
  final VoidCallback onChanged;
  final ValueChanged<TipoOperacao> onTipoChanged;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FormField(
            controller: produtor,
            label: 'Produtor',
            readonly: readonly,
            onChanged: onChanged),
        _FormField(
            controller: fazenda,
            label: 'Fazenda',
            readonly: readonly,
            onChanged: onChanged),
        _FormField(
            controller: talhao,
            label: 'Talhão',
            readonly: readonly,
            onChanged: onChanged),
        _FormField(
            controller: maquina,
            label: 'Máquina',
            readonly: readonly,
            onChanged: onChanged),
        DropdownButtonFormField<TipoOperacao>(
          initialValue: tipo,
          decoration: const InputDecoration(labelText: 'Tipo de Operação'),
          items: const [
            DropdownMenuItem(
                value: TipoOperacao.pulverizador, child: Text('Pulverizador')),
            DropdownMenuItem(
                value: TipoOperacao.plantadeira, child: Text('Plantadeira')),
          ],
          onChanged: readonly
              ? null
              : (value) => onTipoChanged(value ?? TipoOperacao.pulverizador),
        ),
        const SizedBox(height: AppSpacing.md),
        _FormField(
            controller: consultor,
            label: 'Consultor',
            readonly: readonly,
            onChanged: onChanged),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Data da Regulagem'),
          subtitle: Text('${data.day}/${data.month}/${data.year}'),
          trailing: const Icon(Icons.calendar_today),
          onTap: readonly ? null : onPickDate,
        ),
      ],
    );
  }
}

class _ParametrosStep extends StatelessWidget {
  const _ParametrosStep({
    required this.tipo,
    required this.vazao,
    required this.velocidade,
    required this.espacamento,
    required this.numeroPontas,
    required this.pressao,
    required this.linhas,
    required this.espacamentoLinhas,
    required this.eficiencia,
    required this.populacao,
    required this.readonly,
    required this.onChanged,
  });

  final TipoOperacao tipo;
  final TextEditingController vazao;
  final TextEditingController velocidade;
  final TextEditingController espacamento;
  final TextEditingController numeroPontas;
  final TextEditingController pressao;
  final TextEditingController linhas;
  final TextEditingController espacamentoLinhas;
  final TextEditingController eficiencia;
  final TextEditingController populacao;
  final bool readonly;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    if (tipo == TipoOperacao.pulverizador) {
      return Column(
        children: [
          _FormField(
              controller: vazao,
              label: 'Vazão (L/ha)',
              readonly: readonly,
              onChanged: onChanged,
              number: true),
          _FormField(
              controller: velocidade,
              label: 'Velocidade (km/h)',
              readonly: readonly,
              onChanged: onChanged,
              number: true),
          _FormField(
              controller: espacamento,
              label: 'Espaçamento entre bicos (cm)',
              readonly: readonly,
              onChanged: onChanged,
              number: true),
          _FormField(
              controller: numeroPontas,
              label: 'Número de pontas',
              readonly: readonly,
              onChanged: onChanged,
              number: true),
          _FormField(
              controller: pressao,
              label: 'Pressão de trabalho (bar)',
              readonly: readonly,
              onChanged: onChanged,
              number: true),
        ],
      );
    }
    return Column(
      children: [
        _FormField(
            controller: linhas,
            label: 'Número de linhas',
            readonly: readonly,
            onChanged: onChanged,
            number: true),
        _FormField(
            controller: espacamentoLinhas,
            label: 'Espaçamento entre linhas (m)',
            readonly: readonly,
            onChanged: onChanged,
            number: true),
        _FormField(
            controller: velocidade,
            label: 'Velocidade (km/h)',
            readonly: readonly,
            onChanged: onChanged,
            number: true),
        _FormField(
            controller: eficiencia,
            label: 'Eficiência de campo (%)',
            readonly: readonly,
            onChanged: onChanged,
            number: true),
        _FormField(
            controller: populacao,
            label: 'População desejada (plantas/ha)',
            readonly: readonly,
            onChanged: onChanged,
            number: true),
      ],
    );
  }
}

class _ResultadosStep extends StatelessWidget {
  const _ResultadosStep({
    required this.tipo,
    required this.litroMinIdeal,
    required this.larguraUtil,
    required this.rendimento,
  });

  final TipoOperacao tipo;
  final double litroMinIdeal;
  final double larguraUtil;
  final double rendimento;

  @override
  Widget build(BuildContext context) {
    if (tipo == TipoOperacao.pulverizador) {
      return _ReadonlyResult(
          label: 'Lt/min Ideal',
          value: '${litroMinIdeal.toStringAsFixed(3)} L/min');
    }
    return Column(
      children: [
        _ReadonlyResult(
            label: 'Largura Útil',
            value: '${larguraUtil.toStringAsFixed(2)} m'),
        const SizedBox(height: AppSpacing.md),
        _ReadonlyResult(
            label: 'Rendimento',
            value: '${rendimento.toStringAsFixed(2)} ha/h'),
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

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    required this.readonly,
    required this.onChanged,
    this.number = false,
  });

  final TextEditingController controller;
  final String label;
  final bool readonly;
  final VoidCallback onChanged;
  final bool number;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextField(
        controller: controller,
        enabled: !readonly,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label),
        onChanged: (_) => onChanged(),
      ),
    );
  }
}
