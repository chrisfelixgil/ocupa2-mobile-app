import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ocupa2/features/my_activity/data/models/application.dart';
import 'package:ocupa2/features/my_activity/data/models/experience.dart';

import '../../data/models/offer.dart';
import '../../data/models/offer_status.dart';
import '../viewmodels/offer_detail_status.dart';
import '../viewmodels/offer_detail_view_model.dart';

class JobPostingOfferDetailView extends StatefulWidget {
  final String offerId;

  const JobPostingOfferDetailView({super.key, required this.offerId});

  @override
  State<JobPostingOfferDetailView> createState() =>
      _JobPostingOfferDetailViewState();
}

class _JobPostingOfferDetailViewState extends State<JobPostingOfferDetailView> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobPostingOfferDetailViewModel>().load(widget.offerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<JobPostingOfferDetailViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de la oferta')),
      body: _buildBody(context, viewModel),
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Error cargando oferta',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  viewModel.errorMessage ?? 'Error al cargar la oferta',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () {
                    viewModel.load(widget.offerId);
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        );

      case JobPostingOfferDetailStatus.loaded:
        final Offer? offer = viewModel.offer;

        if (offer == null) {
          return const Center(child: Text('No se encontró la oferta'));
        }

        return _OfferContent(offer: offer, viewModel: viewModel);
    }
  }
}

class _OfferContent extends StatelessWidget {
  const _OfferContent({required this.offer, required this.viewModel});

  final Offer offer;
  final JobPostingOfferDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ============================================================
          // FOTO
          // ============================================================
          if (offer.photo != null && offer.photo!.trim().isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                offer.photo!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) {
                  return _buildImagePlaceholder();
                },
              ),
            )
          else
            _buildImagePlaceholder(),

          const SizedBox(height: 20),

          // ============================================================
          // TIPO DE TRABAJO
          // ============================================================
          Text(
            offer.jobTypeName.isNotEmpty ? offer.jobTypeName : offer.jobTypeKey,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          if (offer.jobTypeName.isNotEmpty && offer.jobTypeKey.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(offer.jobTypeKey, style: textTheme.bodySmall),
          ],

          const SizedBox(height: 12),

          // ============================================================
          // DIRECCIÓN
          // ============================================================
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 22),
              const SizedBox(width: 8),
              Expanded(child: Text(offer.address, style: textTheme.bodyLarge)),
            ],
          ),

          const SizedBox(height: 16),

          // ============================================================
          // INFORMACIÓN PRINCIPAL
          // ============================================================
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.work_outline, size: 18),
                label: Text(offer.contractType),
              ),

              Chip(
                avatar: const Icon(Icons.payments_outlined, size: 18),
                label: Text(
                  '${offer.payment.amount} '
                  '${offer.payment.currency}',
                ),
              ),

              if (offer.deadline != null)
                Chip(
                  avatar: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(
                    'Hasta '
                    '${offer.deadline!.day}/'
                    '${offer.deadline!.month}/'
                    '${offer.deadline!.year}',
                  ),
                ),
            ],
          ),

          const SizedBox(height: 28),

          // ============================================================
          // DESCRIPCIÓN
          // ============================================================
          Text(
            'Descripción',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(offer.description, style: textTheme.bodyLarge),

          const SizedBox(height: 28),

          // ============================================================
          // UBICACIÓN
          // ============================================================
          Text(
            'Ubicación',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Latitud: ${offer.location.lat}\n'
                    'Longitud: ${offer.location.lng}',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ============================================================
          // POSTULANTES
          // ============================================================
          Text(
            'Postulantes',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (viewModel.applicants.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Todavía no hay postulantes para esta oferta.'),
            )
          else
            ...viewModel.applicants.map((Application applicant) {
              return _ApplicantCard(
                applicant: applicant,
                isUpdating: viewModel.isUpdatingApplicant,
                onSelectFinalist: () => viewModel.updateApplicantStatus(
                  applicationId: applicant.id,
                  status: 'finalist',
                ),
                onSelectWinner: () => viewModel.updateApplicantStatus(
                  applicationId: applicant.id,
                  status: 'winner',
                ),
                onDiscard: () => viewModel.updateApplicantStatus(
                  applicationId: applicant.id,
                  status: 'discarded',
                ),
              );
            }),

          const SizedBox(height: 28),

          // ============================================================
          // DESACTIVAR
          // ============================================================
          if (offer.status == OfferStatus.active)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await _deactivate(context);
                },
                icon: const Icon(Icons.block),
                label: const Text('Desactivar oferta'),
              ),
            ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade200,
      ),
      child: const Icon(Icons.work_outline, size: 70),
    );
  }

  Future<void> _deactivate(BuildContext context) async {
    final bool ok = await viewModel.deactivate();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Oferta desactivada' : 'No se pudo desactivar la oferta',
        ),
      ),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  const _ApplicantCard({
    required this.applicant,
    required this.isUpdating,
    required this.onSelectFinalist,
    required this.onSelectWinner,
    required this.onDiscard,
  });

  final Application applicant;
  final bool isUpdating;
  final VoidCallback onSelectFinalist;
  final VoidCallback onSelectWinner;
  final VoidCallback onDiscard;

  Future<void> _openCertificateDialog(
    BuildContext context,
    Experience experience,
  ) async {
    final String? imageUrl = experience.certificateImage?.trim();

    if (imageUrl == null || imageUrl.isEmpty) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                icon: const Icon(Icons.close),
              ),
              title: Text(experience.title),
            ),
            body: SafeArea(
              child: InteractiveViewer(
                child: Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder:
                        (
                          BuildContext context,
                          Object error,
                          StackTrace? stackTrace,
                        ) {
                          return const Center(
                            child: Text('No se pudo cargar el certificado'),
                          );
                        },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor = switch (applicant.status.toLowerCase()) {
      'applied' => Colors.orange,
      'finalist' => Colors.blue,
      'winner' => Colors.green,
      'discarded' => Colors.red,
      _ => Colors.grey,
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  applicant.applicantDisplayName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  applicant.displayStatusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            applicant.offerTitle ?? 'Postulación a oferta',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          if ((applicant.comment ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              applicant.comment!,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
          if (applicant.applicantExperiences.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Experiencia registrada',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: applicant.applicantExperiences
                  .where((experience) => experience.title.trim().isNotEmpty)
                  .map((experience) {
                    return ActionChip(
                      avatar: const Icon(Icons.badge_outlined, size: 18),
                      label: Text(experience.title),
                      onPressed:
                          (experience.certificateImage?.trim().isNotEmpty ??
                              false)
                          ? () => _openCertificateDialog(context, experience)
                          : null,
                    );
                  })
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: isUpdating ? null : onSelectFinalist,
                child: const Text('Finalista'),
              ),
              OutlinedButton(
                onPressed: isUpdating ? null : onSelectWinner,
                child: const Text('Ganador'),
              ),
              TextButton(
                onPressed: isUpdating ? null : onDiscard,
                child: const Text('Descartar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
