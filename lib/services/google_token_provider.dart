import 'package:google_sign_in/google_sign_in.dart';

import '../core/api_config.dart';
import '../core/api_exception.dart';
import '../models/credencial_google.dart';

class GoogleTokenProvider {
  GoogleTokenProvider();

  final GoogleSignIn _google = GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: ApiConfig.googleServerClientId.isEmpty
        ? null
        : ApiConfig.googleServerClientId,
  );

  Future<CredencialGoogle> obtenerCredencial() async {
    final cuenta = await _google.signIn();
    if (cuenta == null) {
      throw const InicioCancelado();
    }

    final idToken = (await cuenta.authentication).idToken;
    if (idToken == null) {
      throw const ApiException(
        'Google no devolvió el token. Revisa el Client ID del servidor.',
      );
    }
    return CredencialGoogle(idToken: idToken, fotoUrl: cuenta.photoUrl);
  }

  Future<void> cerrarSesion() async {
    try {
      await _google.signOut();
    } catch (_) {}
  }
}
