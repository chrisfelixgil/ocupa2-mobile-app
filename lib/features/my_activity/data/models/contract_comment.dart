import 'package:ocupa2/core/network/json_parsing.dart';
import 'package:ocupa2/features/my_activity/data/models/contract_party.dart';

class ContractComment {
  const ContractComment({
    required this.body,
    this.by,
    this.createdAt,
  });

  final String body;
  final ContractParty? by;
  final DateTime? createdAt;

  factory ContractComment.fromJson(Object? json) {
    final Map<String, dynamic> map = requireJsonObject(
      json,
      context: 'Un comentario de contrato',
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

    return ContractComment(
      body: asText(map['body']) ?? asText(map['message']) ?? 'Comentario',
      by: author,
      createdAt: date,
    );
  }
}
