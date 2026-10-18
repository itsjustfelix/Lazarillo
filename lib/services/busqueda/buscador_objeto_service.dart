import 'dart:async';

import 'package:camera/camera.dart';

import '../../models/deteccion.dart';
import '../../models/instruccion.dart';
import '../deteccion/detector_objetos_service.dart';
import 'guia_busqueda.dart';

/// Busca un objeto de forma continua: recibe el video de la cámara,
/// analiza fotogramas y emite instrucciones para guiar a la persona.
///
/// Conecta tres piezas, sin hacer el trabajo de ninguna:
///   cámara -> DetectorObjetosService -> GuiaBusqueda -> [instrucciones]
class BuscadorObjetoService {
  BuscadorObjetoService({
    required DetectorObjetosService detector,
    this.intervaloMinimo = const Duration(milliseconds: 300),
  }) : _detector = detector;

  final DetectorObjetosService _detector;

  /// Tiempo mínimo entre análisis. La cámara da ~30 fotogramas por segundo;
  /// los que sobran se descartan.
  final Duration intervaloMinimo;

  final _instrucciones = StreamController<Instruccion>.broadcast();
  CameraController? _camara;
  GuiaBusqueda? _guia;
  int _claseId = -1;
  bool _procesando = false;
  DateTime _ultimoAnalisis = DateTime.fromMillisecondsSinceEpoch(0);

  /// Lo que hay que decirle a la persona. Escúchalo y pásalo a la voz.
  Stream<Instruccion> get instrucciones => _instrucciones.stream;

  bool get activo => _guia != null;

  Future<void> iniciar({
    required CameraController camara,
    required int claseId,
    required String nombreObjeto,
  }) async {
    await detener();
    _camara = camara;
    _claseId = claseId;
    _guia = GuiaBusqueda(nombreObjeto: nombreObjeto);
    await camara.startImageStream(_alRecibirFotograma);
  }

  Future<void> detener() async {
    final camara = _camara;
    _camara = null;
    _guia = null;
    if (camara != null && camara.value.isStreamingImages) {
      await camara.stopImageStream();
    }
  }

  Future<void> cerrar() async {
    await detener();
    await _instrucciones.close();
  }

  Future<void> _alRecibirFotograma(CameraImage fotograma) async {
    final guia = _guia;
    final camara = _camara;
    if (guia == null || camara == null || _procesando) return;

    final ahora = DateTime.now();
    if (ahora.difference(_ultimoAnalisis) < intervaloMinimo) return;

    _procesando = true;
    _ultimoAnalisis = ahora;
    try {
      final detecciones = await _detector.detectarEnFotograma(
        fotograma,
        camara,
      );

      // La búsqueda pudo detenerse o cambiar mientras se analizaba.
      if (_guia != guia) return;

      final instruccion = guia.evaluar(
        _mejorCoincidencia(detecciones),
        DateTime.now(),
      );
      if (instruccion != null) _instrucciones.add(instruccion);
      if (guia.terminado) await detener();
    } catch (error) {
      if (!_instrucciones.isClosed) _instrucciones.addError(error);
    } finally {
      _procesando = false;
    }
  }

  Deteccion? _mejorCoincidencia(List<Deteccion> detecciones) {
    final buscadas = _detector.filtrarPorClase(detecciones, _claseId);
    return buscadas.isEmpty ? null : buscadas.first;
  }
}
