import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme.dart';

/// Seletor simples (HSV + hex) para cor personalizada do cabeçalho.
Future<Color?> showSeletorCorMarcaDialog(
  BuildContext context, {
  required Color initial,
}) {
  return showDialog<Color>(
    context: context,
    builder: (ctx) => _SeletorCorMarcaDialog(initial: initial),
  );
}

class _SeletorCorMarcaDialog extends StatefulWidget {
  const _SeletorCorMarcaDialog({required this.initial});

  final Color initial;

  @override
  State<_SeletorCorMarcaDialog> createState() => _SeletorCorMarcaDialogState();
}

class _SeletorCorMarcaDialogState extends State<_SeletorCorMarcaDialog> {
  late HSVColor _hsv;
  late final TextEditingController _hex;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initial);
    _hex = TextEditingController(text: _hexFromColor(widget.initial));
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  Color get _color => _hsv.toColor();

  void _syncHex() {
    _hex.text = _hexFromColor(_color);
  }

  void _applyHex(String value) {
    final parsed = _colorFromHex(value);
    if (parsed == null) return;
    setState(() => _hsv = HSVColor.fromColor(parsed));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cor personalizada'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Matiz', style: Theme.of(context).textTheme.labelSmall),
            Slider(
              value: _hsv.hue,
              min: 0,
              max: 360,
              onChanged: (v) => setState(() {
                _hsv = _hsv.withHue(v);
                _syncHex();
              }),
            ),
            Text('Saturação', style: Theme.of(context).textTheme.labelSmall),
            Slider(
              value: _hsv.saturation,
              min: 0,
              max: 1,
              onChanged: (v) => setState(() {
                _hsv = _hsv.withSaturation(v);
                _syncHex();
              }),
            ),
            Text('Brilho', style: Theme.of(context).textTheme.labelSmall),
            Slider(
              value: _hsv.value,
              min: 0,
              max: 1,
              onChanged: (v) => setState(() {
                _hsv = _hsv.withValue(v);
                _syncHex();
              }),
            ),
            TextField(
              controller: _hex,
              decoration: const InputDecoration(
                labelText: 'Hex',
                prefixText: '#',
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Fa-f]')),
                LengthLimitingTextInputFormatter(8),
              ],
              onSubmitted: _applyHex,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _color),
          child: const Text('Usar cor'),
        ),
      ],
    );
  }
}

String _hexFromColor(Color c) {
  final v = c.toARGB32() & 0xFFFFFF;
  return v.toRadixString(16).padLeft(6, '0').toUpperCase();
}

Color? _colorFromHex(String raw) {
  var s = raw.trim().replaceAll('#', '');
  if (s.length == 6) s = 'FF$s';
  if (s.length != 8) return null;
  final n = int.tryParse(s, radix: 16);
  if (n == null) return null;
  return Color(n);
}
