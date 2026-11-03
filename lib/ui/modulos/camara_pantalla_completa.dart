import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../tema.dart';

/// Muestra la cámara a pantalla completa SIN deformarla.
///
/// Por qué existe: si CameraPreview se mete en un espacio de tamaño fijo
/// (por ejemplo, toda la pantalla), el espacio manda y la imagen se estira.
/// Aquí se le da a la vista previa su proporción real y se la escala con
/// BoxFit.cover: llena la pantalla manteniendo la proporción y recorta el
/// sobrante, igual que la app de cámara del teléfono.
class CamaraPantallaCompleta extends StatelessWidget {
  const CamaraPantallaCompleta({super.key, required this.controlador});

  final CameraController controlador;

  @override
  Widget build(BuildContext context) {
    final tamano = controlador.value.previewSize;
    if (tamano == null) return const ColoredBox(color: ColoresApp.fondoCamara);

    return ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          // La cámara informa su tamaño "acostado" (ancho > alto). Con el
          // teléfono en vertical hay que intercambiar ancho y alto.
          child: SizedBox(
            width: tamano.height,
            height: tamano.width,
            child: CameraPreview(controlador),
          ),
        ),
      ),
    );
  }
}
