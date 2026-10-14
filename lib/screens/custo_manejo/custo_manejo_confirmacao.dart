import 'package:flutter/material.dart';

import '../../models/custo_manejo.dart';
import '../../theme.dart';

Future<bool> confirmarRemoverProdutoManejo(
  BuildContext context,
  ProdutoManejo produto,
) async {
  final nome = produto.nome.trim();
  final rotulo = nome.isEmpty ? 'este produto' : '“$nome”';
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Remover produto?'),
      content: Text('$rotulo será retirado desta aplicação.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text(
            'Remover',
            style: TextStyle(color: AppColors.danger),
          ),
        ),
      ],
    ),
  );
  return ok == true;
}
