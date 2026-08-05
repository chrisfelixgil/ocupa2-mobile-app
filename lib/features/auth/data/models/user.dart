import 'package:ocupa2/core/network/json_parsing.dart';

class User {
  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.nombre,
    required this.referralMatricula,
    required this.role,
    required this.createdAt,
    required this.lastLoginAt,
    required this.updatedAt,
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String nombre;
  final String referralMatricula;
  final String role;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final DateTime updatedAt;

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
      referralMatricula: requireString(
        data,
        'referralMatricula',
        context: 'El usuario',
      ),
      role: requireString(data, 'role', context: 'El usuario'),
      createdAt: requireDateTime(data, 'createdAt', context: 'El usuario'),
      lastLoginAt: requireDateTime(data, 'lastLoginAt', context: 'El usuario'),
      updatedAt: requireDateTime(data, 'updatedAt', context: 'El usuario'),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'nombre': nombre,
      'referralMatricula': referralMatricula,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
