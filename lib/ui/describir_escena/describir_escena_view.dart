import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/dependencias.dart';
import '../modulos/pagina_camara.dart';

/// Módulo del centro: describe lo que ve la cámara.
class DescribirEscenaView extends StatefulWidget {
  const DescribirEscenaView({
    super.key,
    required this.dependencias,
    required this.camara,
    required this.onSesionExpirada,
  });

  final Dependencias dependencias;

  /// Cámara ya abierta, prestada por ModulosView.
  final CameraController camara;
  final VoidCallback onSesionExpirada;

  @override
  State<DescribirEscenaView> createState() => _DescribirEscenaViewState();
}

class _DescribirEscenaViewState extends State<DescribirEscenaView> {
  bool _procesando = false;

  Dependencias get _d => widget.dependencias;

  Future<void> _describir() async {
    if (_procesando) return;

    setState(() => _procesando = true);
    try {
      final foto = await widget.camara.takePicture();
      // Sin await: se dice "Analizando" mientras la foto viaja al servidor.
      unawaited(_d.voz.hablar('Analizando.'));

      // Mientras el servidor responde, el teléfono da pulsos suaves.
      final texto = await _conPulsosDeEspera(
        () => _d.descripcion.describirEscena(foto.path),
      );
      // Si la persona ya se fue a otro módulo, no se lee la descripción.
      if (!mounted) return;
      await _d.voz.hablar(texto);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.esSesionExpirada) {
        widget.onSesionExpirada();
        return;
      }
      await _d.voz.hablar(e.message);
    } catch (_) {
      if (!mounted) return;
      await _d.voz.hablar('Ocurrió un error inesperado. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  /// Da pulsos mientras [espera] no termina y los corta en cuanto termina,
  /// sea porque llegó la respuesta o porque falló. Los pulsos se paran ANTES
  /// de que la voz lea la descripción, no después.
  Future<T> _conPulsosDeEspera<T>(Future<T> Function() espera) async {
    unawaited(_d.vibracion.pulsarEnEspera());
    try {
      return await espera();
    } finally {
      unawaited(_d.vibracion.detener());
    }
  }

  @override
  void dispose() {
    // Si la persona se va a otro módulo mientras se espera, no deben seguir
    // los pulsos en un módulo que ya no está a la vista.
    unawaited(_d.vibracion.detener());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PaginaCamara(
      camara: widget.camara,
      etiqueta:
          'Describir escena. Toca dos veces para describir '
          'lo que tienes enfrente.',
      alActivar: _describir,
      ocupado: _procesando,
    );
  }
}
