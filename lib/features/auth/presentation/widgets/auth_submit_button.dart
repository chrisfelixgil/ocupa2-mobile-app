import 'package:flutter/material.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_spacing.dart';

class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    required this.label,
    required this.loadingLabel,
    required this.isLoading,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final String loadingLabel;
  final bool isLoading;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !isLoading,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: isLoading
              ? Row(
                  key: const ValueKey<String>('loading'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.3,
                        color: AppColors.onPrimary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(loadingLabel),
                  ],
                )
              : Row(
                  key: const ValueKey<String>('ready'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (icon != null) ...<Widget>[
                      Icon(icon),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Text(label),
                  ],
                ),
        ),
      ),
    );
  }
}
