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

class BuscarObjetoView extends StatefulWidget {
  const BuscarObjetoView({
    super.key,
    required this.dependencias,
    required this.camara,
  });

  final Dependencias dependencias;
  final CameraController camara;

  @override
  State<BuscarObjetoView> createState() => _BuscarObjetoViewState();
}

class _BuscarObjetoViewState extends State<BuscarObjetoView> {
  BuscadorObjetoService? _buscador;
  StreamSubscription<Instruccion>? _suscripcion;
  bool _ocupado = false;
  String? _error;

  Dependencias get _d => widget.dependencias;

  @override
  void initState() {
    super.initState();
    _preparar();
  }

  Future<void> _preparar() async {
    try {
      final detector = await _d.obtenerDetector();
      if (!mounted) return;

      final buscador = BuscadorObjetoService(detector: detector);
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

  Future<void> _mostrarError(String detalle) async {
    if (mounted) setState(() => _error = detalle);
    await _d.voz.hablar('No pude preparar la búsqueda de objetos.');
  }

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
      if (claseId == null || !mounted) return;

      final nombre = EtiquetasCoco.espanol[claseId];
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

  Future<int?> _preguntarObjeto() async {
    var pregunta = 'Di qué quieres buscar.';

    for (var intento = 1; intento <= 2; intento++) {
      await _d.voz.hablar(pregunta);
      final frase = await _d.escucha.escucharVentana(
        ventana: const Duration(seconds: 3),
        alAbrir: _d.vibracion.avisar,
      );

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
