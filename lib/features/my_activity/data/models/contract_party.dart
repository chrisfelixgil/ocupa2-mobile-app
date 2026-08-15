import 'package:ocupa2/core/network/json_parsing.dart';

class ContractParty {
  const ContractParty({
    required this.id,
    required this.nombre,
    this.email,
  });

  final String id;
  final String nombre;
  final String? email;

  factory ContractParty.fromJson(Object? json) {
    if (json is String && json.trim().isNotEmpty) {
      return ContractParty(id: 'unknown-party', nombre: json.trim());
    }

    final Map<String, dynamic> map = requireJsonObject(
      json,
      context: 'Una parte del contrato',
    );

    String? asText(Object? value) {
      if (value == null) return null;
      if (value is String) return value.trim();
      if (value is num || value is bool) return value.toString().trim();
      return value.toString().trim();
    }

    final Map<String, dynamic>? nestedUser =
        map['user'] is Map ? Map<String, dynamic>.from(map['user'] as Map) : null;

    final String resolvedId = asText(map['id']) ??
        asText(map['_id']) ??
        asText(map['userId']) ??
        asText(map['contractorId']) ??
        asText(map['employeeId']) ??
        asText(nestedUser?['id']) ??
        asText(nestedUser?['_id']) ??
        'unknown-party';

    final String? explicitName = asText(map['nombre']) ??
        asText(map['name']) ??
        asText(map['fullName']) ??
        asText(nestedUser?['nombre']) ??
        asText(nestedUser?['name']) ??
        asText(nestedUser?['fullName']);

    final String? firstName = asText(map['firstName']) ?? asText(nestedUser?['firstName']);
    final String? lastName = asText(map['lastName']) ?? asText(nestedUser?['lastName']);
    final String resolvedName =
        explicitName != null && explicitName.isNotEmpty
            ? explicitName
            : (firstName != null || lastName != null)
                ? <String?>[firstName, lastName]
                    .where((String? value) => value != null && value.isNotEmpty)
                    .join(' ')
                : '';

    return ContractParty(
      id: resolvedId,
      nombre: resolvedName.isNotEmpty ? resolvedName : 'Usuario',
      email: asText(map['email']) ?? asText(nestedUser?['email']),
    );
  }
}
