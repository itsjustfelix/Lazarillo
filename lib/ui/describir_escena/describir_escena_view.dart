import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/dependencias.dart';
import '../modulos/pagina_camara.dart';

/// Módulo del centro: describe lo que ve la cámara.
/// Un segundo doble toque interrumpe tanto la narración como la espera.
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
  bool _cancelada = false;
  bool _cancelando = false;

  Dependencias get _d => widget.dependencias;

  /// Doble toque: si está ocupada, cancela; si está libre, describe.
  Future<void> _alActivar() async {
    if (_cancelando) return;

    if (_procesando) {
      await _cancelarDescripcion();
      return;
    }

    await _describir();
  }

  Future<void> _cancelarDescripcion() async {
    // La marca es inmediata: una respuesta del backend que llegue después
    // no debe comenzar a hablar ni mostrar errores de esta petición.
    if (_cancelada) return;
    _cancelada = true;
    _cancelando = true;

    try {
      await _d.vibracion.detener();
      await _d.voz.detener();

      // Confirmación breve para quien utiliza la app sin mirar la pantalla.
      if (mounted) {
        await _d.voz.hablar('Descripción detenida.');
      }
    } finally {
      _cancelando = false;
    }
  }

  Future<void> _describir() async {
    setState(() {
      _procesando = true;
      _cancelada = false;
    });

    // La foto pertenece a esta operación; no se comparte entre intentos.
    XFile? foto;

    try {
      foto = await widget.camara.takePicture();
      if (!mounted || _cancelada) return;

      // Esperamos el anuncio para que una cancelación no deje un mensaje
      // «Analizando» pendiente de reproducirse después de detener la voz.
      await _d.voz.hablar('Analizando.');
      if (!mounted || _cancelada) return;

      final texto = await _conPulsosDeEspera(
        () => _d.descripcion.describirEscena(foto!.path),
      );

      // Aunque no se cancele la petición HTTP, su respuesta ya no se narra.
      if (!mounted || _cancelada) return;
      await _d.voz.hablar(texto);
    } on ApiException catch (e) {
      if (!mounted || _cancelada) return;
      if (e.esSesionExpirada) {
        widget.onSesionExpirada();
        return;
      }
      await _d.voz.hablar(e.message);
    } catch (_) {
      if (!mounted || _cancelada) return;
      await _d.voz.hablar('Ocurrió un error inesperado. Intenta de nuevo.');
    } finally {
      if (foto != null) {
        try {
          await _eliminarArchivoFoto(foto.path);
        } catch (_) {
          // La limpieza de la foto no debe bloquear la siguiente interacción.
        }
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
    final archivo = File(path);
    if (await archivo.exists()) {
      await archivo.delete();
    }
  }

  @override
  void dispose() {
    _cancelada = true;
    // Al abandonar el módulo no deben quedar pulsos en espera.
    unawaited(_d.vibracion.detener());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PaginaCamara(
      etiqueta: _procesando
          ? 'Describir escena. Toca dos veces para detener la descripción.'
          : 'Describir escena. Toca dos veces para describir '
                'lo que tienes enfrente.',
      alActivar: _alActivar,
      ocupado: _procesando,
    );
  }
}
