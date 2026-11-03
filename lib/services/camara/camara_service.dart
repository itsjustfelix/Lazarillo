import 'dart:io';

import 'package:camera/camera.dart';

/// Abre la cámara trasera lista para usar. Está aparte porque la necesitan
/// dos sitios: main.dart (al arrancar, mientras se ve la pantalla nativa) y
/// ModulosView (cuando la cámara no se abrió en el arranque).
class CamaraService {
  CamaraService._(); // solo tiene una función estática: no se instancia

  /// high = nítida sin pesar demasiado. Si la búsqueda de objetos se pone
  /// lenta, baja a ResolutionPreset.medium.
  static const _resolucion = ResolutionPreset.high;

  /// Lanza [CameraException] si falta el permiso o la cámara falla.
  static Future<CameraController> abrir() async {
    final camaras = await availableCameras();
    final trasera = camaras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => camaras.first,
    );
    final controlador = CameraController(
      trasera,
      _resolucion,
      enableAudio: false,
      // El detector de objetos convierte estos dos formatos de fotograma.
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.bgra8888,
    );
    await controlador.initialize();
    return controlador;
  }
}
