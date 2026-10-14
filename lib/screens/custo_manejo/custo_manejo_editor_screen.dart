import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/extensions/double_extension.dart';
import '../../domain/calculos/calc_custo_manejo.dart';
import '../../models/custo_manejo.dart';
import '../../providers/custos_manejo_provider.dart';
import '../../screens/regulagem/widgets/regulagem_form_fields.dart';
import '../../theme.dart';
import 'custo_manejo_confirmacao.dart';

class CustoManejoEditorScreen extends StatefulWidget {
  const CustoManejoEditorScreen({super.key, this.custo});

  final CustoManejo? custo;

  @override
  State<CustoManejoEditorScreen> createState() =>
      _CustoManejoEditorScreenState();
}

class _CustoManejoEditorScreenState extends State<CustoManejoEditorScreen> {
  late CustoManejo _custo;
  late final TextEditingController _nomeCtrl;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _custo = widget.custo != null
        ? widget.custo!
        : novoCustoManejoRascunho();
    _nomeCtrl = TextEditingController(text: _custo.nome);
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    super.dispose();
  }

  double get _totalGeral => calcularTotalManejo(_custo);

  void _syncNome() {
    _custo = _custo.copyWith(nome: _nomeCtrl.text);
  }

  void _setAplicacoes(List<AplicacaoManejo> aplicacoes) {
    setState(() => _custo = _custo.copyWith(aplicacoes: aplicacoes));
  }

  void _adicionarAplicacao() {
    _setAplicacoes([
      ..._custo.aplicacoes,
      novaAplicacaoManejo(_custo.aplicacoes.length + 1),
    ]);
  }

  void _removerAplicacao(String id) {
    if (_custo.aplicacoes.length <= 1) return;
    _setAplicacoes(_custo.aplicacoes.where((a) => a.id != id).toList());
  }

  void _atualizarAplicacao(AplicacaoManejo aplicacao) {
    _setAplicacoes(
      _custo.aplicacoes.map((a) => a.id == aplicacao.id ? aplicacao : a).toList(),
    );
  }

  Future<void> _salvar() async {
    _syncNome();
    final erro = validarCustoManejoParaSalvar(_custo);
    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro), backgroundColor: AppColors.danger),
      );
      return;
    }
    setState(() => _salvando = true);
    try {
      final agora = DateTime.now();
      final salvar = _custo.copyWith(atualizadoEm: agora);
      await context.read<CustosManejoProvider>().save(salvar);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Custo de manejo salvo ✓')),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar.'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.custo == null ? 'Novo custo de manejo' : 'Editar custo'),
        actions: [
          TextButton(
            onPressed: _salvando ? null : _salvar,
            child: _salvando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Salvar'),
          ),
        ],
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg + bottomInset,
        ),
        children: [
          LabeledField(
            controller: _nomeCtrl,
            label: 'Nome do manejo',
            readonly: false,
            onChanged: _syncNome,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final aplicacao in _custo.aplicacoes) ...[
            _AplicacaoCard(
              aplicacao: aplicacao,
              podeRemover: _custo.aplicacoes.length > 1,
              onChanged: _atualizarAplicacao,
              onRemover: () => _removerAplicacao(aplicacao.id),
              onRemoverProduto: (produto) async {
                if (aplicacao.produtos.length <= 1) return;
                final ok = await confirmarRemoverProdutoManejo(context, produto);
                if (!ok || !mounted) return;
                _atualizarAplicacao(
                  aplicacao.copyWith(
                    produtos: aplicacao.produtos
                        .where((p) => p.id != produto.id)
                        .toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          OutlinedButton.icon(
            onPressed: _adicionarAplicacao,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar aplicação'),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Total geral do manejo',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  _totalGeral.toMoeda(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AplicacaoCard extends StatelessWidget {
  const _AplicacaoCard({
    required this.aplicacao,
    required this.podeRemover,
    required this.onChanged,
    required this.onRemover,
    required this.onRemoverProduto,
  });

  final AplicacaoManejo aplicacao;
  final bool podeRemover;
  final ValueChanged<AplicacaoManejo> onChanged;
  final VoidCallback onRemover;
  final Future<void> Function(ProdutoManejo produto) onRemoverProduto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final total = calcularTotalAplicacaoManejo(aplicacao);
    final nProdutos = aplicacao.produtos.length;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
              ),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.primary, width: 4),
                  bottom: BorderSide(color: colors.border),
                ),
                color: colors.surfaceAlt,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.layers_outlined, color: AppColors.primary, size: 22),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _RotuloAplicacaoField(
                      rotulo: aplicacao.rotulo,
                      onChanged: (value) =>
                          onChanged(aplicacao.copyWith(rotulo: value)),
                    ),
                  ),
                  if (podeRemover)
                    IconButton(
                      tooltip: 'Remover aplicação',
                      onPressed: onRemover,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: AppColors.danger,
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Text(
                    'Produtos',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      '$nProdutos',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  for (var i = 0; i < aplicacao.produtos.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.sm),
                    _ProdutoManejoRow(
                      key: ValueKey(aplicacao.produtos[i].id),
                      produto: aplicacao.produtos[i],
                      indice: i + 1,
                      onChanged: (p) {
                        onChanged(
                          aplicacao.copyWith(
                            produtos: aplicacao.produtos
                                .map((item) => item.id == p.id ? p : item)
                                .toList(),
                          ),
                        );
                      },
                      onRemover: aplicacao.produtos.length > 1
                          ? () => onRemoverProduto(aplicacao.produtos[i])
                          : null,
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.35),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                    ),
                    onPressed: () {
                      onChanged(
                        aplicacao.copyWith(
                          produtos: [
                            ...aplicacao.produtos,
                            novoProdutoManejo(),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Adicionar produto'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Total da aplicação',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          total.toMoeda(),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RotuloAplicacaoField extends StatefulWidget {
  const _RotuloAplicacaoField({
    required this.rotulo,
    required this.onChanged,
  });

  final String rotulo;
  final ValueChanged<String> onChanged;

  @override
  State<_RotuloAplicacaoField> createState() => _RotuloAplicacaoFieldState();
}

class _RotuloAplicacaoFieldState extends State<_RotuloAplicacaoField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.rotulo);
  }

  @override
  void didUpdateWidget(covariant _RotuloAplicacaoField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rotulo != widget.rotulo && _ctrl.text != widget.rotulo) {
      _ctrl.text = widget.rotulo;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LabeledField(
      controller: _ctrl,
      label: 'Aplicação',
      readonly: false,
      onChanged: () => widget.onChanged(_ctrl.text),
    );
  }
}

class _ProdutoManejoRow extends StatefulWidget {
  const _ProdutoManejoRow({
    super.key,
    required this.produto,
    required this.indice,
    required this.onChanged,
    this.onRemover,
  });

  final ProdutoManejo produto;
  final int indice;
  final ValueChanged<ProdutoManejo> onChanged;
  final Future<void> Function()? onRemover;

  @override
  State<_ProdutoManejoRow> createState() => _ProdutoManejoRowState();
}

class _ProdutoManejoRowState extends State<_ProdutoManejoRow> {
  late TextEditingController _nome;
  late TextEditingController _dose;
  late TextEditingController _valor;
  late bool _expandido;
  late final ExpansibleController _expansionCtrl;
  late final FocusNode _focusNome;
  late final FocusNode _focusDose;
  late final FocusNode _focusValor;

  bool _produtoVazio(ProdutoManejo p) =>
      p.nome.trim().isEmpty && p.dose == 0 && p.valorUnitario == 0;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.produto.nome);
    _dose = TextEditingController(text: _numText(widget.produto.dose));
    _valor = TextEditingController(text: _numText(widget.produto.valorUnitario));
    _expandido = _produtoVazio(widget.produto);
    _expansionCtrl = ExpansibleController();
    if (_expandido) {
      _expansionCtrl.expand();
    }
    _focusNome = FocusNode(debugLabel: 'produto-nome');
    _focusDose = FocusNode(debugLabel: 'produto-dose');
    _focusValor = FocusNode(debugLabel: 'produto-valor');
    for (final node in [_focusNome, _focusDose, _focusValor]) {
      node.addListener(() => _onCampoFocado(node));
    }
  }

  void _onCampoFocado(FocusNode node) {
    if (!node.hasFocus) return;
    if (!_expansionCtrl.isExpanded) {
      _expansionCtrl.expand();
      setState(() => _expandido = true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = node.context;
      if (ctx == null || !ctx.mounted) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.25,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void didUpdateWidget(covariant _ProdutoManejoRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.produto.id != widget.produto.id) {
      _nome.dispose();
      _dose.dispose();
      _valor.dispose();
      _nome = TextEditingController(text: widget.produto.nome);
      _dose = TextEditingController(text: _numText(widget.produto.dose));
      _valor =
          TextEditingController(text: _numText(widget.produto.valorUnitario));
      _expandido = _produtoVazio(widget.produto);
      if (_expandido) {
        _expansionCtrl.expand();
      } else {
        _expansionCtrl.collapse();
      }
    }
  }

  @override
  void dispose() {
    _focusNome.dispose();
    _focusDose.dispose();
    _focusValor.dispose();
    _expansionCtrl.dispose();
    _nome.dispose();
    _dose.dispose();
    _valor.dispose();
    super.dispose();
  }

  String _numText(double v) => v == 0 ? '' : v.toString();

  double _parse(String text) =>
      double.tryParse(text.replaceAll(',', '.')) ?? 0;

  void _emit() {
    widget.onChanged(
      widget.produto.copyWith(
        nome: _nome.text,
        dose: _parse(_dose.text),
        valorUnitario: _parse(_valor.text),
      ),
    );
  }

  String _tituloProduto() {
    final nome = widget.produto.nome.trim();
    return nome.isEmpty ? 'Novo produto' : nome;
  }

  String _resumoProduto() {
    final dose = widget.produto.dose;
    final valor = widget.produto.valorUnitario;
    if (dose == 0 && valor == 0) {
      return 'Toque para informar dose e valor unitário';
    }
    final partes = <String>[];
    if (dose != 0) {
      partes.add('Dose ${dose.toString()}');
    }
    if (valor != 0) {
      partes.add('${valor.toMoeda()}/un');
    }
    return partes.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final total = calcularTotalProdutoManejo(
      dose: widget.produto.dose,
      valorUnitario: widget.produto.valorUnitario,
    );
    final titulo = _tituloProduto();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: _expandido ? colors.surface : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: _expandido
              ? colors.border
              : AppColors.primary.withValues(alpha: 0.28),
        ),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey<String>('produto-manejo-${widget.produto.id}'),
          controller: _expansionCtrl,
          initiallyExpanded: _expandido,
          onExpansionChanged: (value) => setState(() => _expandido = value),
          maintainState: true,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          shape: const Border(),
          collapsedShape: const Border(),
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.primary,
          leading: CircleAvatar(
            radius: 18,
            backgroundColor:
                _expandido ? AppColors.primaryLight : colors.surface,
            foregroundColor: AppColors.primary,
            child: Text(
              '${widget.indice}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _resumoProduto(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  total.toMoeda(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
            LabeledField(
              controller: _nome,
              label: 'Produto',
              readonly: false,
              onChanged: _emit,
              focusNode: _focusNome,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _focusDose.requestFocus(),
              scrollPadding: const EdgeInsets.only(bottom: 120),
            ),
            const SizedBox(height: AppSpacing.sm),
            FieldRow(
              left: LabeledField(
                controller: _dose,
                label: 'Dose',
                readonly: false,
                onChanged: _emit,
                decimal: true,
                focusNode: _focusDose,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _focusValor.requestFocus(),
                scrollPadding: const EdgeInsets.only(bottom: 120),
              ),
              right: LabeledField(
                controller: _valor,
                label: 'Valor unitário (R\$)',
                readonly: false,
                onChanged: _emit,
                decimal: true,
                focusNode: _focusValor,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                scrollPadding: const EdgeInsets.only(bottom: 120),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (widget.onRemover != null)
                  TextButton.icon(
                    onPressed: () async => widget.onRemover?.call(),
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.danger.withValues(alpha: 0.9),
                    ),
                    label: Text(
                      'Remover produto',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Spacer(),
                Text(
                  'Total ${total.toMoeda()}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ),
      ),
    );
  }
}
