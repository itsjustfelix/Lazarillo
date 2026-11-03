import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../tema.dart';
import 'camara_pantalla_completa.dart';

class PaginaCamara extends StatelessWidget {
  const PaginaCamara({
    super.key,
    required this.camara,
    required this.etiqueta,
    required this.alActivar,
    this.ocupado = false,
    this.mensaje,
  });

  final CameraController camara;

  /// Lo que lee el lector de pantalla (TalkBack) para este módulo.
  final String etiqueta;

  /// La acción del módulo (se ejecuta con doble toque).
  final VoidCallback alActivar;

  /// Muestra un indicador de carga sobre la cámara.
  final bool ocupado;

  /// Texto opcional sobre la cámara (por ejemplo, un error para quien
  /// desarrolla).
  final String? mensaje;

  @override
  Widget build(BuildContext context) {
    final mensaje = this.mensaje;

    return Semantics(
      button: true,
      label: etiqueta,
      // Con TalkBack activado, su propio doble toque llega aquí como
      // "activar". Sin TalkBack, lo recoge el GestureDetector de abajo.
      onTap: alActivar,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: alActivar,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CamaraPantallaCompleta(controlador: camara),
            if (ocupado) const Center(child: CircularProgressIndicator()),
            if (mensaje != null)
              Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(16),
                  color: ColoresApp.fondoMensaje,
                  child: SelectableText(
                    mensaje,
                    style: const TextStyle(
                      color: ColoresApp.contenidoSobreCamara,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
