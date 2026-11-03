/// Valores de configuración del backend.
/// Se inyectan al ejecutar con --dart-define, así no quedan en el código.
abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment('API_URL');

  /// Client ID de tipo "Web". Debe ser el mismo GOOGLE_CLIENT_ID del backend.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  static const Duration timeout = Duration(seconds: 30);
}
