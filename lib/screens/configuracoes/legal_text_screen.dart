import 'package:flutter/material.dart';

import '../../theme.dart';

class LegalTextScreen extends StatelessWidget {
  const LegalTextScreen({
    super.key,
    required this.titulo,
    required this.paragrafos,
  });

  final String titulo;
  final List<String> paragrafos;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          for (final paragrafo in paragrafos) ...[
            Text(
              paragrafo,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}
