import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/fotos_regulagem_constants.dart';
import '../../../models/foto_regulagem.dart';
import '../../../services/fotos_regulagem_service.dart';
import '../../../theme.dart';
import 'foto_regulagem_sheet.dart';

class FotosRegulagemSection extends StatefulWidget {
  const FotosRegulagemSection({
    super.key,
    required this.regulagemId,
    required this.fotos,
    required this.readonly,
    required this.onChanged,
    this.fotosService,
  });

  final String regulagemId;
  final List<FotoRegulagem> fotos;
  final bool readonly;
  final ValueChanged<List<FotoRegulagem>> onChanged;
  final FotosRegulagemService? fotosService;

  @override
  State<FotosRegulagemSection> createState() => _FotosRegulagemSectionState();
}

class _FotosRegulagemSectionState extends State<FotosRegulagemSection> {
  late final FotosRegulagemService _service =
      widget.fotosService ?? FotosRegulagemService();
  final _picker = ImagePicker();
  bool _busy = false;

  bool get _podeAdicionar =>
      !widget.readonly &&
      widget.fotos.length < FotosRegulagemConstants.maxFotosPorRegulagem;

  Future<void> _capturar() async {
    if (!_podeAdicionar || _busy) return;

    setState(() => _busy = true);
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: FotosRegulagemConstants.maxLadoPx.toDouble(),
        imageQuality: FotosRegulagemConstants.qualidadeJpeg,
      );
      if (picked == null || !mounted) return;

      final foto =
          await _service.salvarFoto(File(picked.path), widget.regulagemId);
      if (!mounted) return;

      final arquivo = await _service.resolverArquivo(foto);
      if (!mounted) return;
      await FotoRegulagemSheet.show(
        context: context,
        imageFile: arquivo,
        foto: foto,
        isNew: true,
        readonly: false,
        onSave: (atualizada) {
          widget.onChanged([...widget.fotos, atualizada]);
        },
        onDelete: () async {
          await _service.removerFoto(foto);
        },
      );

      if (!mounted) return;
      final aindaExiste = await arquivo.exists();
      if (aindaExiste && !widget.fotos.any((f) => f.arquivo == foto.arquivo)) {
        await _service.removerFoto(foto);
      }
    } catch (error) {
      debugPrint('Erro ao adicionar foto: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Não foi possível adicionar a foto.'),
            backgroundColor: AppColors.danger,
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _abrirFoto(FotoRegulagem foto) async {
    final arquivo = await _service.resolverArquivo(foto);
    if (!await arquivo.exists() || !mounted) return;

    await FotoRegulagemSheet.show(
      context: context,
      imageFile: arquivo,
      foto: foto,
      isNew: false,
      readonly: widget.readonly,
      onSave: widget.readonly
          ? null
          : (atualizada) {
              final lista = [...widget.fotos];
              final index = lista.indexWhere((f) => f.arquivo == foto.arquivo);
              if (index >= 0) {
                lista[index] = atualizada;
                widget.onChanged(lista);
              }
            },
      onDelete: widget.readonly
          ? null
          : () async {
              await _service.removerFoto(foto);
              widget.onChanged(
                widget.fotos.where((f) => f.arquivo != foto.arquivo).toList(),
              );
            },
    );
  }

  @override
  Widget build(BuildContext context) {
    final slots = <Widget>[
      for (final foto in widget.fotos)
        _FotoThumbnail(
          foto: foto,
          service: _service,
          onTap: () => _abrirFoto(foto),
        ),
      if (_podeAdicionar)
        _AdicionarFotoSlot(
          busy: _busy,
          onTap: _capturar,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RepaintBoundary(
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1,
            children: slots,
          ),
        ),
        if (!widget.readonly &&
            widget.fotos.length >= FotosRegulagemConstants.maxFotosPorRegulagem)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              'Limite de ${FotosRegulagemConstants.maxFotosPorRegulagem} fotos atingido.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
      ],
    );
  }
}

class _FotoThumbnail extends StatefulWidget {
  const _FotoThumbnail({
    required this.foto,
    required this.service,
    required this.onTap,
  });

  final FotoRegulagem foto;
  final FotosRegulagemService service;
  final VoidCallback onTap;

  @override
  State<_FotoThumbnail> createState() => _FotoThumbnailState();
}

class _FotoThumbnailState extends State<_FotoThumbnail> {
  late Future<File> _arquivoFuture;

  @override
  void initState() {
    super.initState();
    _arquivoFuture = widget.service.resolverArquivo(widget.foto);
  }

  @override
  void didUpdateWidget(covariant _FotoThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.foto.arquivo != widget.foto.arquivo) {
      _arquivoFuture = widget.service.resolverArquivo(widget.foto);
    }
  }

  int _cacheSidePx(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    const listPadding = AppSpacing.lg * 2;
    const cardPadding = AppSpacing.lg * 2;
    const gridGaps = AppSpacing.md * 2;
    final cellLogical =
        (screenWidth - listPadding - cardPadding - gridGaps) / 3;
    return (cellLogical * dpr).round().clamp(64, 512);
  }

  @override
  Widget build(BuildContext context) {
    final cacheSide = _cacheSidePx(context);

    return Material(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: AspectRatio(
          aspectRatio: 1,
          child: FutureBuilder<File>(
            future: _arquivoFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              return Image.file(
                snapshot.data!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                cacheWidth: cacheSide,
                cacheHeight: cacheSide,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textTertiary,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AdicionarFotoSlot extends StatefulWidget {
  const _AdicionarFotoSlot({
    required this.busy,
    required this.onTap,
  });

  final bool busy;
  final VoidCallback onTap;

  @override
  State<_AdicionarFotoSlot> createState() => _AdicionarFotoSlotState();
}

class _AdicionarFotoSlotState extends State<_AdicionarFotoSlot> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        _focused ? AppColors.iosPrimary : AppColors.iosDashedBorder;
    final background = _focused ? AppColors.iosFocusFill : Colors.transparent;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: widget.busy ? null : widget.onTap,
        onHighlightChanged: (value) => setState(() => _focused = value),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: AspectRatio(
          aspectRatio: 1,
          child: CustomPaint(
            painter: _DashedBorderPainter(color: borderColor),
            child: Center(
              child: widget.busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      Icons.add,
                      size: 28,
                      color: _focused
                          ? AppColors.iosPrimary
                          : AppColors.textSecondary,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 2.0;
    const dashLength = 6.0;
    const gapLength = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      const Radius.circular(AppRadius.sm),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashLength;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
