import '../core/api_client.dart';
import '../models/login_response.dart';
import 'google_token_provider.dart';
import 'token_storage.dart';

/// Caso de uso: iniciar y cerrar sesión.
class AuthService {
  AuthService({
    required ApiClient api,
    required TokenStorage storage,
    required GoogleTokenProvider google,
  }) : _api = api,
       _storage = storage,
       _google = google;

  final ApiClient _api;
  final TokenStorage _storage;
  final GoogleTokenProvider _google;

  Future<bool> haySesion() async => await _storage.leerJwt() != null;

  Future<String?> obtenerNombre() => _storage.leerNombre();

  /// Devuelve el nombre del usuario.
  Future<String> loginConGoogle() async {
    final idToken = await _google.obtenerIdToken();
    final sesion = await _autenticarEnBackend(idToken);
    await _storage.guardar(jwt: sesion.jwtToken, nombre: sesion.nombre);
    return sesion.nombre;
  }

  Future<void> cerrarSesion() async {
    await _storage.borrar();
    await _google.cerrarSesion();
  }

  Future<LoginResponse> _autenticarEnBackend(String idToken) async {
    final json = await _api.postJson('/auth/login/google', {
      'id_token': idToken,
    });
    return LoginResponse.fromJson(json);
  }
}
