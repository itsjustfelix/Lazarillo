import '../core/api_client.dart';
import '../models/descripcion_response.dart';

/// Caso de uso: describir una foto para la persona.
class DescripcionService {
  DescripcionService(this._api);

  final ApiClient _api;

  /// Devuelve el texto listo para leerse en voz alta.
  Future<String> describirEscena(String rutaFoto) async {
    final json = await _api.postArchivoAutenticado(
      '/descripcion/describir-escena',
      campo: 'foto',
      rutaArchivo: rutaFoto,
      mimeType: _mimeDe(rutaFoto),
    );
    return DescripcionResponse.fromJson(json).texto;
  }

  String _mimeDe(String ruta) {
    final minuscula = ruta.toLowerCase();
    if (minuscula.endsWith('.png')) return 'image/png';
    if (minuscula.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
