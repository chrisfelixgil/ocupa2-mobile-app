import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/router/app_routes.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_spacing.dart';
import 'package:ocupa2/app/theme/app_typography.dart';
import 'package:ocupa2/features/job_search/data/models/offer.dart';
import 'package:ocupa2/features/job_search/presentation/viewmodels/offer_detail_status.dart';
import 'package:ocupa2/features/job_search/presentation/viewmodels/offer_detail_view_model.dart';
import 'package:ocupa2/features/job_search/presentation/widgets/application_sent_dialog.dart';
import 'package:ocupa2/features/job_search/presentation/widgets/apply_offer_sheet.dart';
import 'package:ocupa2/features/job_search/presentation/widgets/offer_display.dart';
import 'package:provider/provider.dart';

const Color _payGreen = Color(0xFF16A34A);
const Color _payGreenSoft = Color(0xFFF0FDF4);
const Color _payGreenBorder = Color(0xFFDCFCE7);

class OfferDetailView extends StatelessWidget {
  const OfferDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final OfferDetailViewModel viewModel = context.watch<OfferDetailViewModel>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: _buildBody(context, viewModel),
    );
  }

  Widget _buildBody(BuildContext context, OfferDetailViewModel viewModel) {
    return switch (viewModel.status) {
      OfferDetailStatus.idle || OfferDetailStatus.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      OfferDetailStatus.error => SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(viewModel.errorMessage ?? 'Ocurrió un error.'),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton(
                  onPressed: viewModel.load,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
      OfferDetailStatus.loaded => _OfferDetailContent(
        offer: viewModel.offer!,
        viewModel: viewModel,
      ),
    };
  }
}

class _OfferDetailContent extends StatelessWidget {
  const _OfferDetailContent({required this.offer, required this.viewModel});

  final Offer offer;
  final OfferDetailViewModel viewModel;

  Future<void> _openApplySheet(BuildContext context) async {
    final bool submitted = await showApplyOfferSheet(
      context: context,
      offer: offer,
      viewModel: viewModel,
    );

    if (!submitted || !context.mounted) {
      return;
    }

    final ApplicationSentAction action = await showApplicationSentDialog(
      context,
    );

    if (!context.mounted) {
      return;
    }

    final GoRouter router = GoRouter.of(context);
    Navigator.of(context).pop(true);

    if (action == ApplicationSentAction.viewApplications) {
      router.pushNamed(AppRouteNames.activityHub);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? deadline = OfferDisplay.deadlineLabel(offer.deadline);

    return Column(
      children: <Widget>[
        Expanded(
          child: CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(child: _HeroBanner(photoUrl: offer.photoUrl)),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(<Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          offer.displayJobType,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: AppTypography.medium,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      offer.description,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 22,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _InfoChip(
                          icon: Icons.calendar_today_outlined,
                          label: OfferDisplay.contractLabel(offer.contractType),
                        ),
                        _InfoChip(
                          icon: Icons.location_on_outlined,
                          label: offer.address,
                        ),
                        if (deadline != null)
                          _InfoChip(
                            icon: Icons.event_outlined,
                            label: deadline,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _payGreenSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _payGreenBorder),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text(
                                  'Pago ofrecido',
                                  style: TextStyle(
                                    color: AppColors.text,
                                    fontSize: 12,
                                    fontWeight: AppTypography.regular,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  OfferDisplay.paymentLabel(offer),
                                  style: const TextStyle(
                                    color: _payGreen,
                                    fontSize: 24,
                                    fontWeight: AppTypography.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _payGreenBorder,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              OfferDisplay.paymentFrequency(offer.contractType),
                              style: const TextStyle(
                                color: _payGreen,
                                fontSize: 11,
                                fontWeight: AppTypography.medium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Descripción',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: AppTypography.medium,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      offer.description,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        height: 1.5,
                        fontWeight: AppTypography.regular,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
        ),
        DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: FilledButton(
                onPressed: viewModel.isSubmittingApplication
                    ? null
                    : () => _openApplySheet(context),
                child: const Text('Aplicar a esta oferta'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (photoUrl == null || photoUrl!.isEmpty)
            const ColoredBox(color: AppColors.border)
          else
            CachedNetworkImage(
              imageUrl: photoUrl!,
              fit: BoxFit.cover,
              placeholder: (_, _) {
                return const ColoredBox(color: AppColors.border);
              },
              errorWidget: (_, _, _) {
                return const ColoredBox(
                  color: AppColors.border,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.text,
                    size: 40,
                  ),
                );
              },
            ),
          const ColoredBox(color: Color(0x33000000)),
          Positioned(
            left: 16,
            top: MediaQuery.paddingOf(context).top + 8,
            child: Material(
              color: const Color(0x61000000),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).pop(),
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(
                    Icons.arrow_back,
                    color: AppColors.onPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: AppColors.text),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: AppTypography.regular,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
