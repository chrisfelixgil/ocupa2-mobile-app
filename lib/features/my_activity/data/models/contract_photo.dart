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
    if (json is String && json.trim().isNotEmpty) {
      return ContractPhoto(url: json.trim(), description: '');
    }

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
    if (author == null && (userId != null || (rootName != null && rootName.isNotEmpty))) {
      author = ContractParty(
        id: userId ?? 'unknown-party',
        nombre: rootName ?? '',
      );
    }

    return ContractPhoto(
      url: asText(map['url']) ??
          asText(map['image']) ??
          asText(map['photo']) ??
          asText(map['imageUrl']) ??
          asText(map['src']) ??
          '',
      description: asText(map['description']) ?? asText(map['caption']) ?? '',
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
