import 'package:google_sign_in/google_sign_in.dart';

import '../core/api_config.dart';
import '../core/api_exception.dart';
import '../models/credencial_google.dart';

///Abre la ventana de Google para que la persona elija su cuenta y devuelve
///el id_token junto con la foto de la cuenta.
class GoogleTokenProvider {
  GoogleTokenProvider();

  final GoogleSignIn _google = GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: ApiConfig.googleServerClientId.isEmpty
        ? null
        : ApiConfig.googleServerClientId,
  );

  /// Abre la ventana de Google y devuelve el id_token y la foto de la cuenta.
  /// Lanza [ApiException] si la persona cancela o si Google no da el token.
  Future<CredencialGoogle> obtenerCredencial() async {
    final cuenta = await _google.signIn();
    if (cuenta == null) {
      throw const ApiException('Inicio de sesión cancelado.');
    }

    final idToken = (await cuenta.authentication).idToken;
    if (idToken == null) {
      throw const ApiException(
        'Google no devolvió el token. Revisa el Client ID del servidor.',
      );
    }
    return CredencialGoogle(idToken: idToken, fotoUrl: cuenta.photoUrl);
  }

  /// Cierra la sesión de Google para que la proxima vez que se abra la ventana
  ///  de Google, la persona tenga que elegir su cuenta y no se inicie sesión automáticamente.
  Future<void> cerrarSesion() async {
    try {
      await _google.signOut();
    } catch (_) {}
  }
}
