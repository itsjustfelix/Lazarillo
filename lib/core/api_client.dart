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

  /// Esta funcion se utliza para envia un JSON al backend al momento de iniciar sesion
  /// para verificar que el JWT que retorna Google sea valido y devuelve
  /// un JWT propio del backend y el nombre del usuario.
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

  /// Esta funcion se utliza para enviar un JSON al backend con la foto,
  /// el JWT para, verificar primeramente si el usuario esta autenticado
  /// y luego describe la foto y devuelve un JSON con el resultado de la descripcion.
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

  ///Esta funcion flecha es para cear la uri del backend conectando la ruta base
  ///(fue la que se pasa al momento de hacer el  build con --define) con la ruta
  ///que se le pasa a la funcion, para que el backend pueda recibir la peticion en la ruta correcta.
  Uri _uri(String ruta) => Uri.parse('${ApiConfig.baseUrl}$ruta');

  ///Esta funcion es la encargada de ejecutar la peticion al backend y manejar
  ///los errores de conexion, tiempo agotado y errores del cliente HTTP, lanzando
  ///las excepciones correspondientes.
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

  ///Esta funcion es la encargada de procesar la respuesta del backend, verificando
  ///el codigo de estado de la respuesta y si es valido decodifica el cuerpo de
  /// la respuesta y lo retorna como un Map<String, dynamic> para que pueda ser utilizado por los services.
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
