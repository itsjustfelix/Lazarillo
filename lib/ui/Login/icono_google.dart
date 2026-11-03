import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tema.dart';

/// La «G» de Google en sus cuatro colores, dibujada con código (no usa
/// ninguna imagen). Es una aproximación fiel del logo: cuatro arcos y la
/// barra azul. Si quieres el archivo oficial, se descarga de los recursos de
/// marca de Google y se cambia este widget por un Image.asset.
class IconoGoogle extends StatelessWidget {
  const IconoGoogle({super.key, this.tamano = 28});

  final double tamano;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tamano,
      height: tamano,
      child: CustomPaint(painter: _PintorG()),
    );
  }
}

class _PintorG extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grosor = size.width * 0.2;
    final radio = (size.width - grosor) / 2;
    final centro = Offset(size.width / 2, size.height / 2);
    final cuadro = Rect.fromCircle(center: centro, radius: radio);

    // Los ángulos se miden en grados desde las 3 en punto, hacia abajo.
    void arco(Color color, double inicio, double barrido) {
      final pincel = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = grosor;
      canvas.drawArc(
        cuadro,
        inicio * math.pi / 180,
        barrido * math.pi / 180,
        false,
        pincel,
      );
    }

    arco(ColoresApp.googleRojo, 200, 115); // arriba, hasta la apertura
    arco(ColoresApp.googleAmarillo, 135, 65); // abajo a la izquierda
    arco(ColoresApp.googleVerde, 45, 90); // abajo
    arco(ColoresApp.googleAzul, 0, 45); // derecha, bajo la barra

    // La barra horizontal de la G, del centro al borde derecho.
    canvas.drawRect(
      Rect.fromLTRB(
        centro.dx,
        centro.dy - grosor / 2,
        size.width,
        centro.dy + grosor / 2,
      ),
      Paint()..color = ColoresApp.googleAzul,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter anterior) => false;
}
