import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/dependencias.dart';
import '../../services/texto/reconocedor_texto_service.dart';
import '../modulos/pagina_camara.dart';

enum _Estado { listo, procesando, leyendo }

class ExtraerTextoView extends StatefulWidget {
  const ExtraerTextoView({
    super.key,
    required this.dependencias,
    required this.camara,
  });

  final Dependencias dependencias;
  final CameraController camara;

  @override
  State<ExtraerTextoView> createState() => _ExtraerTextoViewState();
}

class _ExtraerTextoViewState extends State<ExtraerTextoView> {
  final _reconocedor = ReconocedorTextoService();
  _Estado _estado = _Estado.listo;

  Dependencias get _d => widget.dependencias;
  XFile? foto;
  void _cambiarEstado(_Estado nuevo) {
    if (mounted) setState(() => _estado = nuevo);
  }

  Future<void> _alActivar() async {
    switch (_estado) {
      case _Estado.procesando:
        return;
      case _Estado.leyendo:
        await _d.voz.detener();
        await _d.voz.hablar(
          'Lectura detenida. Toca dos veces para leer de nuevo.',
        );
      case _Estado.listo:
        await _leerTexto();
    }
  }

  Future<void> _leerTexto() async {
    _cambiarEstado(_Estado.procesando);
    try {
      foto = await widget.camara.takePicture();
      unawaited(_d.voz.hablar('Leyendo la imagen.'));

      final texto = await _reconocedor.extraerDeArchivo(foto!.path);
      if (!mounted) return;

      if (texto.isEmpty) {
        await _d.voz.hablar(
          'No encontré texto. Acerca el teléfono a la '
          'página y busca más luz.',
        );
        return;
      }

      _cambiarEstado(_Estado.leyendo);
      await _d.voz.leerTextoLargo(texto);
    } on TextoException catch (e) {
      if (mounted) await _d.voz.hablar(e.message);
    } catch (_) {
      if (mounted) {
        await _d.voz.hablar('Ocurrió un error inesperado. Intenta de nuevo.');
      }
    } finally {
      if (foto != null) {
        await _eliminarArchivoFoto(foto!.path);
      }
      _cambiarEstado(_Estado.listo);
    }
  }

  Future<void> _eliminarArchivoFoto(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  void dispose() {
    unawaited(_reconocedor.cerrar());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final etiqueta = _estado == _Estado.leyendo
        ? 'Leyendo el texto. Toca dos veces para detener.'
        : 'Leer texto. Toca dos veces para fotografiar la página '
              'y escucharla.';

    return PaginaCamara(
      camara: widget.camara,
      etiqueta: etiqueta,
      alActivar: _alActivar,
      ocupado: _estado == _Estado.procesando,
    );
  }
}
