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
    this.showCompletedMarker = true,
    this.startExpanded = true,
    this.collapsible = true,
  });

  final int index;
  final String title;
  final bool locked;
  final bool complete;
  final Widget child;
  final Widget? summary;
  final bool showCompletedMarker;

  /// Nova regulagem: etapa ativa abre expandida. Editar existente: recolhida com resumo.
  final bool startExpanded;

  /// Quando false e desbloqueada, corpo fixo sem `ExpansionTile` (ex.: Medições das Pontas).
  final bool collapsible;

  @override
  State<ProgressiveCard> createState() => _ProgressiveCardState();
}

class _ProgressiveCardState extends State<ProgressiveCard> {
  late final ExpansibleController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ExpansibleController();
    if (!widget.locked && widget.startExpanded) {
      _controller.expand();
    }
    _controller.addListener(_onExpansion);
  }

  @override
  void didUpdateWidget(covariant ProgressiveCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.collapsible &&
        oldWidget.locked &&
        !widget.locked &&
        widget.startExpanded) {
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
    final useExpansion = widget.locked || widget.collapsible;
    if (!useExpansion) {
      return ProgressiveStepCard(
        stepNumber: widget.index,
        title: widget.title,
        status: status,
        expandable: false,
        showCompletedMarker: widget.showCompletedMarker,
        child: widget.child,
      );
    }

    final mostrarResumo =
        !widget.locked && !_controller.isExpanded && widget.summary != null;
    return ProgressiveStepCard(
      stepNumber: widget.index,
      title: widget.title,
      status: status,
      expandable: true,
      initiallyExpanded: !widget.locked && widget.startExpanded,
      expansionController: _controller,
      summary: mostrarResumo ? widget.summary : null,
      showCompletedMarker: widget.showCompletedMarker,
      child: widget.child,
    );
  }
}
