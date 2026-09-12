import 'package:flutter/material.dart';

import '../../../widgets/progressive_step_card.dart';

class ProgressiveCard extends StatefulWidget {
  const ProgressiveCard({
    super.key,
    required this.index,
    required this.title,
    required this.locked,
    required this.complete,
    required this.child,
    this.summary,
  });

  final int index;
  final String title;
  final bool locked;
  final bool complete;
  final Widget child;
  final Widget? summary;

  @override
  State<ProgressiveCard> createState() => _ProgressiveCardState();
}

class _ProgressiveCardState extends State<ProgressiveCard> {
  late final ExpansibleController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ExpansibleController();
    if (!widget.locked) {
      _controller.expand();
    }
    _controller.addListener(_onExpansion);
  }

  @override
  void didUpdateWidget(covariant ProgressiveCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locked && !widget.locked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_controller.isExpanded) {
          _controller.expand();
        }
      });
    } else if (!oldWidget.locked && widget.locked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.isExpanded) {
          _controller.collapse();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onExpansion);
    _controller.dispose();
    super.dispose();
  }

  void _onExpansion() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final StepStatus status = widget.locked
        ? StepStatus.locked
        : widget.complete
            ? StepStatus.completed
            : StepStatus.active;
    final mostrarResumo =
        !widget.locked && !_controller.isExpanded && widget.summary != null;
    return ProgressiveStepCard(
      stepNumber: widget.index,
      title: widget.title,
      status: status,
      expandable: true,
      initiallyExpanded: !widget.locked,
      expansionController: _controller,
      summary: mostrarResumo ? widget.summary : null,
      child: widget.child,
    );
  }
}
