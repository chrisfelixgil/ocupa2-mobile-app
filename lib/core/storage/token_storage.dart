abstract interface class TokenStorage {
  Future<void> saveToken(String token);

  Future<String?> readToken();

  Future<void> deleteToken();
}
