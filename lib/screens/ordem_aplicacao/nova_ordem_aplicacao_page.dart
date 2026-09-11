import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../domain/ordem_aplicacao/ordens.dart';
import '../../models/cadastro_local.dart';
import '../../providers/cadastros_provider.dart';
import '../../providers/ordens_aplicacao_provider.dart';
import '../../providers/regulagens_provider.dart';
import '../../theme.dart';
import '../../widgets/progressive_step_card.dart';
import 'widgets/alerta_orientacao.dart';
import 'widgets/campo_rotulado.dart';
import 'widgets/totais_chips.dart';

class NovaOrdemAplicacaoPage extends StatefulWidget {
  const NovaOrdemAplicacaoPage({super.key, this.ordem});

  final OrdemAplicacao? ordem;

  @override
  State<NovaOrdemAplicacaoPage> createState() => _NovaOrdemAplicacaoPageState();
}

class _NovaOrdemAplicacaoPageState extends State<NovaOrdemAplicacaoPage> {
  static const _uuid = Uuid();

  late final String _id;
  late final DateTime _criadoEm;
  final _areaAplicar = TextEditingController();
  final _responsavel = TextEditingController();
  final _temperatura = TextEditingController();
  final _umidade = TextEditingController();
  final _vento = TextEditingController();
  final _volumeCalda = TextEditingController();
  final _dose = TextEditingController();
  final _observacaoProduto = TextEditingController();
  final _buscaProduto = TextEditingController();

  ClienteLocal? _cliente;
  FazendaLocal? _fazenda;
  TalhaoLocal? _talhao;
  AlvoAplicacao? _alvo;
  ProdutoCatalogo? _produtoSelecionado;
  UnidadeDose _unidade = UnidadeDose.lHa;
  bool _reservarEstoque = false;
  List<ProdutoAplicacao> _produtos = [];
  List<AnexoAplicacao> _anexos = [];
  ExecucaoAplicacao _execucao = const ExecucaoAplicacao();
  List<String> _erros = [];
  bool _estoqueBaixado = false;

  @override
  void initState() {
    super.initState();
    final existente = widget.ordem;
    _id = existente?.id ?? _uuid.v4();
    _criadoEm = existente?.criadoEm ?? DateTime.now();
    if (existente != null) {
      _areaAplicar.text =
          existente.areaAplicar == 0 ? '' : existente.areaAplicar.toString();
      _alvo = existente.alvo;
      _produtos = List.of(existente.produtos);
      _anexos = List.of(existente.anexos);
      _execucao = existente.execucao;
      _estoqueBaixado = existente.estoqueBaixado;
      _responsavel.text = existente.execucao.responsavel ?? '';
      _temperatura.text = _num(existente.execucao.temperaturaC);
      _umidade.text = _num(existente.execucao.umidadePct);
      _vento.text = _num(existente.execucao.ventoKmh);
      _volumeCalda.text = _num(existente.execucao.volumeCaldaLha);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final cadastros = context.read<CadastrosProvider>();
    final regulagens = context.read<RegulagensProvider>().regulagens;
    await cadastros.load();
    await cadastros.sugerirDeRegulagens(regulagens);
    if (!mounted) return;
    _hidratarCadastros(cadastros.cadastros);
  }

  void _hidratarCadastros(CadastrosLocais cadastros) {
    final existente = widget.ordem;
    if (existente == null) return;
    setState(() {
      _cliente = _clientePorId(cadastros, existente.clienteId) ??
          _clientePorNome(cadastros, existente.clienteNome);
      _fazenda = _fazendaPorId(cadastros, existente.fazendaId) ??
          _fazendaPorNome(cadastros, existente.fazendaNome);
      _talhao = _talhaoPorId(cadastros, existente.talhaoId) ??
          _talhaoPorNome(cadastros, existente.talhaoNome);
    });
  }

  ClienteLocal? _clientePorId(CadastrosLocais cadastros, String? id) {
    if (id == null) return null;
    for (final item in cadastros.clientes) {
      if (item.id == id) return item;
    }
    return null;
  }

  ClienteLocal? _clientePorNome(CadastrosLocais cadastros, String nome) {
    final alvo = nome.trim().toLowerCase();
    if (alvo.isEmpty) return null;
    for (final item in cadastros.clientes) {
      if (item.nome.toLowerCase() == alvo) return item;
    }
    return null;
  }

  FazendaLocal? _fazendaPorId(CadastrosLocais cadastros, String? id) {
    if (id == null) return null;
    for (final item in cadastros.fazendas) {
      if (item.id == id) return item;
    }
    return null;
  }

  FazendaLocal? _fazendaPorNome(CadastrosLocais cadastros, String nome) {
    final alvo = nome.trim().toLowerCase();
    if (alvo.isEmpty) return null;
    for (final item in cadastros.fazendas) {
      if (item.nome.toLowerCase() == alvo) return item;
    }
    return null;
  }

  TalhaoLocal? _talhaoPorId(CadastrosLocais cadastros, String? id) {
    if (id == null) return null;
    for (final item in cadastros.talhoes) {
      if (item.id == id) return item;
    }
    return null;
  }

  TalhaoLocal? _talhaoPorNome(CadastrosLocais cadastros, String nome) {
    final alvo = nome.trim().toLowerCase();
    if (alvo.isEmpty) return null;
    for (final item in cadastros.talhoes) {
      if (item.nome.toLowerCase() == alvo) return item;
    }
    return null;
  }

  String _num(double? value) {
    if (value == null || value == 0) return '';
    return value.toString();
  }

  double _parse(String text) {
    return double.tryParse(text.replaceAll(',', '.')) ?? 0;
  }

  double get _area => _parse(_areaAplicar.text);

  OrdemAplicacao _montar() {
    return OrdemAplicacao(
      id: _id,
      clienteId: _cliente?.id,
      clienteNome: _cliente?.nome ?? '',
      fazendaId: _fazenda?.id,
      fazendaNome: _fazenda?.nome ?? '',
      talhaoId: _talhao?.id,
      talhaoNome: _talhao?.nome ?? '',
      areaTalhaoHa: _talhao?.areaHa ?? 0,
      areaAplicar: _area,
      alvo: _alvo,
      produtos: _produtos,
      execucao: _execucao.copyWith(
        responsavel: _responsavel.text.trim(),
        temperaturaC: _parse(_temperatura.text),
        umidadePct: _parse(_umidade.text),
        ventoKmh: _parse(_vento.text),
        volumeCaldaLha: _parse(_volumeCalda.text),
      ),
      anexos: _anexos,
      estoqueBaixado: _estoqueBaixado,
      criadoEm: _criadoEm,
      atualizadoEm: DateTime.now(),
    );
  }

  StepStatus _status({required bool locked, required bool complete}) {
    if (locked) return StepStatus.locked;
    if (complete) return StepStatus.completed;
    return StepStatus.active;
  }

  Future<void> _salvar() async {
    final ordem = _montar();
    final cadastros = context.read<CadastrosProvider>();
    final erros = validarOrdem(
      ordem,
      estoquePorProdutoId: cadastros.estoquePorProdutoId,
    );
    setState(() => _erros = erros);
    if (erros.isNotEmpty) return;

    var persistida = ordem;
    if (!persistida.estoqueBaixado) {
      final baixas = <String, double>{};
      final darSaida = persistida.execucao.darSaidaEstoque &&
          persistida.execucao.status == StatusOrdem.concluida;
      for (final produto in persistida.produtos) {
        if (!produto.reservarEstoque && !darSaida) continue;
        baixas[produto.produtoId] = (baixas[produto.produtoId] ?? 0) +
            produto.quantidadeTotal(persistida.areaAplicar);
      }
      if (baixas.isNotEmpty) {
        await cadastros.baixarEstoque(baixas);
        persistida = persistida.copyWith(estoqueBaixado: true);
      }
    }

    if (!mounted) return;
    await context.read<OrdensAplicacaoProvider>().save(persistida);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Ordem salva com sucesso ✓')));
    Navigator.pop(context);
  }

  Future<String?> _pedirTexto(String titulo, {String? hint}) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.isEmpty) return null;
    return result;
  }

  @override
  void dispose() {
    _areaAplicar.dispose();
    _responsavel.dispose();
    _temperatura.dispose();
    _umidade.dispose();
    _vento.dispose();
    _volumeCalda.dispose();
    _dose.dispose();
    _observacaoProduto.dispose();
    _buscaProduto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cadastros = context.watch<CadastrosProvider>().cadastros;
    final ordem = _montar();
    final etapa1 = ordem.etapa1Completa;
    final etapa2 = ordem.etapa2Completa;
    final fazendas = cadastros.fazendas
        .where((item) => _cliente != null && item.clienteId == _cliente!.id)
        .toList();
    final talhoes = cadastros.talhoes
        .where((item) => _fazenda != null && item.fazendaId == _fazenda!.id)
        .toList();
    final produtosFiltrados = cadastros.produtos.where((item) {
      final q = _buscaProduto.text.trim().toLowerCase();
      if (q.isEmpty) return true;
      return item.nome.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.ordem == null
              ? 'Nova Ordem de Aplicação'
              : 'Editar Ordem de Aplicação',
        ),
        actions: [
          TextButton(
            onPressed: etapa1 && etapa2 ? _salvar : null,
            child: const Text('Salvar'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          ..._erros.map((erro) => AlertaOrientacao(texto: erro)),
          ProgressiveStepCard(
            stepNumber: 1,
            title: 'Contexto da Operação',
            status: _status(locked: false, complete: etapa1),
            child: _contexto(cadastros, fazendas, talhoes),
          ),
          ProgressiveStepCard(
            stepNumber: 2,
            title: 'Produtos & Dose',
            status: _status(locked: !etapa1, complete: etapa2),
            child: _produtosStep(cadastros, produtosFiltrados),
          ),
          ProgressiveStepCard(
            stepNumber: 3,
            title: 'Execução',
            description: 'Preenchimento opcional',
            status: _status(locked: !etapa2, complete: false),
            child: _execucaoStep(cadastros),
          ),
          ProgressiveStepCard(
            stepNumber: 4,
            title: 'Anexos',
            status: _status(locked: !etapa2, complete: _anexos.isNotEmpty),
            child: _anexosStep(),
          ),
        ],
      ),
    );
  }

  Widget _contexto(
    CadastrosLocais cadastros,
    List<FazendaLocal> fazendas,
    List<TalhaoLocal> talhoes,
  ) {
    return Column(
      children: [
        CampoDropdown<ClienteLocal>(
          label: 'Cliente',
          value: _cliente,
          items: cadastros.clientes,
          itemLabel: (item) => item.nome,
          novoLabel: '+ Novo cliente',
          onNovo: () async {
            final nome = await _pedirTexto('Novo cliente');
            if (nome == null || !mounted) return;
            final cliente = await context.read<CadastrosProvider>().addCliente(
                  nome,
                );
            setState(() {
              _cliente = cliente;
              _fazenda = null;
              _talhao = null;
            });
          },
          onChanged: (cliente) => setState(() {
            _cliente = cliente;
            _fazenda = null;
            _talhao = null;
          }),
        ),
        const SizedBox(height: AppSpacing.md),
        CampoDropdown<FazendaLocal>(
          label: 'Fazenda',
          value: _fazenda,
          items: fazendas,
          itemLabel: (item) => item.nome,
          novoLabel: '+ Nova fazenda',
          onNovo: _cliente == null
              ? null
              : () async {
                  final nome = await _pedirTexto('Nova fazenda');
                  if (nome == null || !mounted) return;
                  final fazenda = await context
                      .read<CadastrosProvider>()
                      .addFazenda(clienteId: _cliente!.id, nome: nome);
                  setState(() {
                    _fazenda = fazenda;
                    _talhao = null;
                  });
                },
          onChanged: (fazenda) => setState(() {
            _fazenda = fazenda;
            _talhao = null;
          }),
        ),
        const SizedBox(height: AppSpacing.md),
        CampoDropdown<TalhaoLocal>(
          label: 'Talhão',
          value: _talhao,
          items: talhoes,
          itemLabel: (item) => item.nome,
          novoLabel: '+ Novo talhão',
          onNovo: _fazenda == null
              ? null
              : () async {
                  final nome = await _pedirTexto('Novo talhão');
                  if (nome == null || !mounted) return;
                  final areaTexto = await _pedirTexto(
                    'Área do talhão (ha)',
                    hint: 'ex.: 80',
                  );
                  if (areaTexto == null || !mounted) return;
                  final talhao =
                      await context.read<CadastrosProvider>().addTalhao(
                            fazendaId: _fazenda!.id,
                            nome: nome,
                            areaHa: _parse(areaTexto),
                          );
                  setState(() => _talhao = talhao);
                },
          onChanged: (talhao) => setState(() => _talhao = talhao),
        ),
        const SizedBox(height: AppSpacing.md),
        CampoSomenteLeitura(
          label: 'Área do Talhão (ha)',
          value: _talhao == null ? '' : _talhao!.areaHa.toStringAsFixed(2),
        ),
        const SizedBox(height: AppSpacing.md),
        CampoRotulado(
          label: 'Área a Aplicar (ha)',
          controller: _areaAplicar,
          decimal: true,
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.md),
        CampoDropdown<AlvoAplicacao>(
          label: 'Alvo',
          value: _alvo,
          items: AlvoAplicacao.values,
          itemLabel: (item) => item.label,
          onChanged: (alvo) => setState(() => _alvo = alvo),
        ),
      ],
    );
  }

  Widget _produtosStep(
    CadastrosLocais cadastros,
    List<ProdutoCatalogo> produtosFiltrados,
  ) {
    final totais = calcularTotaisPorUnidade(
      _produtos.map(
        (item) => (
          unidade: item.unidade,
          quantidadeTotal: item.quantidadeTotal(_area),
        ),
      ),
    );
    final qtdTotal = _produtoSelecionado == null
        ? 0.0
        : calcularQuantidadeTotal(dose: _parse(_dose.text), areaAplicar: _area);
    final estoque = _produtoSelecionado == null
        ? 0.0
        : cadastros.produtos
            .firstWhere(
              (item) => item.id == _produtoSelecionado!.id,
              orElse: () => _produtoSelecionado!,
            )
            .estoque;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampoRotulado(
          label: 'Buscar produto',
          controller: _buscaProduto,
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.md),
        CampoDropdown<ProdutoCatalogo>(
          label: 'Produto',
          value: produtosFiltrados.contains(_produtoSelecionado)
              ? _produtoSelecionado
              : null,
          items: produtosFiltrados,
          itemLabel: (item) =>
              '${item.nome} (${item.estoque} ${item.unidadePadrao})',
          novoLabel: '+ Novo produto',
          onNovo: () async {
            final nome = await _pedirTexto('Novo produto');
            if (nome == null || !mounted) return;
            final estoqueTexto = await _pedirTexto(
              'Estoque atual',
              hint: 'quantidade no depósito',
            );
            if (estoqueTexto == null || !mounted) return;
            final produto = await context.read<CadastrosProvider>().addProduto(
                  nome: nome,
                  unidadePadrao: _unidade.label,
                  estoque: _parse(estoqueTexto),
                );
            setState(() => _produtoSelecionado = produto);
          },
          onChanged: (produto) {
            setState(() {
              _produtoSelecionado = produto;
              if (produto != null) {
                _unidade =
                    UnidadeDoseX.fromLabel(produto.unidadePadrao) ?? _unidade;
              }
            });
          },
        ),
        const SizedBox(height: AppSpacing.md),
        CampoRotulado(
          label: 'Dose',
          controller: _dose,
          decimal: true,
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.md),
        CampoDropdown<UnidadeDose>(
          label: 'Unidade',
          value: _unidade,
          items: UnidadeDose.values,
          itemLabel: (item) => item.label,
          onChanged: (unidade) {
            if (unidade != null) setState(() => _unidade = unidade);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        CampoSomenteLeitura(
          label: 'Qtd Total',
          value: '${qtdTotal.toStringAsFixed(2)} ${_unidade.quantidadeLabel}',
          destacado: true,
          helper: 'dose × área a aplicar',
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Reservar no estoque'),
          value: _reservarEstoque,
          onChanged: (value) =>
              setState(() => _reservarEstoque = value ?? false),
        ),
        CampoRotulado(label: 'Observação', controller: _observacaoProduto),
        if (_reservarEstoque &&
            _produtoSelecionado != null &&
            qtdTotal > estoque)
          AlertaOrientacao(
            titulo: 'Estoque insuficiente',
            texto:
                'Disponível: $estoque ${_unidade.quantidadeLabel}. Necessário: ${qtdTotal.toStringAsFixed(2)}.',
          ),
        const SizedBox(height: AppSpacing.sm),
        FilledButton.icon(
          onPressed: _produtoSelecionado == null || _parse(_dose.text) <= 0
              ? null
              : () {
                  setState(() {
                    _produtos = [
                      ..._produtos,
                      ProdutoAplicacao(
                        id: _uuid.v4(),
                        produtoId: _produtoSelecionado!.id,
                        nomeProduto: _produtoSelecionado!.nome,
                        dose: _parse(_dose.text),
                        unidade: _unidade,
                        reservarEstoque: _reservarEstoque,
                        observacao: _observacaoProduto.text.trim().isEmpty
                            ? null
                            : _observacaoProduto.text.trim(),
                      ),
                    ];
                    _dose.clear();
                    _observacaoProduto.clear();
                    _reservarEstoque = false;
                  });
                },
          icon: const Icon(Icons.add),
          label: const Text('Adicionar produto'),
        ),
        const SizedBox(height: AppSpacing.lg),
        TotaisChips(totais: totais),
        const SizedBox(height: AppSpacing.md),
        ..._produtos.map((produto) {
          final qtd = produto.quantidadeTotal(_area);
          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ListTile(
              title: Text(produto.nomeProduto),
              subtitle: Text(
                '${produto.dose} ${produto.unidade.label} → ${qtd.toStringAsFixed(2)} ${produto.unidade.quantidadeLabel}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(
                  () => _produtos =
                      _produtos.where((item) => item.id != produto.id).toList(),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _execucaoStep(CadastrosLocais cadastros) {
    MaquinaLocal? maquinaAtual;
    for (final item in cadastros.maquinas) {
      if (item.id == _execucao.maquinaId) {
        maquinaAtual = item;
        break;
      }
    }
    return Column(
      children: [
        CampoRotulado(label: 'Responsável', controller: _responsavel),
        const SizedBox(height: AppSpacing.md),
        CampoDropdown<MaquinaLocal>(
          label: 'Máquina',
          value: maquinaAtual,
          items: cadastros.maquinas,
          itemLabel: (item) => item.nome,
          novoLabel: '+ Nova máquina',
          onNovo: () async {
            final nome = await _pedirTexto('Nova máquina');
            if (nome == null || !mounted) return;
            final maquina = await context.read<CadastrosProvider>().addMaquina(
                  nome,
                );
            setState(() {
              _execucao = _execucao.copyWith(
                maquinaId: maquina.id,
                maquinaNome: maquina.nome,
              );
            });
          },
          onChanged: (maquina) => setState(() {
            _execucao = _execucao.copyWith(
              maquinaId: maquina?.id,
              maquinaNome: maquina?.nome,
            );
          }),
        ),
        const SizedBox(height: AppSpacing.md),
        _DateTimeField(
          label: 'Data/Hora Início',
          value: _execucao.inicio,
          onPick: () => _pickDateTime(inicio: true),
        ),
        const SizedBox(height: AppSpacing.md),
        _DateTimeField(
          label: 'Data/Hora Fim',
          value: _execucao.fim,
          onPick: () => _pickDateTime(inicio: false),
        ),
        const SizedBox(height: AppSpacing.md),
        CampoRotulado(
          label: 'Temperatura (°C)',
          controller: _temperatura,
          decimal: true,
        ),
        const SizedBox(height: AppSpacing.md),
        CampoRotulado(
          label: 'Umidade (%)',
          controller: _umidade,
          decimal: true,
        ),
        const SizedBox(height: AppSpacing.md),
        CampoRotulado(label: 'Vento (km/h)', controller: _vento, decimal: true),
        const SizedBox(height: AppSpacing.md),
        CampoRotulado(
          label: 'Volume de Calda (L/ha)',
          controller: _volumeCalda,
          decimal: true,
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Dar saída do estoque ao concluir'),
          value: _execucao.darSaidaEstoque,
          onChanged: (value) => setState(() {
            _execucao = _execucao.copyWith(darSaidaEstoque: value ?? false);
          }),
        ),
        CampoDropdown<StatusOrdem>(
          label: 'Status',
          value: _execucao.status,
          items: StatusOrdem.values,
          itemLabel: (item) => item.label,
          onChanged: (status) {
            if (status != null) {
              setState(() => _execucao = _execucao.copyWith(status: status));
            }
          },
        ),
      ],
    );
  }

  Future<void> _pickDateTime({required bool inicio}) async {
    final atual = (inicio ? _execucao.inicio : _execucao.fim) ?? DateTime.now();
    final data = await showDatePicker(
      context: context,
      initialDate: atual,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (data == null || !mounted) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(atual),
    );
    if (hora == null || !mounted) return;
    final value = DateTime(
      data.year,
      data.month,
      data.day,
      hora.hour,
      hora.minute,
    );
    setState(() {
      _execucao = inicio
          ? _execucao.copyWith(inicio: value)
          : _execucao.copyWith(fim: value);
    });
  }

  Widget _anexosStep() {
    final colors = AppThemeColors.of(context);
    return Column(
      children: [
        InkWell(
          onTap: _adicionarAnexo,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xxl),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: colors.border,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.attach_file, color: colors.textTertiary, size: 32),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Toque para anexar um arquivo',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ..._anexos.map(
          (anexo) => Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ListTile(
              leading: const Icon(Icons.insert_drive_file_outlined),
              title: Text(anexo.nome),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(
                  () => _anexos =
                      _anexos.where((item) => item.id != anexo.id).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _adicionarAnexo() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) return;
    final picked = File(result.files.single.path!);
    final nome = result.files.single.name;
    final docs = await getApplicationDocumentsDirectory();
    final destDir = Directory('${docs.path}/anexos_ordem');
    if (!await destDir.exists()) await destDir.create(recursive: true);
    final id = _uuid.v4();
    final dest = File('${destDir.path}/${id}_$nome');
    await picked.copy(dest.path);
    if (!mounted) return;
    setState(() {
      _anexos = [
        ..._anexos,
        AnexoAplicacao(id: id, nome: nome, path: dest.path),
      ];
    });
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.label,
    required this.value,
    required this.onPick,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final texto = value == null
        ? 'Toque para escolher'
        : '${value!.day.toString().padLeft(2, '0')}/'
            '${value!.month.toString().padLeft(2, '0')}/'
            '${value!.year} '
            '${value!.hour.toString().padLeft(2, '0')}:'
            '${value!.minute.toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        OutlinedButton(
          onPressed: onPick,
          child: Align(alignment: Alignment.centerLeft, child: Text(texto)),
        ),
      ],
    );
  }
}
