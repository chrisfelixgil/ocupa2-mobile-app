import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_typography.dart';
import 'package:ocupa2/features/job_search/presentation/widgets/offer_display.dart';
import 'package:ocupa2/features/my_activity/data/models/application.dart';

const Color _successGreen = Color(0xFF16A34A);
const Color _discardRed = Color(0xFFEF4444);

class MyApplicationCard extends StatelessWidget {
  const MyApplicationCard({
    required this.application,
    this.onTap,
    super.key,
  });

  final Application application;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final String subtitle = application.cardSubtitle;

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: _OfferPhoto(url: application.displayPhotoUrl),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          application.cardTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 2),
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
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: AppColors.border),
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _paymentLabel(application),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                        Text(
                          _appliedLabel(application.createdAt),
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 11,
                            fontWeight: AppTypography.regular,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(
                    status: application.status,
                    label: application.displayStatusLabel,
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

class _OfferPhoto extends StatelessWidget {
  const _OfferPhoto({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return const ColoredBox(
        color: AppColors.border,
        child: Icon(Icons.work_outline, color: AppColors.text),
      );
    }

    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      placeholder: (_, _) => const ColoredBox(color: AppColors.border),
      errorWidget: (_, _, _) => const ColoredBox(
        color: AppColors.border,
        child: Icon(Icons.work_outline, color: AppColors.text),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.label});

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: AppTypography.bold,
        ),
      ),
    );
  }
}

String _paymentLabel(Application application) {
  final offer = application.offer;
  if (offer == null) {
    return 'A convenir';
  }
  return OfferDisplay.paymentLabel(offer);
}

String _appliedLabel(DateTime? date) {
  if (date == null) {
    return 'Aplicado: Sin fecha';
  }

  final Duration elapsed = DateTime.now().difference(date);
  if (elapsed.inMinutes < 60) {
    final int minutes = elapsed.inMinutes < 1 ? 1 : elapsed.inMinutes;
    return minutes == 1 ? 'Aplicado: Hace 1 min' : 'Aplicado: Hace $minutes min';
  }
  if (elapsed.inHours < 24) {
    return elapsed.inHours == 1
        ? 'Aplicado: Hace 1 hora'
        : 'Aplicado: Hace ${elapsed.inHours} horas';
  }
  if (elapsed.inDays == 1) {
    return 'Aplicado: Hace 1 día';
  }

  const List<String> months = <String>[
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];

  return 'Aplicado: ${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
}
