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

    ContractParty? author;
    if (map['by'] != null) {
      try {
        author = ContractParty.fromJson(map['by']);
      } catch (_) {
        author = null;
      }
    }

    final Object? rawCreatedAt = map['createdAt'];
    final DateTime? date = rawCreatedAt is String
        ? DateTime.tryParse(rawCreatedAt.trim())
        : null;

    return ContractPhoto(
      url: requireString(map, 'url', context: 'Una foto de contrato'),
      description: (map['description'] as String?)?.trim() ?? '',
      by: author,
      createdAt: date,
    );
  }
}
