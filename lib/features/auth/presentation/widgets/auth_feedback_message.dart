import 'package:flutter/material.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_spacing.dart';

class AuthFeedbackMessage extends StatelessWidget {
  const AuthFeedbackMessage({this.errorMessage, this.successMessage, super.key})
    : assert(
        errorMessage == null || successMessage == null,
        'No se deben mostrar éxito y error al mismo tiempo.',
      );

  final String? errorMessage;
  final String? successMessage;

  @override
  Widget build(BuildContext context) {
    final bool isError = errorMessage != null;
    final String? message = errorMessage ?? successMessage;

    if (message == null || message.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final Color backgroundColor = isError
        ? AppColors.errorSurface
        : AppColors.successSurface;

    final Color foregroundColor = isError ? AppColors.error : AppColors.success;

    final IconData icon = isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;

    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: foregroundColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: foregroundColor),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
