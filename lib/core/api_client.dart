import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'api_config.dart';
import 'api_exception.dart';

typedef TokenReader = Future<String?> Function();

/// Único lugar que habla HTTP con el backend.
/// Se encarga de: URL base, header de autenticación, timeout y traducir
/// los fallos a [ApiException]. Los services solo piden datos.
class ApiClient {
  ApiClient({required TokenReader leerToken, http.Client? client})
    : _leerToken = leerToken,
      _client = client ?? http.Client();

  final TokenReader _leerToken;
  final http.Client _client;

  Future<Map<String, dynamic>> postJson(
    String ruta,
    Map<String, dynamic> cuerpo,
  ) {
    return _ejecutar(
      () => _client.post(
        _uri(ruta),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(cuerpo),
      ),
    );
  }

  Future<Map<String, dynamic>> postArchivoAutenticado(
    String ruta, {
    required String campo,
    required String rutaArchivo,
    required String mimeType,
  }) async {
    final token = await _leerToken();
    if (token == null) throw const ApiException.sesionExpirada();

    return _ejecutar(() async {
      final peticion = http.MultipartRequest('POST', _uri(ruta))
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(
          await http.MultipartFile.fromPath(
            campo,
            rutaArchivo,
            contentType: MediaType.parse(mimeType),
          ),
        );
      final stream = await _client.send(peticion);
      return http.Response.fromStream(stream);
    });
  }

  Uri _uri(String ruta) => Uri.parse('${ApiConfig.baseUrl}$ruta');

  Future<Map<String, dynamic>> _ejecutar(
    Future<http.Response> Function() peticion,
  ) async {
    try {
      final respuesta = await peticion().timeout(ApiConfig.timeout);
      return _procesar(respuesta);
    } on SocketException {
      throw const ApiException.sinConexion();
    } on http.ClientException {
      throw const ApiException.sinConexion();
    } on TimeoutException {
      throw const ApiException.tiempoAgotado();
    }
  }

  Map<String, dynamic> _procesar(http.Response respuesta) {
    final codigo = respuesta.statusCode;

    if (codigo == 401 || codigo == 403) {
      throw ApiException(
        'Tu sesión expiró. Inicia sesión de nuevo.',
        statusCode: codigo,
      );
    }
    if (codigo < 200 || codigo >= 300) {
      throw ApiException(
        'El servidor respondió con un error.',
        statusCode: codigo,
      );
    }

    final cuerpo = jsonDecode(utf8.decode(respuesta.bodyBytes));
    if (cuerpo is! Map<String, dynamic>) {
      throw const ApiException('La respuesta del servidor no es válida.');
    }
    return cuerpo;
  }
}
