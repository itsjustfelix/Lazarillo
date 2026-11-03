import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'core/dependencias.dart';
import 'services/camara/camara_service.dart';
import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Todo esto ocurre ANTES de dibujar nada: mientras tanto se ve la pantalla
  // de arranque nativa del sistema.
  final dependencias = Dependencias();
  final haySesion = await _haySesionGuardada(dependencias);

  // Solo con sesión guardada se abre la cámara ya: si no hay sesión, primero
  // va el login y no tiene sentido (ni se debe) pedir el permiso antes.
  final camara = haySesion ? await _abrirCamaraSinFallar() : null;

  runApp(
    LazarilloApp(
      dependencias: dependencias,
      haySesionInicial: haySesion,
      camaraInicial: camara,
    ),
  );
}

/// Si el almacenamiento seguro falla (pasa en algunos teléfonos), se trata
/// como "sin sesión" para que la app abra igual en el inicio de sesión.
Future<bool> _haySesionGuardada(Dependencias dependencias) async {
  try {
    return await dependencias.auth.haySesion();
  } catch (_) {
    return false;
  }
}

/// Si la cámara no se pudo abrir (sin permiso, sin cámara...), no se rompe el
/// arranque: devuelve null y ModulosView lo intenta de nuevo y avisa por voz.
Future<CameraController?> _abrirCamaraSinFallar() async {
  try {
    return await CamaraService.abrir();
  } catch (e) {
    debugPrint('Cámara en el arranque: $e');
    return null;
  }
}
