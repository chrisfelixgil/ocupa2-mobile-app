import 'package:ocupa2/core/network/json_parsing.dart';

/// Campo personalizado de un tipo de trabajo (ej. "categoría de licencia"
/// para chofer). Definido por el API en GET /job-types.
class CustomField {
  const CustomField({
    required this.key,
    required this.label,
    required this.type,
    required this.required,
    this.options = const <String>[],
  });

  final String key;
  final String label;
  final String type;
  final bool required;
  final List<String> options;

  factory CustomField.fromJson(Object? json) {
    final Map<String, dynamic> map = requireJsonObject(
      json,
      context: 'Un campo personalizado',
    );

    return CustomField(
      key: requireString(map, 'key', context: 'Un campo personalizado'),
      label: requireString(map, 'label', context: 'Un campo personalizado'),
      type: requireString(map, 'type', context: 'Un campo personalizado'),
      required: map['required'] == true,
      options:
          (map['options'] as List<dynamic>?)
              ?.map((Object? option) => option.toString())
              .toList() ??
          const <String>[],
    );
  }
}
