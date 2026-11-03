import '../core/api_exception.dart';

class LoginResponse {
  const LoginResponse({required this.jwtToken, required this.nombre});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final jwt = json['jwt_token'];
    if (jwt is! String || jwt.isEmpty) {
      throw const ApiException('El servidor no devolvió una sesión válida.');
    }
    return LoginResponse(
      jwtToken: jwt,
      nombre: (json['nombre'] as String?) ?? 'usuario',
    );
  }

  final String jwtToken;
  final String nombre;
}
