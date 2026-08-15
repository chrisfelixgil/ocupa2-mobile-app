import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocupa2/core/constants/storage_keys.dart';
import 'package:ocupa2/core/storage/secure_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureStorageService', () {
    late FlutterSecureStorage storage;
    late SecureStorageService service;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues(<String, String>{});

      storage = const FlutterSecureStorage();

      service = SecureStorageService(storage: storage);
    });

    test('guarda y lee el token normalizado', () async {
      await service.saveToken('  token-de-prueba  ');

      final String? result = await service.readToken();

      expect(result, 'token-de-prueba');
    });

    test('elimina el token almacenado', () async {
      await service.saveToken('token-de-prueba');

      await service.deleteToken();

      final String? result = await service.readToken();

      expect(result, isNull);
    });

    test('retorna null cuando no existe token', () async {
      final String? result = await service.readToken();

      expect(result, isNull);
    });

    test('no permite guardar un token vacío', () async {
      expect(service.saveToken('   '), throwsArgumentError);
    });

    test('utiliza la clave de almacenamiento esperada', () async {
      await service.saveToken('token-de-prueba');

      final String? storedValue = await storage.read(
        key: StorageKeys.authToken,
      );

      expect(storedValue, 'token-de-prueba');
    });
  });
}
