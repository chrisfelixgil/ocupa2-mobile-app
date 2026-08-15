import 'package:flutter/material.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_typography.dart';
import 'package:ocupa2/core/utils/app_url_launcher.dart';
import 'package:ocupa2/features/about/data/models/team_member.dart';

const Color _telegramGreen = Color(0xFF16A34A);

class TeamMemberCard extends StatelessWidget {
  const TeamMemberCard({
    required this.member,
    this.onLaunchUri = launchAppUri,
    super.key,
  });

  final TeamMember member;
  final AppUriLauncher onLaunchUri;

  Future<void> _openUri(
    BuildContext context,
    Uri uri,
    String errorMessage,
  ) async {
    final bool launched = await onLaunchUri(uri);

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  member.photoAsset,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (
                        BuildContext context,
                        Object error,
                        StackTrace? stackTrace,
                      ) {
                        return Container(
                          width: 48,
                          height: 48,
                          color: AppColors.border,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.person_outline,
                            size: 24,
                            color: AppColors.text,
                          ),
                        );
                      },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      member.name,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Matrícula: ${member.matricula}',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 12,
                        fontWeight: AppTypography.regular,
                      ),
                    ),
                    Text(
                      member.phoneDisplay,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 12,
                        fontWeight: AppTypography.regular,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _ActionButton(
                key: Key('call_${member.matricula}'),
                icon: Icons.phone,
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                iconColor: AppColors.primary,
                onTap: () {
                  _openUri(
                    context,
                    member.phoneUri,
                    'No fue posible abrir la llamada.',
                  );
                },
              ),
              const SizedBox(width: 8),
              _ActionButton(
                key: Key('telegram_${member.matricula}'),
                icon: Icons.send,
                backgroundColor: _telegramGreen.withValues(alpha: 0.08),
                iconColor: _telegramGreen,
                onTap: () {
                  _openUri(
                    context,
                    member.telegramUrl,
                    'No fue posible abrir Telegram.',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(icon, size: 14, color: iconColor),
        ),
      ),
    );
  }
}
