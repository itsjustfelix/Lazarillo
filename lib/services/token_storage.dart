import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda la sesión en el almacenamiento cifrado del dispositivo.
class TokenStorage {
  TokenStorage();

  static const _claveJwt = 'jwt_token';
  static const _claveNombre = 'nombre_usuario';
  static const _claveFoto = 'foto_usuario';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Guarda el JWT, el nombre y la foto del usuario en el almacenamiento
  /// seguro (Keychain en iOS, Keystore en Android) para que puedan ser leídos
  /// posteriormente y mantener la sesión del usuario.
  /// Si [fotoUrl] viene vacía se borra la anterior, para no mostrar la foto
  /// de otra cuenta.
  Future<void> guardar({
    required String jwt,
    required String nombre,
    String? fotoUrl,
  }) async {
    await _storage.write(key: _claveJwt, value: jwt);
    await _storage.write(key: _claveNombre, value: nombre);
    if (fotoUrl == null || fotoUrl.isEmpty) {
      await _storage.delete(key: _claveFoto);
    } else {
      await _storage.write(key: _claveFoto, value: fotoUrl);
    }
  }

  /// Lee el JWT del almacenamiento seguro.
  ///  Retorna null si no hay JWT guardado.
  Future<String?> leerJwt() => _storage.read(key: _claveJwt);

  Future<String?> leerNombre() => _storage.read(key: _claveNombre);

  /// Retorna null si la cuenta no tiene foto o la sesión es anterior a que
  /// se guardara.
  Future<String?> leerFotoUrl() => _storage.read(key: _claveFoto);

  /// Borra el JWT, el nombre y la foto del usuario del almacenamiento seguro
  /// cuando el usuario cierra la sesión.
  Future<void> borrar() async {
    await _storage.delete(key: _claveJwt);
    await _storage.delete(key: _claveNombre);
    await _storage.delete(key: _claveFoto);
  }
}
