import '../services/auth_service.dart';
import '../services/descripcion_service.dart';
import '../services/deteccion/detector_objetos_service.dart';
import '../services/google_token_provider.dart';
import '../services/token_storage.dart';
import '../services/vibracion_service.dart';
import '../services/voz/texto_a_voz_service.dart';
import '../services/voz/voz_a_texto_service.dart';
import 'api_client.dart';

/// Crea cada service una sola vez y se los reparte a las pantallas.
/// Ninguna clase crea a otra por dentro: todo se arma aquí.
class Dependencias {
  final _storage = TokenStorage();

  late final api = ApiClient(leerToken: _storage.leerJwt);
  late final auth = AuthService(
    api: api,
    storage: _storage,
    google: GoogleTokenProvider(),
  );
  late final descripcion = DescripcionService(api);

  final voz = TextoAVozService();
  final escucha = VozATextoService();
  final vibracion = VibracionService();

  DetectorObjetosService? _detector;

  Future<DetectorObjetosService> obtenerDetector() async {
    final existente = _detector;
    if (existente != null) return existente;

    final nuevo = await DetectorObjetosService.cargar();
    _detector = nuevo;
    return nuevo;
  }
}
