import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ocupa2/core/constants/storage_keys.dart';
import 'package:ocupa2/core/storage/token_storage.dart';

class SecureStorageService implements TokenStorage {
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> saveToken(String token) async {
    final String normalizedToken = token.trim();

    if (normalizedToken.isEmpty) {
      throw ArgumentError.value(
        token,
        'token',
        'El token no puede estar vacío.',
      );
    }

    await _storage.write(key: StorageKeys.authToken, value: normalizedToken);
  }

  @override
  Future<String?> readToken() async {
    final String? token = await _storage.read(key: StorageKeys.authToken);

    final String? normalizedToken = token?.trim();

    if (normalizedToken == null || normalizedToken.isEmpty) {
      return null;
    }

    return normalizedToken;
  }

  @override
  Future<void> deleteToken() async {
    await _storage.delete(key: StorageKeys.authToken);
  }
}
