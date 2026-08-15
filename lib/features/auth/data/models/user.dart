import 'package:ocupa2/core/network/json_parsing.dart';

class User {
  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.nombre,
    required this.profileCompleted,
    required this.referralMatricula,
    required this.role,
    required this.createdAt,
    required this.lastLoginAt,
    this.cedula,
    this.gender,
    this.birthDate,
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String nombre;
  final String? cedula;
  final String? gender;
  final DateTime? birthDate;
  final bool profileCompleted;
  final String referralMatricula;
  final String role;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  factory User.fromJson(Object? json) {
    final Map<String, dynamic> data = requireJsonObject(
      json,
      context: 'El usuario',
    );

    return User(
      id: requireString(data, 'id', context: 'El usuario'),
      email: requireString(data, 'email', context: 'El usuario'),
      firstName: requireString(data, 'firstName', context: 'El usuario'),
      lastName: requireString(data, 'lastName', context: 'El usuario'),
      nombre: requireString(data, 'nombre', context: 'El usuario'),
      cedula: _optionalString(data, 'cedula', context: 'El usuario'),
      gender: _optionalString(data, 'gender', context: 'El usuario'),
      birthDate: _optionalDateTime(data, 'birthDate', context: 'El usuario'),
      profileCompleted: data['profileCompleted'] == true,
      referralMatricula: requireString(
        data,
        'referralMatricula',
        context: 'El usuario',
      ),
      role: requireString(data, 'role', context: 'El usuario'),
      createdAt: requireDateTime(data, 'createdAt', context: 'El usuario'),
      lastLoginAt: requireDateTime(data, 'lastLoginAt', context: 'El usuario'),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'nombre': nombre,
      'cedula': cedula,
      'gender': gender,
      'birthDate': birthDate?.toIso8601String(),
      'profileCompleted': profileCompleted,
      'referralMatricula': referralMatricula,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
    };
  }
}

String? _optionalString(
  Map<String, dynamic> json,
  String key, {
  required String context,
}) {
  final Object? value = json[key];

  if (value == null) {
    return null;
  }

  if (value is! String) {
    throw FormatException('$context no contiene un valor válido para "$key".');
  }

  final String normalizedValue = value.trim();

  return normalizedValue.isEmpty ? null : normalizedValue;
}

DateTime? _optionalDateTime(
  Map<String, dynamic> json,
  String key, {
  required String context,
}) {
  final String? value = _optionalString(json, key, context: context);

  if (value == null) {
    return null;
  }

  final DateTime? date = DateTime.tryParse(value);

  if (date == null) {
    throw FormatException('$context no contiene una fecha válida para "$key".');
  }

  return date;
}
