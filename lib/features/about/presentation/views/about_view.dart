import 'package:flutter/material.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_spacing.dart';
import 'package:ocupa2/core/utils/app_url_launcher.dart';
import 'package:ocupa2/features/about/data/team_members.dart';
import 'package:ocupa2/features/about/presentation/widgets/team_member_card.dart';

class AboutView extends StatelessWidget {
  const AboutView({this.onLaunchUri = launchAppUri, super.key});

  final AppUriLauncher onLaunchUri;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: <Widget>[
                    const Icon(
                      Icons.groups_rounded,
                      size: 42,
                      color: AppColors.terracotta,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Equipo de desarrollo',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: AppColors.cream),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Conoce a las personas detrás de Ocupa2. '
                      'Puedes llamar o escribir por Telegram.',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.cream),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ...TeamMembers.all.map(
                (member) =>
                    TeamMemberCard(member: member, onLaunchUri: onLaunchUri),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
