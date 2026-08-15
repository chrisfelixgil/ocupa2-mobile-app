import 'package:flutter/material.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_typography.dart';

const List<String> kPublishStepLabels = <String>[
  'Información',
  'Detalles',
  'Preguntas',
  'Revisar',
];

const Color _stepCompletedGreen = Color(0xFF16A34A);
const Color _stepCompletedGreenSoft = Color(0x1416A34A);

class PublishStepper extends StatelessWidget {
  const PublishStepper({
    required this.currentStep,
    this.reachableStep,
    this.onStepSelected,
    super.key,
  });

  /// Índice 0–3 (Información, Detalles, Preguntas, Revisar).
  final int currentStep;

  /// Último paso ya visitado; se puede volver a él tocando el stepper.
  final int? reachableStep;

  final ValueChanged<int>? onStepSelected;

  @override
  Widget build(BuildContext context) {
    final int clamped = currentStep.clamp(0, 3);
    final int farthest = (reachableStep ?? clamped).clamp(0, 3);
    final double progress = (clamped + 1) / kPublishStepLabels.length;

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          children: <Widget>[
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width - 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    for (int i = 0; i < kPublishStepLabels.length; i++)
                      _StepNode(
                        index: i,
                        label: kPublishStepLabels[i],
                        active: i == clamped,
                        completed: i < clamped,
                        enabled: i <= farthest,
                        onTap: onStepSelected,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: AppColors.border,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.index,
    required this.label,
    required this.active,
    required this.completed,
    required this.enabled,
    this.onTap,
  });

  final int index;
  final String label;
  final bool active;
  final bool completed;
  final bool enabled;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final Color circleColor;
    final Color borderColor;
    if (completed) {
      circleColor = _stepCompletedGreenSoft;
      borderColor = _stepCompletedGreen;
    } else if (active) {
      circleColor = AppColors.primary;
      borderColor = AppColors.primary;
    } else {
      circleColor = AppColors.surface;
      borderColor = AppColors.border;
    }

    final Widget node = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: circleColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: completed
              ? const Icon(Icons.check, size: 14, color: _stepCompletedGreen)
              : Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: active ? AppColors.onPrimary : AppColors.text,
                    fontSize: 12,
                    fontWeight: AppTypography.bold,
                  ),
                ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: active ? AppColors.primary : AppColors.text,
            fontSize: 13,
            fontWeight: active
                ? AppTypography.medium
                : AppTypography.regular,
          ),
        ),
      ],
    );

    if (!enabled || onTap == null) {
      return node;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onTap!(index),
        behavior: HitTestBehavior.opaque,
        child: node,
      ),
    );
  }
}
