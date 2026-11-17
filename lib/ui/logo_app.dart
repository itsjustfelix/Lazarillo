import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tema.dart';

/// Logo vectorial de Lazarillo.
///
/// Se dibuja directamente en Flutter mediante CustomPainter,
/// sin depender de una imagen PNG.
///
/// Puede utilizarse en cualquier pantalla cambiando [tamano].
class LogoApp extends StatelessWidget {
  const LogoApp({super.key, this.tamano = 160});

  final double tamano;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tamano,
      height: tamano,
      child: CustomPaint(painter: const _PintorLogoLazarillo()),
    );
  }
}

/// Dibuja las formas del logo original:
/// - Contorno blanco del ojo.
/// - Dos aros azules.
/// - Círculo azul central.
class _PintorLogoLazarillo extends CustomPainter {
  const _PintorLogoLazarillo();

  // Dimensiones de referencia del diseño original.
  static const double _referencia = 1152;

  static const Offset _centro = Offset(576, 576);

  @override
  void paint(Canvas canvas, Size size) {
    // Mantiene las proporciones en cualquier tamaño.
    final escala = math.min(size.width, size.height) / _referencia;

    canvas.save();

    // Centra el dibujo en el espacio disponible.
    canvas.translate(
      (size.width - _referencia * escala) / 2,
      (size.height - _referencia * escala) / 2,
    );

    canvas.scale(escala);

    _dibujarContorno(canvas);
    _dibujarAros(canvas);
    _dibujarCentro(canvas);

    canvas.restore();
  }

  /// Dibuja el contorno blanco del ojo.
  void _dibujarContorno(Canvas canvas) {
    final contorno = Path()
      ..moveTo(192, 576)
      // Párpado superior.
      ..cubicTo(356, 286, 796, 286, 960, 576)
      // Párpado inferior.
      ..cubicTo(796, 866, 356, 866, 192, 576)
      ..close();

    final pincel = Paint()
      ..color = ColoresApp.blanco
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    canvas.drawPath(contorno, pincel);
  }

  /// Dibuja los dos círculos azules.
  void _dibujarAros(Canvas canvas) {
    // Aro más externo:
    //  más transparente = más visible.
    final aroExterior = Paint()
      ..color = ColoresApp.secundario.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..isAntiAlias = true;

    canvas.drawCircle(_centro, 179, aroExterior);

    // Aro más interno:
    //  menos transparente = más suave.
    final aroInterior = Paint()
      ..color = ColoresApp.secundario.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..isAntiAlias = true;

    canvas.drawCircle(_centro, 145, aroInterior);
  }

  /// Dibuja el círculo azul sólido del centro.
  void _dibujarCentro(Canvas canvas) {
    final pincel = Paint()
      ..color = ColoresApp.secundario
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawCircle(_centro, 85, pincel);
  }

  @override
  bool shouldRepaint(covariant _PintorLogoLazarillo anterior) {
    return false;
  }
}
