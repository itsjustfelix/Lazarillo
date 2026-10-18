import 'dart:ui' show Rect;

import 'package:camera/camera.dart';
import 'package:flutter_litert/flutter_litert.dart'
    show detectionSize, rotationForFrame;
import 'package:object_detection/object_detection.dart';

import '../../core/etiquetas_coco.dart';
import '../../models/deteccion.dart';

class DeteccionException implements Exception {
  const DeteccionException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Detecta objetos en el video de la cámara usando el paquete
/// object_detection (modelo EfficientDet-Lite0, sin internet).
/// El análisis corre en un hilo aparte: la pantalla no se congela.
class DetectorObjetosService {
  DetectorObjetosService._(this._detector);

  /// Los fotogramas se reducen a este lado máximo antes de analizarse.
  static const int _ladoMaximo = 640;

  final ObjectDetector _detector;

  /// Carga el detector. Hazlo una sola vez, al abrir la pantalla.
  static Future<DetectorObjetosService> cargar() async {
    try {
      return DetectorObjetosService._(await ObjectDetector.create());
    } catch (error) {
      throw DeteccionException('No pude cargar el detector de objetos: $error');
    }
  }

  /// Analiza un fotograma del video. Las cajas salen normalizadas (0 a 1)
  /// sobre la imagen ya girada, con izquierda y derecha como las ve la persona.
  Future<List<Deteccion>> detectarEnFotograma(
    CameraImage fotograma,
    CameraController camara, {
    double umbral = 0.3,
  }) async {
    final descripcion = camara.description;
    final rotacion = rotationForFrame(
      width: fotograma.width,
      height: fotograma.height,
      sensorOrientation: descripcion.sensorOrientation,
      isFrontCamera: descripcion.lensDirection == CameraLensDirection.front,
      deviceOrientation: camara.value.deviceOrientation,
    );

    // El espacio de coordenadas en que el paquete devuelve las cajas.
    final tamano = detectionSize(
      width: fotograma.width,
      height: fotograma.height,
      rotation: rotacion,
      maxDim: _ladoMaximo,
    );

    final objetos = await _detector.detectFromCameraImage(
      fotograma,
      rotation: rotacion,
      options: ObjectDetectorOptions(scoreThreshold: umbral, maxResults: 20),
      maxDim: _ladoMaximo,
    );

    final ancho = tamano.width.toDouble();
    final alto = tamano.height.toDouble();
    return objetos
        .map((objeto) => _convertir(objeto, ancho, alto))
        .whereType<Deteccion>()
        .toList();
  }

  /// De todo lo detectado, deja solo la clase buscada (la más segura primero).
  List<Deteccion> filtrarPorClase(List<Deteccion> detecciones, int claseId) {
    return detecciones.where((d) => d.claseId == claseId).toList()
      ..sort((a, b) => b.confianza.compareTo(a.confianza));
  }

  Future<void> cerrar() => _detector.dispose();

  /// Traduce lo que devuelve el paquete a nuestro modelo, en español.
  Deteccion? _convertir(DetectedObject objeto, double ancho, double alto) {
    final claseId = EtiquetasCoco.ingles.indexOf(objeto.categoryName);
    if (claseId < 0) return null; // etiqueta vacía ("???") del modelo

    final caja = objeto.boundingBox;
    return Deteccion(
      claseId: claseId,
      etiqueta: EtiquetasCoco.espanol[claseId],
      confianza: objeto.score,
      caja: Rect.fromLTRB(
        _normalizar(caja.topLeft.x, ancho),
        _normalizar(caja.topLeft.y, alto),
        _normalizar(caja.bottomRight.x, ancho),
        _normalizar(caja.bottomRight.y, alto),
      ),
    );
  }

  double _normalizar(double valor, double total) =>
      (valor / total).clamp(0.0, 1.0).toDouble();
}
