import 'package:ocupa2/core/network/json_parsing.dart';
import 'package:ocupa2/features/job_search/data/models/offer.dart';

import 'experience.dart';

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
    this.applicantFirstName,
    this.applicantLastName,
    this.applicantExperiences = const <Experience>[],
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
  final String? applicantFirstName;
  final String? applicantLastName;
  final List<Experience> applicantExperiences;

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

  String get applicantDisplayName {
    final String firstName = applicantFirstName?.trim() ?? '';
    final String lastName = applicantLastName?.trim() ?? '';

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    }

    if (firstName.isNotEmpty) {
      return firstName;
    }

    if (lastName.isNotEmpty) {
      return lastName;
    }

    return 'Postulante';
  }

  Application copyWith({
    String? status,
    String? comment,
    int? rating,
    String? applicantFirstName,
    String? applicantLastName,
    List<Experience>? applicantExperiences,
  }) {
    return Application(
      id: id,
      status: status ?? this.status,
      comment: comment ?? this.comment,
      rating: rating ?? this.rating,
      createdAt: createdAt,
      offerId: offerId,
      jobTypeKey: jobTypeKey,
      jobTypeName: jobTypeName,
      offerTitle: offerTitle,
      offerDescription: offerDescription,
      offerPhotoUrl: offerPhotoUrl,
      offerAddress: offerAddress,
      offer: offer,
      applicantFirstName: applicantFirstName ?? this.applicantFirstName,
      applicantLastName: applicantLastName ?? this.applicantLastName,
      applicantExperiences: applicantExperiences ?? this.applicantExperiences,
    );
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

    final Object? rawRating = map['rating'] ?? map['score'];
    final int? ratingVal = rawRating is num ? rawRating.toInt() : null;

    final Object? rawCreatedAt = map['createdAt'] ?? map['date'];
    final DateTime? createdDate = rawCreatedAt is String
        ? DateTime.tryParse(rawCreatedAt.trim())
        : null;

    final Object? rawUser = map['user'] ??
        map['applicant'] ??
        map['candidate'] ??
        map['applicantUser'];
    final Map<String, dynamic>? userMap = _asMap(rawUser);
    final Map<String, dynamic>? profileMap = _asMap(userMap?['profile']);

    final String? firstName = _asText(map['firstName']) ??
        _asText(userMap?['firstName']) ??
        _asText(profileMap?['firstName']);
    final String? lastName = _asText(map['lastName']) ??
        _asText(userMap?['lastName']) ??
        _asText(profileMap?['lastName']) ??
        _asText(userMap?['surname']) ??
        _asText(map['apellido']) ??
        _asText(userMap?['apellido']);
    final String? fullName = _asText(map['nombre']) ??
        _asText(userMap?['nombre']) ??
        _asText(map['fullName']) ??
        _asText(map['applicantName']) ??
        _asText(userMap?['fullName']) ??
        _asText(userMap?['name']) ??
        _asText(map['applicant']);

    final Object? rawExperiences = map['experiences'] ??
        map['experience'] ??
        (userMap != null ? userMap['experiences'] : null) ??
        (userMap != null ? userMap['experience'] : null);
    final List<Experience> parsedExperiences = <Experience>[];
    if (rawExperiences is List) {
      for (final Object? entry in rawExperiences) {
        try {
          if (entry is Map<String, dynamic>) {
            parsedExperiences.add(Experience.fromJson(entry));
          } else if (entry is Map) {
            parsedExperiences.add(
              Experience.fromJson(Map<String, dynamic>.from(entry)),
            );
          }
        } catch (_) {
          // Una experiencia mal formada no debe tumbar toda la aplicación.
        }
      }
    }

    final String applicationStatus = (map['status'] as String?) ??
        (map['applicationStatus'] as String?) ??
        (map['state'] as String?) ??
        'applied';

    final String? applicationId = _asId(map['id']) ?? _asId(map['_id']);
    if (applicationId == null) {
      throw const FormatException(
        'Una aplicación no contiene un valor válido para "id".',
      );
    }

    return Application(
      id: applicationId,
      status: applicationStatus.trim().isNotEmpty ? applicationStatus.trim() : 'applied',
      comment: (map['comment'] as String?)?.trim() ?? (map['message'] as String?)?.trim(),
      rating: ratingVal,
      createdAt: createdDate,
      offerId: _readOfferId(map) ?? offerObj?.id,
      jobTypeKey: (map['jobTypeKey'] as String?)?.trim() ?? offerObj?.jobTypeKey,
      jobTypeName: (map['jobTypeName'] as String?)?.trim() ?? offerObj?.jobTypeName,
      offerTitle: (map['title'] as String?)?.trim() ?? (map['offerTitle'] as String?)?.trim(),
      offerDescription: (map['description'] as String?)?.trim() ?? (map['offerDescription'] as String?)?.trim() ?? offerObj?.description,
      offerPhotoUrl: (map['photo'] as String?) ?? (map['photoUrl'] as String?) ?? (map['offerPhoto'] as String?) ?? offerObj?.photoUrl,
      offerAddress: (map['address'] as String?) ?? (map['offerAddress'] as String?) ?? offerObj?.address,
      offer: offerObj,
      applicantFirstName: firstName ?? (lastName == null ? fullName : null),
      applicantLastName: lastName,
      applicantExperiences: parsedExperiences,
    );
  }

  static Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  static String? _asText(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is String) {
      final String trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    return null;
  }

  static String? _readOfferId(Map<String, dynamic> map) {
    return _asId(map['offerId']) ??
        _asId(map['offer_id']) ??
        _asId(map['offer']);
  }

  static String? _asId(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is String) {
      final String trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    if (value is num) {
      return value.toString();
    }

    if (value is Map) {
      return _asId(value['id'] ?? value['_id']);
    }

    return null;
  }
}
