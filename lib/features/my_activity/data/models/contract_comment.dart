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
    if (json is String && json.trim().isNotEmpty) {
      return ContractComment(body: json.trim());
    }

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
    final Object? rawAuthor =
        map['by'] ?? map['author'] ?? map['user'] ?? map['createdBy'] ?? map['from'];
    if (rawAuthor is String && rawAuthor.trim().isNotEmpty) {
      author = ContractParty(id: rawAuthor.trim(), nombre: rawAuthor.trim());
    } else if (rawAuthor is num) {
      author = ContractParty(id: rawAuthor.toString(), nombre: '');
    } else if (rawAuthor != null) {
      try {
        author = ContractParty.fromJson(rawAuthor);
      } catch (_) {
        author = null;
      }
    }

    final String? userId = asText(map['userId']) ??
        asText(map['authorId']) ??
        asText(map['createdById']);
    final String? rootName = asText(map['nombre']) ?? asText(map['name']);
    final String? firstName = asText(map['firstName']);
    final String? lastName = asText(map['lastName']);
    final String composedName = <String?>[firstName, lastName]
        .where((String? value) => value != null && value.isNotEmpty)
        .join(' ');
    final String resolvedName = (rootName != null && rootName.isNotEmpty)
        ? rootName
        : composedName;

    if (author == null && (userId != null || resolvedName.isNotEmpty)) {
      author = ContractParty(
        id: userId ?? 'unknown-party',
        nombre: resolvedName,
      );
    } else if (author != null &&
        (author.nombre.isEmpty || author.nombre == 'Usuario') &&
        resolvedName.isNotEmpty) {
      author = ContractParty(
        id: author.id,
        nombre: resolvedName,
        email: author.email,
      );
    }

    return ContractComment(
      body: asText(map['body']) ?? asText(map['message']) ?? asText(map['text']) ?? 'Comentario',
      by: author,
      createdAt: _parseDate(map['createdAt'] ?? map['date'] ?? map['timestamp']),
    );
  }
}

DateTime? _parseDate(Object? raw) {
  if (raw is DateTime) return raw;
  if (raw is int) {
    if (raw > 9999999999) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    return DateTime.fromMillisecondsSinceEpoch(raw * 1000);
  }
  if (raw is String) return DateTime.tryParse(raw.trim());
  return null;
}
