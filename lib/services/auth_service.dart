// ignore_for_file: prefer_initializing_formals

import '../core/api_client.dart';
import '../models/login_response.dart';
import '../models/perfil_usuario.dart';
import 'google_token_provider.dart';
import 'token_storage.dart';

/// Caso de uso: iniciar y cerrar sesión, y consultar quién es la persona.
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

  Future<String?> obtenerFotoUrl() => _storage.leerFotoUrl();

  /// Nombre y foto de la persona con la sesión iniciada (para el perfil).
  Future<PerfilUsuario> obtenerPerfil() async {
    final nombre = await _storage.leerNombre() ?? 'usuario';
    final fotoUrl = await _storage.leerFotoUrl();
    return PerfilUsuario(nombre: nombre, fotoUrl: fotoUrl);
  }

  /// Devuelve el nombre del usuario.
  Future<String> loginConGoogle() async {
    final credencial = await _google.obtenerCredencial();
    final sesion = await _autenticarEnBackend(credencial.idToken);
    await _storage.guardar(
      jwt: sesion.jwtToken,
      nombre: sesion.nombre,
      fotoUrl: credencial.fotoUrl,
    );
    return sesion.nombre;
  }

  Future<void> cerrarSesion() async {
    await _storage.borrar();
    await _google.cerrarSesion();
  }

  ///Autentica el id_token de Google en el backend y devuelve un JWT propio del
  ///backend y el nombre del usuario.
  Future<LoginResponse> _autenticarEnBackend(String idToken) async {
    final json = await _api.postJson('/auth/login/google', {
      'id_token': idToken,
    });
    return LoginResponse.fromJson(json);
  }
}
