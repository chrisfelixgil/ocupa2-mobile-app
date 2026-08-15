import 'package:flutter/material.dart';
import 'package:ocupa2/core/widgets/app_bottom_nav.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_typography.dart';
import 'package:ocupa2/core/utils/app_url_launcher.dart';
import 'package:ocupa2/features/about/data/team_members.dart';
import 'package:ocupa2/features/about/presentation/widgets/team_member_card.dart';

class AboutView extends StatelessWidget {
  const AboutView({this.onLaunchUri = launchAppUri, super.key});

  final AppUriLauncher onLaunchUri;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      bottomNavigationBar: const AppBottomNav(
        selected: AppBottomNavTab.profile,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: <Widget>[
                  Material(
                    color: AppColors.surface,
                    shape: const CircleBorder(
                      side: BorderSide(color: AppColors.border),
                    ),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(
                          Icons.chevron_left,
                          size: 16,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Acerca de Ocupa2',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 18,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Ocupa2',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: <Widget>[
                            SizedBox(
                              width: 64,
                              height: 64,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Color(0x142563EB),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(16),
                                  ),
                                ),
                                child: Icon(
                                  Icons.work_outline,
                                  size: 36,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Ocupa2',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 24,
                                fontWeight: AppTypography.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Versión 1.0.0',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Nuestra misión es conectar el talento técnico '
                              'dominicano con hogares y empresas locales que '
                              'necesitan soluciones rápidas, confiables y seguras.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 13,
                                fontWeight: AppTypography.regular,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Equipo de desarrollo',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...TeamMembers.all.map(
                      (member) => TeamMemberCard(
                        member: member,
                        onLaunchUri: onLaunchUri,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
