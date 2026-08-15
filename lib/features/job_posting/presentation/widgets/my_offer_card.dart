import 'package:flutter/material.dart';

import '../../data/models/offer.dart';

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
        trailing: isDeactivating
    ? const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
    : SizedBox(
        width: 110,
        child: TextButton.icon(
          onPressed: onDeactivate,
          icon: const Icon(Icons.delete_outline, size: 18),
          label: const Text('Eliminar'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(0, 36),
          ),
        ),
      ),
      ),
    );
  }
}