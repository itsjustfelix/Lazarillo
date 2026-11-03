import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/dependencias.dart';
import '../../core/etiquetas_coco.dart';
import '../../models/instruccion.dart';
import '../../services/busqueda/buscador_objeto_service.dart';
import '../../services/deteccion/detector_objetos_service.dart';
import '../../services/deteccion/resolutor_objeto.dart';
import '../../services/voz/voz_a_texto_service.dart';
import '../modulos/pagina_camara.dart';

/// Módulo de la izquierda: busca un objeto y guía con la voz.
class BuscarObjetoView extends StatefulWidget {
  const BuscarObjetoView({
    super.key,
    required this.dependencias,
    required this.camara,
  });

  final Dependencias dependencias;

  /// Cámara ya abierta, prestada por ModulosView.
  final CameraController camara;

  @override
  State<BuscarObjetoView> createState() => _BuscarObjetoViewState();
}

class _BuscarObjetoViewState extends State<BuscarObjetoView> {
  BuscadorObjetoService? _buscador;
  StreamSubscription<Instruccion>? _suscripcion;
  bool _ocupado = false; // true mientras pregunta y escucha el objeto
  String? _error; // detalle técnico del fallo, para quien desarrolla

  Dependencias get _d => widget.dependencias;

  @override
  void initState() {
    super.initState();
    _preparar();
  }

  Future<void> _preparar() async {
    try {
      // El detector se carga una sola vez y se reutiliza entre visitas.
      final detector = await _d.obtenerDetector();
      if (!mounted) return;

      final buscador = BuscadorObjetoService(detector: detector);
      // Cada instrucción nueva se dice en voz alta, cortando la anterior.
      _suscripcion = buscador.instrucciones.listen(
        (instruccion) => _d.voz.hablar(instruccion.texto),
        onError: (_) => _d.voz.hablar('Hubo un problema con la búsqueda.'),
      );
      setState(() => _buscador = buscador);
    } on DeteccionException catch (e) {
      await _mostrarError(e.message);
    } catch (e) {
      await _mostrarError('$e');
    }
  }

  /// La persona oye un mensaje simple; el detalle técnico queda en
  /// pantalla y en la terminal para poder corregirlo.
  Future<void> _mostrarError(String detalle) async {
    debugPrint('BuscarObjeto: $detalle');
    if (mounted) setState(() => _error = detalle);
    await _d.voz.hablar('No pude preparar la búsqueda de objetos.');
  }

  /// Un doble toque inicia la búsqueda; otro doble toque la detiene.
  Future<void> _alActivar() async {
    if (_ocupado) return;

    final buscador = _buscador;
    if (buscador == null) {
      await _d.voz.hablar('Un momento, estoy preparando la búsqueda.');
      return;
    }

    if (buscador.activo) {
      await buscador.detener();
      await _d.voz.hablar('Búsqueda detenida.');
      return;
    }

    _ocupado = true;
    try {
      final claseId = await _preguntarObjeto();
      // Si la persona se fue a otro módulo mientras hablaba, no se empieza.
      if (claseId == null || !mounted) return;

      final nombre = EtiquetasCoco.espanol[claseId];
      // Se empieza a analizar de inmediato y el aviso se dice sin esperar.
      await buscador.iniciar(
        camara: widget.camara,
        claseId: claseId,
        nombreObjeto: nombre,
      );
      unawaited(_d.voz.hablar('Buscando $nombre.'));
    } on VozException catch (e) {
      await _d.voz.hablar(e.message);
    } finally {
      _ocupado = false;
    }
  }

  /// Pregunta qué objeto busca y devuelve su id, o null si no se entendió.
  /// Si no lo oye o no lo reconoce, lo intenta una segunda vez sin pedir
  /// otro toque.
  Future<int?> _preguntarObjeto() async {
    var pregunta = 'Di qué quieres buscar.';

    for (var intento = 1; intento <= 2; intento++) {
      await _d.voz.hablar(pregunta);

      // Al terminar de hablar: el micrófono se abre, vibra una vez para
      // avisar, escucha 3 segundos exactos y se cierra. Recién ahí se procesa.
      final frase = await _d.escucha.escucharVentana(
        ventana: const Duration(seconds: 3),
        alAbrir: _d.vibracion.avisar,
      );
      debugPrint('Objeto dicho: "$frase"');

      if (frase.isEmpty) {
        pregunta = 'No te escuché. Dime de nuevo qué quieres buscar.';
        continue;
      }
      final claseId = ResolutorObjeto.claseDesdeFrase(frase);
      if (claseId != null) return claseId;
      pregunta =
          'Ese objeto todavía no lo puedo buscar. Prueba con otro, '
          'por ejemplo botella, celular o silla.';
    }

    await _d.voz.hablar(
      'No pude entenderte. Toca dos veces para intentarlo otra vez.',
    );
    return null;
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    // Solo se cierra el buscador: la cámara y el detector no son de esta
    // pantalla (los presta ModulosView y los comparte Dependencias).
    final buscador = _buscador;
    if (buscador != null) unawaited(buscador.cerrar());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PaginaCamara(
      camara: widget.camara,
      etiqueta:
          'Buscar objetos. Toca dos veces y di qué quieres buscar. '
          'Toca dos veces de nuevo para detener.',
      alActivar: _alActivar,
      ocupado: _buscador == null && _error == null,
      mensaje: _error,
    );
  }
}
