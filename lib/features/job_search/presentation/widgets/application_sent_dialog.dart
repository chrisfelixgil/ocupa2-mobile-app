import 'package:flutter/material.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_spacing.dart';
import 'package:ocupa2/app/theme/app_typography.dart';

enum ApplicationSentAction { keepExploring, viewApplications }

const Color _successGreen = Color(0xFF16A34A);
const Color _successGreenSoft = Color(0xFFDCFCE7);

Future<ApplicationSentAction> showApplicationSentDialog(
  BuildContext context,
) async {
  final ApplicationSentAction? action = await showDialog<ApplicationSentAction>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0x700F172A),
    builder: (BuildContext dialogContext) {
      return const ApplicationSentDialog();
    },
  );

  return action ?? ApplicationSentAction.keepExploring;
}

class ApplicationSentDialog extends StatelessWidget {
  const ApplicationSentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: _successGreenSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: _successGreen,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '¡Aplicación enviada!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 20,
                fontWeight: AppTypography.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tu aplicación fue enviada correctamente. El publicante revisará tu perfil y se pondrá en contacto.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 14,
                height: 1.4,
                fontWeight: AppTypography.regular,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(ApplicationSentAction.keepExploring);
              },
              child: const Text(
                'Seguir explorando',
                style: TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeight,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pop(ApplicationSentAction.viewApplications);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.text,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radius),
                  ),
                ),
                child: const Text(
                  'Ver mis aplicaciones',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: AppTypography.medium,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
