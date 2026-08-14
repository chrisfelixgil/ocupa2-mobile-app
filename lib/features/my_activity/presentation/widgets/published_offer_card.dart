import 'package:flutter/material.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_spacing.dart';
import 'package:ocupa2/features/my_activity/data/models/published_offer.dart';

class PublishedOfferCard extends StatelessWidget {
  const PublishedOfferCard({
    required this.offer,
    required this.onTap,
    this.isDeactivating = false,
    this.onDelete,
    super.key,
  });

  final PublishedOffer offer;
  final VoidCallback onTap;
  final bool isDeactivating;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(offer.jobTypeName),
        subtitle: Text(
          offer.address,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: offer.isActive
            ? (isDeactivating
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: AppColors.error,
                    tooltip: 'Eliminar oferta',
                    onPressed: onDelete,
                  ))
            : null,
      ),
    );
  }
}
