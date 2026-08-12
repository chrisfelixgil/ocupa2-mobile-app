import 'package:ocupa2/core/network/json_parsing.dart';
import 'package:ocupa2/features/catalog/data/models/custom_field.dart';

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

    final Object? rawCustomFields =
        map['customFields'] ?? map['fields'] ?? map['custom_fields'];

    final String key = requireString(
      map,
      'key',
      context: 'Un tipo de trabajo',
    );

    final String? name = (map['name'] as String?)?.trim();
    final String? label = (map['label'] as String?)?.trim();

    return JobType(
      key: key,
      label: name?.isNotEmpty == true
          ? name!
          : label?.isNotEmpty == true
              ? label!
              : key.replaceAll('_', ' '),
      customFields: (rawCustomFields as List<dynamic>?)
              ?.map(CustomField.fromJson)
              .toList() ??
          const <CustomField>[],
    );
  }
}