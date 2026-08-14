import 'package:ocupa2/core/network/json_parsing.dart';
import 'package:ocupa2/features/my_activity/data/models/contract_party.dart';

class ContractPhoto {
  const ContractPhoto({
    required this.url,
    required this.description,
    this.by,
    this.createdAt,
  });

  final String url;
  final String description;
  final ContractParty? by;
  final DateTime? createdAt;

  factory ContractPhoto.fromJson(Object? json) {
    final Map<String, dynamic> map = requireJsonObject(
      json,
      context: 'Una foto de contrato',
    );

    String? asText(Object? value) {
      if (value == null) return null;
      if (value is String) return value.trim();
      if (value is num || value is bool) return value.toString().trim();
      return value.toString().trim();
    }

    ContractParty? author;
    final Object? rawAuthor = map['by'] ?? map['author'] ?? map['user'];
    if (rawAuthor != null) {
      try {
        author = ContractParty.fromJson(rawAuthor);
      } catch (_) {
        author = null;
      }
    }

    final Object? rawCreatedAt = map['createdAt'] ?? map['date'] ?? map['timestamp'];
    final DateTime? date = rawCreatedAt is String
        ? DateTime.tryParse(rawCreatedAt.trim())
        : null;

    return ContractPhoto(
      url: asText(map['url']) ?? asText(map['image']) ?? asText(map['photo']) ?? '',
      description: asText(map['description']) ?? asText(map['caption']) ?? '',
      by: author,
      createdAt: date,
    );
  }
}
