import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda la sesión en el almacenamiento cifrado del dispositivo.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _claveJwt = 'jwt_token';
  static const _claveNombre = 'nombre_usuario';

  final FlutterSecureStorage _storage;

  Future<void> guardar({required String jwt, required String nombre}) async {
    await _storage.write(key: _claveJwt, value: jwt);
    await _storage.write(key: _claveNombre, value: nombre);
  }

  Future<String?> leerJwt() => _storage.read(key: _claveJwt);

  Future<String?> leerNombre() => _storage.read(key: _claveNombre);

  Future<void> borrar() async {
    await _storage.delete(key: _claveJwt);
    await _storage.delete(key: _claveNombre);
  }
}
