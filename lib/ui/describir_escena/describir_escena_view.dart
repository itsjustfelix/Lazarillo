import 'dart:async';
import 'dart:io';

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
  XFile? foto;
  Future<void> _describir() async {
    if (_procesando) return;

    setState(() => _procesando = true);
    try {
      foto = await widget.camara.takePicture();
      unawaited(_d.voz.hablar('Analizando.'));

      final texto = await _conPulsosDeEspera(
        () => _d.descripcion.describirEscena(foto!.path),
      );
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
      if (foto != null) {
        await _eliminarArchivoFoto(foto!.path);
      }
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<T> _conPulsosDeEspera<T>(Future<T> Function() espera) async {
    unawaited(_d.vibracion.pulsarEnEspera());
    try {
      return await espera();
    } finally {
      unawaited(_d.vibracion.detener());
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
