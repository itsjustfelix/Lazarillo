import 'dart:ui' show Rect;

enum PosicionHorizontal {
  izquierda('a tu izquierda'),
  centro('al frente'),
  derecha('a tu derecha');

  const PosicionHorizontal(this.texto);
  final String texto;
}

enum Cercania {
  muyCerca('muy cerca'),
  cerca('cerca'),
  lejos('lejos');

  const Cercania(this.texto);
  final String texto;
}

/// Esste modelo representa un objeto detectado en la imagen, con su clase,
///  etiqueta, confianza y caja delimitadora normalizada.
class Deteccion {
  const Deteccion({
    required this.claseId,
    required this.etiqueta,
    required this.confianza,
    required this.caja,
  });

  final int claseId;
  final String etiqueta;
  final double confianza;

  /// Caja normalizada: todos los valores van de 0 a 1 respecto a la imagen.
  final Rect caja;

  PosicionHorizontal get posicion {
    final x = caja.center.dx;
    if (x < 0.4) return PosicionHorizontal.izquierda;
    if (x > 0.6) return PosicionHorizontal.derecha;
    return PosicionHorizontal.centro;
  }

  /// Estimación burda: un objeto que ocupa mucha imagen está más cerca.
  /// Depende del tamaño real del objeto, así que es solo una pista.
  Cercania get cercania {
    final area = caja.width * caja.height;
    if (area > 0.25) return Cercania.muyCerca;
    if (area > 0.06) return Cercania.cerca;
    return Cercania.lejos;
  }

  /// Frase lista para leer en voz alta. Ej: "botella a tu izquierda, cerca".
  String get descripcionHablada =>
      '$etiqueta ${posicion.texto}, ${cercania.texto}';
}
