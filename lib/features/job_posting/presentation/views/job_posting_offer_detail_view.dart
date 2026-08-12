import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/offer.dart';
import '../../data/models/offer_status.dart';
import '../viewmodels/offer_detail_status.dart';
import '../viewmodels/offer_detail_view_model.dart';

class JobPostingOfferDetailView extends StatefulWidget {
  final String offerId;

  const JobPostingOfferDetailView({
    super.key,
    required this.offerId,
  });

  @override
  State<JobPostingOfferDetailView> createState() =>
      _JobPostingOfferDetailViewState();
}

class _JobPostingOfferDetailViewState
    extends State<JobPostingOfferDetailView> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<JobPostingOfferDetailViewModel>()
          .load(widget.offerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel =
        context.watch<JobPostingOfferDetailViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de la oferta'),
      ),
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
        return const Center(
          child: CircularProgressIndicator(),
        );

      case JobPostingOfferDetailStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Error cargando oferta',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  viewModel.errorMessage ??
                      'Error al cargar la oferta',
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
          return const Center(
            child: Text('No se encontró la oferta'),
          );
        }

        return _OfferContent(
          offer: offer,
          viewModel: viewModel,
        );
    }
  }
}

class _OfferContent extends StatelessWidget {
  const _OfferContent({
    required this.offer,
    required this.viewModel,
  });

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

          if (offer.photo != null &&
              offer.photo!.trim().isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                offer.photo!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
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
            offer.jobTypeName.isNotEmpty
                ? offer.jobTypeName
                : offer.jobTypeKey,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          if (offer.jobTypeName.isNotEmpty &&
              offer.jobTypeKey.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              offer.jobTypeKey,
              style: textTheme.bodySmall,
            ),
          ],

          const SizedBox(height: 12),

          // ============================================================
          // DIRECCIÓN
          // ============================================================

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  offer.address,
                  style: textTheme.bodyLarge,
                ),
              ),
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
                avatar: const Icon(
                  Icons.work_outline,
                  size: 18,
                ),
                label: Text(
                  offer.contractType,
                ),
              ),

              Chip(
                avatar: const Icon(
                  Icons.payments_outlined,
                  size: 18,
                ),
                label: Text(
                  '${offer.payment.amount} '
                  '${offer.payment.currency}',
                ),
              ),

              if (offer.deadline != null)
                Chip(
                  avatar: const Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                  ),
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
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            offer.description,
            style: textTheme.bodyLarge,
          ),

          const SizedBox(height: 28),

          // ============================================================
          // UBICACIÓN
          // ============================================================

          Text(
            'Ubicación',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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
                const Icon(
                  Icons.location_on_outlined,
                ),
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
          // ESTADO
          // ============================================================


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
                label: const Text(
                  'Desactivar oferta',
                ),
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
      child: const Icon(
        Icons.work_outline,
        size: 70,
      ),
    );
  }

  String _statusText(OfferStatus status) {
    switch (status) {
      case OfferStatus.active:
        return 'Activa';

      case OfferStatus.inactive:
        return 'Inactiva';

      case OfferStatus.unknown:
        return 'Estado desconocido';
    }
  }

  Future<void> _deactivate(BuildContext context) async {
    final bool ok = await viewModel.deactivate();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Oferta desactivada'
              : 'No se pudo desactivar la oferta',
        ),
      ),
    );
  }
}