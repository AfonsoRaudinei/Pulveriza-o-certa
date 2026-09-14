import 'package:flutter/material.dart';

import '../../../theme.dart';
import 'settings_card.dart';

class FaqItem {
  const FaqItem({required this.pergunta, required this.resposta});

  final String pergunta;
  final String resposta;
}

class SettingsAccordion extends StatelessWidget {
  const SettingsAccordion({super.key, required this.items});

  final List<FaqItem> items;

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: AppThemeColors.of(context).border,
              ),
            _FaqTile(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.item});

  final FaqItem item;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _aberto = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return InkWell(
      onTap: () => setState(() => _aberto = !_aberto),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.item.pergunta,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                Icon(
                  _aberto ? Icons.expand_less : Icons.expand_more,
                  color: colors.textTertiary,
                ),
              ],
            ),
            if (_aberto) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.item.resposta,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
