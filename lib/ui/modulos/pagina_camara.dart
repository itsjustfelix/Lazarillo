import 'package:flutter/material.dart';
import '../tema.dart';

/// Capa de interacción transparente: la cámara se dibuja una sola vez
/// detrás del PageView, desde ModulosView.
class PaginaCamara extends StatelessWidget {
  const PaginaCamara({
    super.key,
    required this.etiqueta,
    required this.alActivar,
    this.ocupado = false,
    this.mensaje,
  });

  final String etiqueta;
  final VoidCallback alActivar;
  final bool ocupado;
  final String? mensaje;

  @override
  Widget build(BuildContext context) {
    final mensaje = this.mensaje;

    return Semantics(
      button: true,
      label: etiqueta,
      value: ocupado ? 'Procesando' : null,
      onTap: alActivar,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: alActivar,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // La actividad se anuncia por voz o vibración desde cada módulo.
            // No tapamos la cámara con un indicador circular.
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
