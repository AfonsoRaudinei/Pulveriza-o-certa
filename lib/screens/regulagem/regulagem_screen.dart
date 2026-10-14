import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/charts/vazao_chart_data.dart' show rotuloStatusPonta;
import '../../core/utils/calculo_utils.dart';
import '../../domain/calculos/limites_regulagem.dart';
import '../../models/configuracoes.dart';
import '../../models/foto_regulagem.dart';
import '../../models/regulagem.dart';
import '../../providers/configuracoes_provider.dart';
import '../../providers/regulagens_provider.dart';
import '../../theme.dart';
import '../custo_manejo/selecionar_custo_manejo_sheet.dart';
import '../../services/marca_fundo_cabecalho_service.dart';
import '../../services/marca_logo_service.dart';
import '../../services/regulagem_pdf_service.dart';
import 'widgets/etapa_resumo.dart';
import 'widgets/exportar_pdf_button.dart';
import 'widgets/fotos_regulagem_section.dart';
import 'widgets/pontas_table.dart';
import 'widgets/progressive_card.dart';
import 'widgets/regulagem_analise_block.dart';
import 'widgets/regulagem_context_step.dart';
import 'widgets/regulagem_parametros_step.dart';
import 'widgets/regulagem_vazao_ha_step.dart';

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

class _RegulagemScreenState extends State<RegulagemScreen>
    with WidgetsBindingObserver {
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
  final _numeroAplicacoesCtrl = TextEditingController();
  final _limiteEntupido = TextEditingController();
  final _limiteDesgaste = TextEditingController();
  Timer? _limitesDebounce;
  Timer? _recalculateDebounce;
  Timer? _economiaDebounce;
  Configuracoes? _recalculateConfigOverride;
  bool _repaintAfterShare = false;

  DateTime _data = DateTime.now();
  double _litroMinIdeal = 0;
  double _manejo = 0;
  double _precoBico = 0;
  double _area = 0;
  CulturaCultivo? _cultura;
  TipoPontaBico? _tipoPonta;
  int? _numeroAplicacoes;
  List<PontaMedicao> _medicoes = [];
  List<FotoRegulagem> _fotos = [];
  LadoConferenciaPontas _ladoConferenciaPontas = LadoConferenciaPontas.direita;
  late final String _id;
  DateTime? _criadoEm;
  Timer? _autoSaveDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _id = widget.regulagem?.id ?? const Uuid().v4();
    _criadoEm = widget.regulagem?.criadoEm;
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _repaintAfterShare) {
      _repaintAfterShare = false;
      _scheduleRepaintAfterForeground();
    }
  }

  void _markShareFlowStarted() => _repaintAfterShare = true;

  void _scheduleRepaintAfterForeground() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    _numeroAplicacoesCtrl.dispose();
    _limiteEntupido.dispose();
    _limiteDesgaste.dispose();
    _limitesDebounce?.cancel();
    _recalculateDebounce?.cancel();
    _economiaDebounce?.cancel();
    _autoSaveDebounce?.cancel();
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
      _fotos = List<FotoRegulagem>.from(regulagem.fotos);
      _ladoConferenciaPontas = regulagem.ladoConferenciaPontas;
      _cultura = regulagem.cultura;
      _tipoPonta = regulagem.tipoPonta;
      _numeroAplicacoes = regulagem.numeroAplicacoes;
      _numeroAplicacoesCtrl.text = regulagem.numeroAplicacoes == null
          ? ''
          : '${regulagem.numeroAplicacoes}';
    } else {
      _consultor.text =
          context.read<ConfiguracoesProvider>().configuracoes.nomeConsultor;
      _cultura = CulturaCultivo.soja;
    }
    final config = context.read<ConfiguracoesProvider>().configuracoes;
    final snapshot = regulagem?.limitesSnapshot;
    final limites = snapshot ?? config.limitesRegulagem;
    _limiteEntupido.text = limites.limiteEntupido.toStringAsFixed(2);
    _limiteDesgaste.text = limites.limiteDesgaste.toStringAsFixed(2);
    _recalculate();
  }

  void _onLimiteChanged() {
    final entupido = _parse(_limiteEntupido.text);
    final desgaste = _parse(_limiteDesgaste.text);
    if (entupido > 0 && desgaste > 0) {
      final validacao = validarLimitesRegulagem(
        limiteEntupido: entupido,
        limiteDesgaste: desgaste,
      );
      if (validacao.valido) {
        _recalculateDebounced(
          context.read<ConfiguracoesProvider>().configuracoes.copyWith(
                limiteIrregular: entupido,
                limiteDesgaste: desgaste,
              ),
        );
      }
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
    final validacao = validarLimitesRegulagem(
      limiteEntupido: entupido,
      limiteDesgaste: desgaste,
    );
    if (!validacao.valido) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(validacao.mensagem ?? 'Limites inválidos.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
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

  /// Campos de texto do contexto não alteram cálculos — só atualiza resumos.
  void _onSummaryFieldChanged() {
    setState(() {});
  }

  void _recalculateDebounced([Configuracoes? configOverride]) {
    _recalculateConfigOverride = configOverride;
    _recalculateDebounce?.cancel();
    _recalculateDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      final override = _recalculateConfigOverride;
      _recalculateConfigOverride = null;
      _recalculate(override);
    });
  }

  void _updateEconomiaDebounced() {
    _economiaDebounce?.cancel();
    _economiaDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _updateEconomiaFromControllers();
    });
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
    final appsRaw = _numeroAplicacoesCtrl.text.trim();
    _numeroAplicacoes =
        appsRaw.isEmpty ? null : int.tryParse(appsRaw);
    setState(() {});
  }

  int? get _numeroAplicacoesParaCalculo {
    if (_numeroAplicacoes != null && _numeroAplicacoes! > 0) {
      return _numeroAplicacoes;
    }
    return null;
  }

  String? _validarCamposEconomiaSafra() {
    if (_manejo <= 0) return null;
    final apps = _numeroAplicacoesParaCalculo;
    if (apps == null || apps <= 0) {
      return 'Informe o número de aplicações na safra (mín. 1) quando '
          'houver manejo (R\$).';
    }
    if (_tipoPonta == null) {
      return 'Selecione o tipo de ponta quando houver manejo (R\$).';
    }
    return null;
  }

  Regulagem _montarRegulagem() {
    final now = DateTime.now();
    _criadoEm ??= now;
    return Regulagem(
      id: _id,
      produtor: _produtor.text.trim(),
      fazenda: _fazenda.text.trim(),
      talhao: _talhao.text.trim().isEmpty ? null : _talhao.text.trim(),
      maquina: _maquina.text.trim(),
      tipoOperacao: TipoOperacao.pulverizador,
      dataRegulagem: _data,
      consultor: _consultor.text.trim().isEmpty ? null : _consultor.text.trim(),
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
      fotos: _fotos,
      ladoConferenciaPontas: _ladoConferenciaPontas,
      larguraUtil: null,
      rendimento: null,
      manejoRS: _manejo == 0 ? null : _manejo,
      precoBicoRS: _precoBico == 0 ? null : _precoBico,
      areaHa: _area == 0 ? null : _area,
      cultura: _cultura,
      tipoPonta: _tipoPonta,
      numeroAplicacoes: _numeroAplicacoesParaCalculo,
      limiteEntupido: _parse(_limiteEntupido.text),
      limiteDesgaste: _parse(_limiteDesgaste.text),
      criadoEm: _criadoEm!,
      atualizadoEm: now,
    );
  }

  void _onMovedToNextPonta() {
    if (widget.readonly) return;
    _autoSaveDebounce?.cancel();
    _autoSaveDebounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(_persist(closeAfter: false));
    });
  }

  void _onFotosChanged(List<FotoRegulagem> fotos) {
    setState(() => _fotos = fotos);
    _onMovedToNextPonta();
  }

  Future<void> _save() => _persist(closeAfter: true);

  Future<void> _persist({required bool closeAfter}) async {
    if (!_etapa1Completa) return;
    _updateEconomiaFromControllers();
    final erroEconomia = _validarCamposEconomiaSafra();
    if (erroEconomia != null) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(erroEconomia),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    final validacao = validarLimitesRegulagem(
      limiteEntupido: _parse(_limiteEntupido.text),
      limiteDesgaste: _parse(_limiteDesgaste.text),
    );
    if (!validacao.valido) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(validacao.mensagem ?? 'Limites inválidos.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    try {
      await context.read<RegulagensProvider>().save(_montarRegulagem());
      if (!mounted) return;
      if (closeAfter) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Regulagem salva com sucesso ✓')),
        );
        Navigator.pop(context);
      }
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
        _maquina.text.trim().isNotEmpty &&
        _cultura != null;
  }

  bool get _etapa2Completa {
    return _parse(_vazao.text) > 0 &&
        _parse(_velocidade.text) > 0 &&
        _parse(_espacamento.text) > 0 &&
        _parseInt(_numeroPontas.text) > 0;
  }

  bool get _temMedicao => _medicoes.any((item) => item.valorMedido != null);

  Widget? _resumoContexto() {
    return EtapaResumo.ouNulo([
      EtapaResumoLinha('Produtor', _produtor.text),
      EtapaResumoLinha('Fazenda', _fazenda.text),
      EtapaResumoLinha('Talhão', _talhao.text),
      EtapaResumoLinha('Máquina', _maquina.text),
      EtapaResumoLinha('Consultor', _consultor.text),
      EtapaResumoLinha(
        'Data da regulagem',
        DateFormat('dd/MM/yyyy', 'pt_BR').format(_data),
      ),
      EtapaResumoLinha('Área (ha)', _areaCtrl.text),
      EtapaResumoLinha('Preço do bico (R\$/un)', _precoBicoCtrl.text),
      EtapaResumoLinha('Manejo (R\$)', _manejoCtrl.text),
      if (_cultura != null) EtapaResumoLinha('Cultura', _cultura!.label),
      if (_tipoPonta != null)
        EtapaResumoLinha('Tipo de ponta', _tipoPonta!.label),
      if (_numeroAplicacoesCtrl.text.trim().isNotEmpty)
        EtapaResumoLinha(
          'Nº de aplicações na safra',
          _numeroAplicacoesCtrl.text,
        ),
    ]);
  }

  Widget? _resumoParametros() {
    return EtapaResumo.ouNulo([
      EtapaResumoLinha('Vazão (L/ha)', _vazao.text),
      EtapaResumoLinha('Velocidade (km/h)', _velocidade.text),
      EtapaResumoLinha('Espaçamento entre bicos (cm)', _espacamento.text),
      EtapaResumoLinha('Número de pontas', _numeroPontas.text),
      EtapaResumoLinha('Pressão de trabalho (bar)', _pressao.text),
    ]);
  }

  Widget? _resumoCalculos() {
    if (_litroMinIdeal <= 0) return null;
    return EtapaResumo.ouNulo([
      EtapaResumoLinha(
        'Lt/min Ideal',
        '${_litroMinIdeal.toStringAsFixed(3)} L/min',
      ),
    ]);
  }

  Widget? _resumoFotos() {
    if (_fotos.isEmpty) return null;
    final quantidade = _fotos.length;
    final linhas = <EtapaResumoLinha>[
      EtapaResumoLinha(
        'Fotos',
        '$quantidade ${quantidade == 1 ? 'foto' : 'fotos'}',
      ),
    ];
    for (var i = 0; i < _fotos.length; i++) {
      final foto = _fotos[i];
      final titulo = foto.titulo?.trim();
      final observacao = foto.observacao?.trim();
      final sufixo = quantidade == 1 ? '' : ' (${i + 1})';
      if (titulo != null && titulo.isNotEmpty) {
        linhas.add(EtapaResumoLinha('Título$sufixo', titulo));
      }
      if (observacao != null && observacao.isNotEmpty) {
        linhas.add(EtapaResumoLinha('Observação$sufixo', observacao));
      }
    }
    return EtapaResumo(linhas: linhas);
  }

  Widget? _resumoPontas() {
    return EtapaResumo.ouNulo([
      for (final ponta in _medicoes)
        if (ponta.valorMedido != null)
          EtapaResumoLinha(
            rotuloPonta(ponta.id, _ladoConferenciaPontas),
            '${ponta.valorMedido!.toStringAsFixed(3)} L/min · '
            '${CalcUtils.calcularPercentualPonta(
              valorMedido: ponta.valorMedido!,
              litroMinIdeal: _litroMinIdeal,
            ).toStringAsFixed(1)}% · '
            '${rotuloStatusPonta(ponta.status)}',
          ),
    ]);
  }

  Future<RegulagemPdfData> _pdfData() async {
    final configuracoes = _configParaClassificar();
    final marcaLogoBytes =
        await MarcaLogoService().lerBytes(configuracoes.marcaLogoArquivo);
    final marcaFundoCabecalhoBytes =
        await MarcaFundoCabecalhoService().lerBytes(
      configuracoes.marcaFundoCabecalhoArquivo,
    );

    return RegulagemPdfData(
      produtor: _produtor.text.trim(),
      fazenda: _fazenda.text.trim(),
      talhao: _talhao.text.trim().isEmpty ? null : _talhao.text.trim(),
      cultura: _cultura,
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
      ladoConferenciaPontas: _ladoConferenciaPontas,
      configuracoes: configuracoes,
      manejo: _manejo,
      precoBico: _precoBico,
      area: _area,
      numeroAplicacoes: _numeroAplicacoesParaCalculo,
      tipoPonta: _tipoPonta,
      fotos: _fotos,
      marcaLogoBytes: marcaLogoBytes,
      marcaFundoCabecalhoBytes: marcaFundoCabecalhoBytes,
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

  Future<void> _aplicarCustoManejoSalvo() async {
    if (widget.readonly) return;
    final total = await mostrarSelecaoCustoManejo(context);
    if (total == null || !mounted) return;
    _manejoCtrl.text = total.toStringAsFixed(2);
    _updateEconomiaFromControllers();
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
    final readonly = widget.readonly;
    final startExpanded = widget.regulagem == null;

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
              buildData: _pdfData,
              variant: ExportarPdfButtonVariant.icon,
              onShareFlowStarted: _markShareFlowStarted,
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
            showCompletedMarker: false,
            startExpanded: startExpanded,
            summary: _resumoContexto(),
            child: ContextStep(
              produtor: _produtor,
              fazenda: _fazenda,
              talhao: _talhao,
              maquina: _maquina,
              consultor: _consultor,
              area: _areaCtrl,
              manejo: _manejoCtrl,
              precoBico: _precoBicoCtrl,
              cultura: _cultura,
              tipoPonta: _tipoPonta,
              numeroAplicacoes: _numeroAplicacoesCtrl,
              data: _data,
              readonly: readonly,
              onChanged: _onSummaryFieldChanged,
              onEconomiaChanged: _updateEconomiaDebounced,
              onCulturaChanged: (value) {
                setState(() => _cultura = value);
              },
              onTipoPontaChanged: (value) {
                setState(() => _tipoPonta = value);
                _updateEconomiaDebounced();
              },
              onSelecionarCustoManejo:
                  readonly ? null : _aplicarCustoManejoSalvo,
              onPickDate: _pickDate,
            ),
          ),
          ProgressiveCard(
            index: 2,
            title: 'Parâmetros da Máquina',
            locked: !_etapa1Completa,
            complete: _etapa2Completa,
            showCompletedMarker: false,
            startExpanded: startExpanded,
            summary: _resumoParametros(),
            child: ParametrosStep(
              vazao: _vazao,
              velocidade: _velocidade,
              espacamento: _espacamento,
              numeroPontas: _numeroPontas,
              pressao: _pressao,
              readonly: readonly,
              onChanged: () => _recalculateDebounced(),
            ),
          ),
          ProgressiveCard(
            index: 3,
            title: 'Vazão / ha',
            locked: !_etapa2Completa,
            complete: _litroMinIdeal > 0,
            showCompletedMarker: false,
            startExpanded: startExpanded,
            summary: _resumoCalculos(),
            child: VazaoHaStep(
              litroMinIdeal: _litroMinIdeal,
              limiteEntupido: _limiteEntupido,
              limiteDesgaste: _limiteDesgaste,
              readonly: readonly,
              onLimiteChanged: _onLimiteChanged,
            ),
          ),
          ProgressiveCard(
            index: 4,
            title: 'Medições das Pontas',
            locked: _litroMinIdeal <= 0,
            complete: _medicoes.any((item) => item.valorMedido != null),
            showCompletedMarker: false,
            collapsible: false,
            startExpanded: startExpanded,
            summary: _resumoPontas(),
            child: PontasTable(
              medicoes: _medicoes,
              ideal: _litroMinIdeal,
              configuracoes: _configParaClassificar(),
              manejo: _manejo,
              precoBico: _precoBico,
              area: _area,
              ladoConferencia: _ladoConferenciaPontas,
              readonly: readonly,
              onMedicaoChanged: _updateMedicao,
              onMovedToNextPonta: _onMovedToNextPonta,
              onLadoConferenciaChanged: readonly
                  ? null
                  : (lado) {
                      setState(() => _ladoConferenciaPontas = lado);
                      _onMovedToNextPonta();
                    },
              exigirConfirmacaoTrocaLado: widget.regulagem != null,
            ),
          ),
          ProgressiveCard(
            index: 5,
            title: 'Fotos da Regulagem',
            locked: !_etapa1Completa,
            complete: _fotos.isNotEmpty,
            showCompletedMarker: false,
            startExpanded: startExpanded,
            summary: _resumoFotos(),
            child: FotosRegulagemSection(
              regulagemId: _id,
              fotos: _fotos,
              readonly: readonly,
              onChanged: _onFotosChanged,
              medicoes: _medicoes,
              ladoConferencia: _ladoConferenciaPontas,
            ),
          ),
          if (_litroMinIdeal > 0 && _temMedicao) ...[
            const SizedBox(height: AppSpacing.lg),
            RegulagemAnaliseBlock(
              medicoes: _medicoes,
              ideal: _litroMinIdeal,
              configuracoes: _configParaClassificar(),
              manejo: _manejo,
              precoBico: _precoBico,
              area: _area,
              numeroAplicacoes: _numeroAplicacoesParaCalculo,
              tipoPonta: _tipoPonta,
              ladoConferencia: _ladoConferenciaPontas,
              readonly: readonly,
              buildData: _pdfData,
              onShareFlowStarted: _markShareFlowStarted,
            ),
          ],
        ],
      ),
    );
  }
}
