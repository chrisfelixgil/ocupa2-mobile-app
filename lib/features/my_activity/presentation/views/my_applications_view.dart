import 'package:flutter/material.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_spacing.dart';
import 'package:ocupa2/features/my_activity/data/models/application.dart';
import 'package:ocupa2/features/my_activity/presentation/viewmodels/applications_status.dart';
import 'package:ocupa2/features/my_activity/presentation/viewmodels/applications_view_model.dart';
import 'package:provider/provider.dart';

class MyApplicationsView extends StatefulWidget {
  const MyApplicationsView({super.key});

  @override
  State<MyApplicationsView> createState() => _MyApplicationsViewState();
}

class _MyApplicationsViewState extends State<MyApplicationsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ApplicationsViewModel>().load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ApplicationsViewModel viewModel =
        context.watch<ApplicationsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis aplicaciones'),
      ),
      body: switch (viewModel.status) {
        ApplicationsStatus.idle || ApplicationsStatus.loading =>
          const Center(child: CircularProgressIndicator()),
        ApplicationsStatus.error => _ErrorState(
            message: viewModel.errorMessage,
            onRetry: viewModel.load,
          ),
        ApplicationsStatus.success => _ApplicationsList(
            applications: viewModel.applications,
          ),
      },
    );
  }
}

class _ApplicationsList extends StatelessWidget {
  const _ApplicationsList({required this.applications});

  final List<Application> applications;

  @override
  Widget build(BuildContext context) {
    if (applications.isEmpty) {
      return const _EmptyState();
    }

    return RefreshIndicator(
      onRefresh: context.read<ApplicationsViewModel>().load,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: applications.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (BuildContext context, int index) {
          final Application application = applications[index];
          return _ApplicationCard(application: application);
        },
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.application});

  final Application application;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _OfferAvatar(photoUrl: application.displayPhotoUrl),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        application.displayTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (application.displayDescription.isNotEmpty) ...<Widget>[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          application.displayDescription,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
                _StatusChip(
                  status: application.status,
                  label: application.displayStatusLabel,
                ),
              ],
            ),
            if (application.rating != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: <Widget>[
                  const Text('Calificación del contratante: ',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  ...List<Widget>.generate(5, (int index) {
                    return Icon(
                      index < application.rating!
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 16,
                      color: Colors.amber,
                    );
                  }),
                ],
              ),
            ],
            if (application.comment != null &&
                application.comment!.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs + 2),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Mi propuesta: "${application.comment}"',
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OfferAvatar extends StatelessWidget {
  const _OfferAvatar({this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Image.network(
            photoUrl!,
            fit: BoxFit.cover,
            loadingBuilder:
                (BuildContext _, Widget child, ImageChunkEvent? progress) {
              if (progress == null) {
                return child;
              }
              return const CircleAvatar(
                backgroundColor: AppColors.cream,
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
            errorBuilder:
                (BuildContext _, Object error, StackTrace? stackTrace) {
              return const CircleAvatar(
                backgroundColor: AppColors.cream,
                child: Icon(Icons.work_outline_rounded, color: AppColors.navy),
              );
            },
          ),
        ),
      );
    }

    return const CircleAvatar(
      backgroundColor: AppColors.cream,
      child: Icon(Icons.work_outline_rounded, color: AppColors.navy),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.label});

  final String status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (Color bgColor, Color fgColor, IconData icon) =
        switch (status.toLowerCase().trim()) {
      'winner' => (
          AppColors.successSurface,
          AppColors.success,
          Icons.emoji_events_outlined
        ),
      'finalist' => (
          const Color(0xFFFFF8E1),
          const Color(0xFFF57F17),
          Icons.star_outline_rounded
        ),
      'discarded' => (
          AppColors.errorSurface,
          AppColors.error,
          Icons.cancel_outlined
        ),
      _ => (
          const Color(0xFFE3F2FD),
          const Color(0xFF1976D2),
          Icons.schedule_rounded
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: fgColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fgColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: AppColors.terracotta,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Aún no has aplicado a ninguna oferta.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Explora las ofertas disponibles en la pestaña de empleos y postula a las que se adapten a ti.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message ?? 'No fue posible cargar tus aplicaciones.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
