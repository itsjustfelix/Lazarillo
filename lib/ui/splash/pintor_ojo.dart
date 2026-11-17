import 'package:flutter/material.dart';

import '../tema.dart';
import 'linea_de_tiempo.dart';

/// Dibuja el ojo del splash: dos párpados, la pupila y dos aros que pulsan.
///
/// Las medidas salen del diseño original (lienzo de 390 x 844). Se dibuja en
/// esas coordenadas y el lienzo se escala al tamaño real de la pantalla, así
/// el ojo se ve igual de proporcionado en cualquier teléfono.
///
/// [progreso] va de 0 a 1 (la animación entera) y [mirada] es cuánto se
/// desplaza la pupila, en unidades del diseño (la mueve el dedo).
class PintorOjo extends CustomPainter {
  const PintorOjo({required this.progreso, required this.mirada});

  final double progreso;
  final Offset mirada;

  // ---- Medidas del diseño ----
  static const _anchoDiseno = 390.0;
  static const _centro = Offset(195, 422);
  static const _izquierda = 71.0; // donde empiezan los párpados
  static const _derecha = 319.0; // donde terminan
  static const _alturaParpado = 96.0; // cuánto se curva un párpado abierto

  // ---- Línea de tiempo (los porcentajes del diseño, de 0 a 1) ----
  // Párpados: cerrados al inicio y se abren entre 13 % y 32 %.
  static const _parpadoSuperior = [
    Fotograma(0, -0.18),
    Fotograma(0.1324, -0.18, Curves.easeInOut),
    Fotograma(0.3235, 1),
  ];
  static const _parpadoInferior = [
    Fotograma(0, 0.18),
    Fotograma(0.1324, 0.18, Curves.easeInOut),
    Fotograma(0.3235, 1),
  ];

  static const _escalaPupila = [
    Fotograma(0, 0.65),
    Fotograma(0.1706, 0.65, Curves.easeOut),
    Fotograma(0.3294, 1),
  ];
  static const _opacidadPupila = [
    Fotograma(0, 0),
    Fotograma(0.1706, 0, Curves.easeInOut),
    Fotograma(0.2794, 1),
  ];

  static const _escalaAroInterior = [
    Fotograma(0, 0.82),
    Fotograma(0.1912, 0.82, Curves.easeInOut),
    Fotograma(0.3088, 1, Curves.easeInOut),
    Fotograma(0.4559, 1.12, Curves.easeInOut),
    Fotograma(0.5735, 1, Curves.easeInOut),
    Fotograma(0.7206, 1.12, Curves.easeInOut),
    Fotograma(0.8382, 1),
  ];
  static const _opacidadAroInterior = [
    Fotograma(0, 0),
    Fotograma(0.1912, 0, Curves.easeInOut),
    Fotograma(0.3088, 1, Curves.easeInOut),
    Fotograma(0.4559, 0.64, Curves.easeInOut),
    Fotograma(0.5735, 1, Curves.easeInOut),
    Fotograma(0.7206, 0.64, Curves.easeInOut),
    Fotograma(0.8382, 1),
  ];

  static const _escalaAroExterior = [
    Fotograma(0, 0.82),
    Fotograma(0.2294, 0.82, Curves.easeInOut),
    Fotograma(0.3471, 1, Curves.easeInOut),
    Fotograma(0.4941, 1.1, Curves.easeInOut),
    Fotograma(0.6118, 1, Curves.easeInOut),
    Fotograma(0.7588, 1.1, Curves.easeInOut),
    Fotograma(0.8765, 1),
  ];
  static const _opacidadAroExterior = [
    Fotograma(0, 0),
    Fotograma(0.2294, 0, Curves.easeInOut),
    Fotograma(0.3471, 1, Curves.easeInOut),
    Fotograma(0.4941, 0.64, Curves.easeInOut),
    Fotograma(0.6118, 1, Curves.easeInOut),
    Fotograma(0.7588, 0.64, Curves.easeInOut),
    Fotograma(0.8765, 1),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // El ojo del diseño queda centrado en la pantalla, sea cual sea su alto.
    final escala = (size.width / _anchoDiseno) * 0.35;
    canvas
      ..translate(size.width / 2, size.height / 2)
      ..scale(escala)
      ..translate(-_centro.dx, -_centro.dy);

    _dibujarAros(canvas);
    _dibujarPupila(canvas);
    _dibujarParpados(canvas);
  }

  void _dibujarParpados(Canvas canvas) {
    final pincel = Paint()
      ..color = ColoresApp.blanco
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    // Negativo curva hacia arriba (párpado superior); positivo, hacia abajo.
    final superior = LineaDeTiempo.valorEn(progreso, _parpadoSuperior);
    final inferior = LineaDeTiempo.valorEn(progreso, _parpadoInferior);
    canvas
      ..drawPath(_parpado(-_alturaParpado * superior), pincel)
      ..drawPath(_parpado(_alturaParpado * inferior), pincel);
  }

  /// Un párpado es una curva Bézier de un extremo del ojo al otro. Los dos
  /// puntos de control se desplazan [curvatura] hacia arriba o abajo.
  Path _parpado(double curvatura) {
    final y = _centro.dy;
    return Path()
      ..moveTo(_izquierda, y)
      ..cubicTo(
        _izquierda + 49,
        y + curvatura,
        _izquierda + 199,
        y + curvatura,
        _derecha,
        y,
      );
  }

  /// Los dos aros azules que laten alrededor de la pupila: el exterior es
  /// más tenue y delgado; el interior, más marcado. Cada uno tiene su propia
  /// escala y opacidad en la línea de tiempo.
  void _dibujarAros(Canvas canvas) {
    _dibujarAro(
      canvas,
      radio: 56,
      grosor: 4,
      opacidadBase: 0.4,
      escala: LineaDeTiempo.valorEn(progreso, _escalaAroExterior),
      opacidad: LineaDeTiempo.valorEn(progreso, _opacidadAroExterior),
    );
    _dibujarAro(
      canvas,
      radio: 41.25,
      grosor: 5.5,
      opacidadBase: 0.75,
      escala: LineaDeTiempo.valorEn(progreso, _escalaAroInterior),
      opacidad: LineaDeTiempo.valorEn(progreso, _opacidadAroInterior),
    );
  }

  void _dibujarAro(
    Canvas canvas, {
    required double radio,
    required double grosor,
    required double opacidadBase,
    required double escala,
    required double opacidad,
  }) {
    if (opacidad <= 0) return;
    canvas.drawCircle(
      _centro,
      radio * escala,
      Paint()
        ..color = ColoresApp.secundario.withValues(
          alpha: opacidadBase * opacidad,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = grosor * escala,
    );
  }

  void _dibujarPupila(Canvas canvas) {
    final opacidad = LineaDeTiempo.valorEn(progreso, _opacidadPupila);
    if (opacidad <= 0) return;

    final escala = LineaDeTiempo.valorEn(progreso, _escalaPupila);
    canvas.drawCircle(
      _centro + mirada,
      27.5 * escala,
      Paint()..color = ColoresApp.secundario.withValues(alpha: opacidad),
    );
  }

  @override
  bool shouldRepaint(PintorOjo anterior) =>
      anterior.progreso != progreso || anterior.mirada != mirada;
}
