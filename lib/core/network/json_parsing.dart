Map<String, dynamic> requireJsonObject(
  Object? value, {
  required String context,
}) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map((Object? key, Object? item) {
      return MapEntry<String, dynamic>(key.toString(), item);
    });
  }

  throw FormatException('$context debe ser un objeto JSON.');
}

String requireString(
  Map<String, dynamic> json,
  String key, {
  required String context,
}) {
  final Object? value = json[key];

  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$context no contiene un valor válido para "$key".');
  }

  return value.trim();
}

bool requireBool(
  Map<String, dynamic> json,
  String key, {
  required String context,
}) {
  final Object? value = json[key];

  if (value is! bool) {
    throw FormatException(
      '$context no contiene un valor booleano válido para "$key".',
    );
  }

  return value;
}

DateTime requireDateTime(
  Map<String, dynamic> json,
  String key, {
  required String context,
}) {
  final String value = requireString(json, key, context: context);

  final DateTime? date = DateTime.tryParse(value);

  if (date == null) {
    throw FormatException('$context no contiene una fecha válida para "$key".');
  }

  return date;
}
