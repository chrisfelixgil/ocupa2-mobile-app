import 'package:flutter/material.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_spacing.dart';
import 'package:ocupa2/core/utils/app_url_launcher.dart';
import 'package:ocupa2/features/about/data/models/team_member.dart';

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
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                member.photoAsset,
                width: 88,
                height: 88,
                fit: BoxFit.cover,
                errorBuilder:
                    (
                      BuildContext context,
                      Object error,
                      StackTrace? stackTrace,
                    ) {
                      return Container(
                        width: 88,
                        height: 88,
                        color: AppColors.border,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.person_rounded,
                          size: 40,
                          color: AppColors.navy,
                        ),
                      );
                    },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    member.name,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Matrícula: ${member.matricula}',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: <Widget>[
                      ActionChip(
                        key: Key('call_${member.matricula}'),
                        avatar: const Icon(Icons.phone_rounded, size: 18),
                        label: Text(member.phoneDisplay),
                        onPressed: () {
                          _openUri(
                            context,
                            member.phoneUri,
                            'No fue posible abrir la llamada.',
                          );
                        },
                      ),
                      ActionChip(
                        key: Key('telegram_${member.matricula}'),
                        avatar: const Icon(Icons.send_rounded, size: 18),
                        label: const Text('Telegram'),
                        onPressed: () {
                          _openUri(
                            context,
                            member.telegramUrl,
                            'No fue posible abrir Telegram.',
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
