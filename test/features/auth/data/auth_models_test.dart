import 'package:flutter_test/flutter_test.dart';
import 'package:ocupa2/core/network/api_response.dart';
import 'package:ocupa2/features/auth/data/models/auth_response.dart';
import 'package:ocupa2/features/auth/data/models/change_password_request.dart';
import 'package:ocupa2/features/auth/data/models/forgot_password_request.dart';
import 'package:ocupa2/features/auth/data/models/login_request.dart';
import 'package:ocupa2/features/auth/data/models/message_response.dart';
import 'package:ocupa2/features/auth/data/models/register_request.dart';

void main() {
  group('Modelos de autenticación', () {
    test('convierte una respuesta real de autenticación', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'ok': true,
        'data': <String, dynamic>{
          'token': 'token-de-prueba',
          'tokenType': 'Bearer',
          'user': <String, dynamic>{
            'id': 'usuario-123',
            'email': 'usuario@itla.edu.do',
            'firstName': 'Christian',
            'lastName': 'Gil',
            'nombre': 'Christian Gil',
            'referralMatricula': '20121036',
            'role': 'user',
            'createdAt': '2026-07-16T22:00:36+00:00',
            'lastLoginAt': '2026-07-16T22:01:31+00:00',
            'updatedAt': '2026-07-16T22:00:36+00:00',
          },
        },
      };

      final ApiResponse<AuthResponse> response =
          ApiResponse<AuthResponse>.fromJson(
            json,
            parseData: AuthResponse.fromJson,
          );

      expect(response.ok, isTrue);
      expect(response.data.token, 'token-de-prueba');
      expect(response.data.tokenType, 'Bearer');
      expect(response.data.user.nombre, 'Christian Gil');
      expect(response.data.user.referralMatricula, '20121036');
      expect(response.data.user.updatedAt.year, 2026);
    });

    test('convierte una respuesta de mensaje', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'ok': true,
        'data': <String, dynamic>{'message': 'Clave actualizada.'},
      };

      final ApiResponse<MessageResponse> response =
          ApiResponse<MessageResponse>.fromJson(
            json,
            parseData: MessageResponse.fromJson,
          );

      expect(response.data.message, 'Clave actualizada.');
    });

    test('serializa correctamente RegisterRequest', () {
      const RegisterRequest request = RegisterRequest(
        email: ' usuario@itla.edu.do ',
        firstName: ' Christian ',
        lastName: ' Gil ',
        password: 'clave123',
        referralMatricula: ' 20121036 ',
      );

      expect(request.toJson(), <String, dynamic>{
        'email': 'usuario@itla.edu.do',
        'firstName': 'Christian',
        'lastName': 'Gil',
        'password': 'clave123',
        'referralMatricula': '20121036',
      });
    });

    test('serializa correctamente LoginRequest', () {
      const LoginRequest request = LoginRequest(
        email: ' usuario@itla.edu.do ',
        password: 'clave123',
      );

      expect(request.toJson(), <String, dynamic>{
        'email': 'usuario@itla.edu.do',
        'password': 'clave123',
      });
    });

    test('serializa correctamente ForgotPasswordRequest', () {
      const ForgotPasswordRequest request = ForgotPasswordRequest(
        email: ' usuario@itla.edu.do ',
        referralMatricula: ' 20121036 ',
      );

      expect(request.toJson(), <String, dynamic>{
        'email': 'usuario@itla.edu.do',
        'referralMatricula': '20121036',
      });
    });

    test('serializa correctamente ChangePasswordRequest', () {
      const ChangePasswordRequest request = ChangePasswordRequest(
        password: 'nuevaClave123',
      );

      expect(request.toJson(), <String, dynamic>{'password': 'nuevaClave123'});
    });

    test('rechaza una respuesta exitosa sin data', () {
      final Map<String, dynamic> json = <String, dynamic>{'ok': true};

      expect(() {
        ApiResponse<MessageResponse>.fromJson(
          json,
          parseData: MessageResponse.fromJson,
        );
      }, throwsFormatException);
    });
  });
}
