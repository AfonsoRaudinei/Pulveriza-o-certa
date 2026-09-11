import 'package:flutter/material.dart';

import '../theme.dart';

enum StepStatus { locked, active, completed }

class ProgressiveStepCard extends StatelessWidget {
  const ProgressiveStepCard({
    super.key,
    required this.stepNumber,
    required this.title,
    this.description,
    required this.status,
    required this.child,
  });

  final int stepNumber;
  final String title;
  final String? description;
  final StepStatus status;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final complete = status == StepStatus.completed;
    final locked = status == StepStatus.locked;
    final borderColor =
        complete ? AppColors.success.withValues(alpha: 0.3) : colors.border;

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
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StepMarker(stepNumber: stepNumber, status: status),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        if (description != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            description!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
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
  const _StepMarker({required this.stepNumber, required this.status});

  final int stepNumber;
  final StepStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final complete = status == StepStatus.completed;
    final locked = status == StepStatus.locked;
    final color = complete ? AppColors.success : AppColors.primary;

    return Container(
      width: AppSpacing.xxxl,
      height: AppSpacing.xxxl,
      decoration: BoxDecoration(
        color: locked ? colors.surfaceAlt : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: locked || complete
              ? Icon(
                  locked ? Icons.lock_outline : Icons.check,
                  key: ValueKey(status),
                  color: locked ? colors.textTertiary : color,
                  size: AppSpacing.xl,
                )
              : Text(
                  '$stepNumber',
                  key: ValueKey(status),
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: color),
                ),
        ),
      ),
    );
  }
}
