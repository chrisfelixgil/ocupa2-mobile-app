import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class Environment {
  static const String _apiBaseUrlKey = 'API_BASE_URL';

  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
    _validate();
  }

  static String get apiBaseUrl {
    final String value = dotenv.get(_apiBaseUrlKey).trim();

    if (value.endsWith('/')) {
      return value.substring(0, value.length - 1);
    }

    return value;
  }

  static void _validate() {
    final String? value = dotenv.maybeGet(_apiBaseUrlKey)?.trim();

    if (value == null || value.isEmpty) {
      throw StateError(
        'La variable API_BASE_URL no está definida en el archivo .env.',
      );
    }

    final Uri? uri = Uri.tryParse(value);

    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw StateError(
        'API_BASE_URL debe contener una URL HTTP o HTTPS válida.',
      );
    }
  }
}
