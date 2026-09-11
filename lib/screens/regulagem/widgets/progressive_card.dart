import 'package:flutter/material.dart';

import '../../../widgets/progressive_step_card.dart';

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
    final StepStatus status = locked
        ? StepStatus.locked
        : complete
            ? StepStatus.completed
            : StepStatus.active;
    return ProgressiveStepCard(
      stepNumber: index,
      title: title,
      status: status,
      child: child,
    );
  }
}
