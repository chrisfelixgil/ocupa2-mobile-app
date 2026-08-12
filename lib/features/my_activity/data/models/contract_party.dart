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
    final Map<String, dynamic> map = requireJsonObject(
      json,
      context: 'Una parte del contrato',
    );

    return ContractParty(
      id: requireString(map, 'id', context: 'Una parte del contrato'),
      nombre: (map['nombre'] as String?)?.trim() ??
          (map['firstName'] as String?)?.trim() ??
          'Usuario',
      email: (map['email'] as String?)?.trim(),
    );
  }
}
