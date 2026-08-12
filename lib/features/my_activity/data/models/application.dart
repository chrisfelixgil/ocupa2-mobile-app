import 'package:ocupa2/core/network/json_parsing.dart';
import 'package:ocupa2/features/job_search/data/models/offer.dart';

/// Modelo que representa una postulación del usuario a una oferta (GET /me/applications).
class Application {
  const Application({
    required this.id,
    required this.status,
    this.comment,
    this.rating,
    this.createdAt,
    this.offerId,
    this.jobTypeKey,
    this.jobTypeName,
    this.offerTitle,
    this.offerDescription,
    this.offerPhotoUrl,
    this.offerAddress,
    this.offer,
  });

  final String id;
  final String status;
  final String? comment;
  final int? rating;
  final DateTime? createdAt;
  final String? offerId;
  final String? jobTypeKey;
  final String? jobTypeName;
  final String? offerTitle;
  final String? offerDescription;
  final String? offerPhotoUrl;
  final String? offerAddress;
  final Offer? offer;

  /// Título o tipo de empleo a mostrar en la UI.
  String get displayTitle {
    if (offer != null) {
      return offer!.displayJobType;
    }
    if (jobTypeName != null && jobTypeName!.trim().isNotEmpty) {
      return jobTypeName!.trim();
    }
    if (offerTitle != null && offerTitle!.trim().isNotEmpty) {
      return offerTitle!.trim();
    }
    if (jobTypeKey != null && jobTypeKey!.trim().isNotEmpty) {
      return jobTypeKey!.trim();
    }
    return 'Oferta de empleo';
  }

  /// Descripción de la oferta asociada.
  String get displayDescription {
    if (offer != null) {
      return offer!.description;
    }
    return offerDescription?.trim() ?? '';
  }

  /// URL de la imagen de la oferta si está disponible.
  String? get displayPhotoUrl {
    if (offer != null) {
      return offer!.photoUrl;
    }
    return offerPhotoUrl;
  }

  /// Etiqueta en español para el estado.
  String get displayStatusLabel {
    return switch (status.toLowerCase().trim()) {
      'applied' => 'En revisión',
      'finalist' => 'Finalista',
      'winner' => 'Ganador',
      'discarded' => 'Descartado',
      _ => status,
    };
  }

  factory Application.fromJson(Object? json) {
    final Map<String, dynamic> map = requireJsonObject(
      json,
      context: 'Una aplicación',
    );

    Offer? offerObj;
    if (map['offer'] is Map) {
      try {
        offerObj = Offer.fromJson(map['offer']);
      } catch (_) {
        offerObj = null;
      }
    }

    final Object? rawRating = map['rating'];
    final int? ratingVal = rawRating is num ? rawRating.toInt() : null;

    final Object? rawCreatedAt = map['createdAt'] ?? map['date'];
    final DateTime? createdDate = rawCreatedAt is String
        ? DateTime.tryParse(rawCreatedAt.trim())
        : null;

    return Application(
      id: requireString(map, 'id', context: 'Una aplicación'),
      status: requireString(map, 'status', context: 'Una aplicación'),
      comment: (map['comment'] as String?)?.trim(),
      rating: ratingVal,
      createdAt: createdDate,
      offerId: (map['offerId'] as String?)?.trim() ?? offerObj?.id,
      jobTypeKey: (map['jobTypeKey'] as String?)?.trim() ?? offerObj?.jobTypeKey,
      jobTypeName: (map['jobTypeName'] as String?)?.trim() ?? offerObj?.jobTypeName,
      offerTitle: (map['title'] as String?)?.trim() ?? (map['offerTitle'] as String?)?.trim(),
      offerDescription: (map['description'] as String?)?.trim() ?? (map['offerDescription'] as String?)?.trim() ?? offerObj?.description,
      offerPhotoUrl: (map['photo'] as String?) ?? (map['photoUrl'] as String?) ?? (map['offerPhoto'] as String?) ?? offerObj?.photoUrl,
      offerAddress: (map['address'] as String?) ?? (map['offerAddress'] as String?) ?? offerObj?.address,
      offer: offerObj,
    );
  }
}
