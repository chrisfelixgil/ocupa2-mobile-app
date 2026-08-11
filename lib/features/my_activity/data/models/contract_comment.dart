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

    return ContractComment(
      body: requireString(map, 'body', context: 'Un comentario de contrato'),
      by: author,
      createdAt: date,
    );
  }
}
