import 'package:google_sign_in/google_sign_in.dart';

import '../core/api_config.dart';
import '../core/api_exception.dart';

///Abre la ventana de Google para que la persona elija su cuenta y devuelve el id_token
class GoogleTokenProvider {
  GoogleTokenProvider({GoogleSignIn? google})
    : _google =
          google ??
          GoogleSignIn(
            scopes: const ['email', 'profile'],
            serverClientId: ApiConfig.googleServerClientId.isEmpty
                ? null
                : ApiConfig.googleServerClientId,
          );

  final GoogleSignIn _google;

  /// Abre la ventana de Google y devuelve el id_token o un null.
  Future<String> obtenerIdToken() async {
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
    return idToken;
  }

  Future<void> cerrarSesion() async {
    try {
      await _google.signOut();
    } catch (_) {
      // Cerrar sesión en Google no debe impedir cerrar la sesión local.
    }
  }
}
