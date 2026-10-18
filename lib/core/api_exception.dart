/// Error con un mensaje pensado para ser leído en voz alta al usuario.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  const ApiException.sinConexion() : this('Sin conexión a internet.');

  const ApiException.tiempoAgotado()
    : this('El servidor tardó demasiado en responder.');

  const ApiException.sesionExpirada()
    : this('Tu sesión expiró. Inicia sesión de nuevo.', statusCode: 401);

  final String message;
  final int? statusCode;

  bool get esSesionExpirada => statusCode == 401 || statusCode == 403;

  @override
  String toString() => message;
}
