import 'package:ocupa2/core/network/json_parsing.dart';
import 'package:ocupa2/features/catalog/data/models/custom_field.dart';

/// Tipo de trabajo del catálogo (GET /job-types). El profesor puede agregar
/// más tipos desde el admin, por eso no están fijos en la app.
class JobType {
  const JobType({
    required this.key,
    required this.label,
    this.customFields = const <CustomField>[],
  });

  final String key;
  final String label;
  final List<CustomField> customFields;

  factory JobType.fromJson(Object? json) {
    final Map<String, dynamic> map = requireJsonObject(
      json,
      context: 'Un tipo de trabajo',
    );

    // NOTA: el nombre del campo de campos personalizados no se confirmó
    // contra un ejemplo real del API (el Swagger no mostraba el JSON de
    // respuesta completo). Se intentan las claves más probables.
    final Object? rawCustomFields =
        map['customFields'] ?? map['fields'] ?? map['custom_fields'];

    return JobType(
      key: requireString(map, 'key', context: 'Un tipo de trabajo'),
      label: (map['label'] as String?)?.trim().isNotEmpty == true
          ? (map['label'] as String).trim()
          : requireString(map, 'key', context: 'Un tipo de trabajo'),
      customFields: (rawCustomFields as List<dynamic>?)
              ?.map(CustomField.fromJson)
              .toList() ??
          const <CustomField>[],
    );
  }
}
