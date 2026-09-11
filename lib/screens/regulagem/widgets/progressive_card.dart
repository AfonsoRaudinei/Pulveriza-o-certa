import 'package:flutter/material.dart';

import '../../../theme.dart';

class ProgressiveCard extends StatelessWidget {
  const ProgressiveCard({
    super.key,
    required this.index,
    required this.title,
    required this.locked,
    required this.complete,
    required this.child,
  });

  final int index;
  final String title;
  final bool locked;
  final bool complete;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        complete ? AppColors.success.withValues(alpha: 0.3) : AppColors.border;
    return AnimatedOpacity(
      opacity: locked ? 0.4 : 1,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: locked,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: AppSpacing.xl),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StepMarker(index: index, locked: locked, complete: complete),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(title,
                        style: Theme.of(context).textTheme.headlineSmall),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _StepMarker extends StatelessWidget {
  const _StepMarker({
    required this.index,
    required this.locked,
    required this.complete,
  });

  final int index;
  final bool locked;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final color = complete ? AppColors.success : AppColors.primary;
    return Container(
      width: AppSpacing.xxxl,
      height: AppSpacing.xxxl,
      decoration: BoxDecoration(
        color: locked ? AppColors.surfaceAlt : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Center(
        child: locked || complete
            ? Icon(
                locked ? Icons.lock_outline : Icons.check,
                color: locked ? AppColors.textTertiary : color,
                size: AppSpacing.xl,
              )
            : Text(
                '$index',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: color),
              ),
      ),
    );
  }
}
