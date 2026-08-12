import 'package:flutter/material.dart';

import '../../data/models/offer.dart';
import '../../data/models/offer_status.dart';

class MyOfferCard extends StatelessWidget {
  final Offer offer;
  final bool isDeactivating;
  final VoidCallback onTap;
  final VoidCallback? onDeactivate;

  const MyOfferCard({
    super.key,
    required this.offer,
    required this.onTap,
    this.isDeactivating = false,
    this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = offer.status == OfferStatus.active;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: onTap,
        title: Text(offer.jobTypeName),
        subtitle: Text(
          offer.address,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: isActive
            ? (isDeactivating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: onDeactivate,
                    child: const Text('Desactivar'),
                  ))
            : (offer.photo != null && offer.photo!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      offer.photo!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.image_not_supported);
                      },
                    ),
                  )
                : const Icon(Icons.image)),
      ),
    );
  }
}