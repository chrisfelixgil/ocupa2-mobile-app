import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/router/app_routes.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_typography.dart';
import 'package:ocupa2/features/job_posting/presentation/viewmodels/offer_detail_status.dart';
import 'package:ocupa2/features/job_posting/presentation/viewmodels/offer_detail_view_model.dart';
import 'package:ocupa2/features/my_activity/data/models/application.dart';
import 'package:provider/provider.dart';

const Color _muted = Color(0xFF64748B);
const Color _successGreen = Color(0xFF16A34A);
const Color _discardRed = Color(0xFFEF4444);

class ApplicantsListView extends StatelessWidget {
  const ApplicantsListView({
    required this.offerId,
    this.offerTitle,
    super.key,
  });

  final String offerId;
  final String? offerTitle;

  @override
  Widget build(BuildContext context) {
    final JobPostingOfferDetailViewModel viewModel =
        context.watch<JobPostingOfferDetailViewModel>();

    final String subtitle = _offerSubtitle(
      viewModel: viewModel,
      fallback: offerTitle,
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 20, 12),
              child: Row(
                children: <Widget>[
                  Material(
                    color: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(10),
                      child: const SizedBox(
                        width: 32,
                        height: 32,
                        child: Icon(
                          Icons.arrow_back,
                          size: 16,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Candidatos',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 20,
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 12,
                              fontWeight: AppTypography.regular,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody(context, viewModel)),
          ],
        ),
      ),
      bottomNavigationBar: const _ApplicantsBottomNav(),
    );
  }

  Widget _buildBody(
    BuildContext context,
    JobPostingOfferDetailViewModel viewModel,
  ) {
    switch (viewModel.status) {
      case JobPostingOfferDetailStatus.idle:
      case JobPostingOfferDetailStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case JobPostingOfferDetailStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  viewModel.errorMessage ??
                      'No fue posible cargar los candidatos.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => viewModel.load(offerId),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        );
      case JobPostingOfferDetailStatus.loaded:
        if (viewModel.applicants.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Todavía no hay postulantes para esta oferta.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.text, fontSize: 14),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => viewModel.load(offerId),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            itemCount: viewModel.applicants.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (BuildContext context, int index) {
              final Application applicant = viewModel.applicants[index];
              return _ApplicantListCard(
                applicant: applicant,
                onOpen: () async {
                  await context.pushNamed(
                    AppRouteNames.applicantDetail,
                    pathParameters: <String, String>{
                      'offerId': offerId,
                      'applicationId': applicant.id,
                    },
                  );
                  if (context.mounted) {
                    await viewModel.load(offerId);
                  }
                },
              );
            },
          ),
        );
    }
  }
}

class _ApplicantListCard extends StatelessWidget {
  const _ApplicantListCard({
    required this.applicant,
    required this.onOpen,
  });

  final Application applicant;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final String comment = applicant.comment?.trim() ?? '';
    final int rating = applicant.rating ?? 0;

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          applicant.applicantDisplayName,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: <Widget>[
                            ...List<Widget>.generate(5, (int index) {
                              final bool filled = rating > index;
                              return Icon(
                                filled
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 14,
                                color: AppColors.primary,
                              );
                            }),
                            const SizedBox(width: 6),
                            Text(
                              _experienceLabel(applicant),
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _ApplicantStatusChip(
                    status: applicant.status,
                    label: applicant.displayStatusLabel,
                  ),
                ],
              ),
              if (comment.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  '"$comment"',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    fontWeight: AppTypography.regular,
                  ),
                ),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: AppColors.border),
              ),
              const Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Ver perfil completo',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApplicantStatusChip extends StatelessWidget {
  const _ApplicantStatusChip({required this.status, required this.label});

  final String status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground) =
        switch (status.toLowerCase().trim()) {
      'winner' => (
          _successGreen.withValues(alpha: 0.08),
          _successGreen,
        ),
      'finalist' => (
          AppColors.primary.withValues(alpha: 0.08),
          AppColors.primary,
        ),
      'discarded' => (
          _discardRed.withValues(alpha: 0.08),
          _discardRed,
        ),
      _ => (AppColors.border, AppColors.text),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: AppTypography.bold,
        ),
      ),
    );
  }
}

class _ApplicantsBottomNav extends StatelessWidget {
  const _ApplicantsBottomNav();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _NavItem(
                icon: Icons.home_outlined,
                label: 'Inicio',
                onTap: () => context.goNamed(AppRouteNames.home),
              ),
              _NavItem(
                icon: Icons.search,
                label: 'Explorar',
                onTap: () => context.pushNamed(AppRouteNames.jobSearchExplore),
              ),
              _NavItem(
                icon: Icons.add,
                label: 'Publicar',
                prominent: true,
                onTap: () => context.pushNamed(AppRouteNames.jobPostingCreate),
              ),
              const _NavItem(
                icon: Icons.history,
                label: 'Actividad',
                selected: true,
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'Perfil',
                onTap: () => context.pushNamed(AppRouteNames.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.prominent = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool prominent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? AppColors.primary : _muted;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (prominent)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(icon, size: 24, color: AppColors.onPrimary),
              )
            else
              Icon(icon, size: 22, color: color),
            if (!prominent) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: selected
                      ? FontWeight.w600
                      : AppTypography.medium,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _offerSubtitle({
  required JobPostingOfferDetailViewModel viewModel,
  required String? fallback,
}) {
  final String description = (viewModel.offer?.description ?? '').trim();
  if (description.isNotEmpty) {
    return description;
  }
  final String jobType = (viewModel.offer?.jobTypeName ?? '').trim();
  if (jobType.isNotEmpty) {
    return jobType;
  }
  return fallback?.trim() ?? '';
}

String _experienceLabel(Application applicant) {
  final int count = applicant.applicantExperiences.length;
  if (count == 0) {
    return 'Sin experiencias';
  }
  if (count == 1) {
    return '1 experiencia';
  }
  return '$count experiencias';
}
