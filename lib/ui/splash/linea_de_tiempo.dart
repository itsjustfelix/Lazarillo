import 'package:flutter/animation.dart';

/// Un punto fijo de una animación: en el instante [t] (de 0 a 1) el valor
/// es [valor]. [curva] describe cómo se viaja desde este punto hasta el
/// SIGUIENTE (igual que `animation-timing-function` en CSS).
class Fotograma {
  const Fotograma(this.t, this.valor, [this.curva = Curves.linear]);

  final double t;
  final double valor;
  final Curve curva;
}

/// Calcula el valor de una propiedad en un instante, interpolando entre
/// fotogramas. Así cada propiedad (escala de un aro, opacidad de la pupila,
/// curvatura de un párpado) se describe con una lista corta y legible, en
/// lugar de una cadena de if.
abstract final class LineaDeTiempo {
  static double valorEn(double t, List<Fotograma> fotogramas) {
    if (t <= fotogramas.first.t) return fotogramas.first.valor;

    for (var i = 0; i < fotogramas.length - 1; i++) {
      final desde = fotogramas[i];
      final hasta = fotogramas[i + 1];
      if (t <= hasta.t) {
        final avance = (t - desde.t) / (hasta.t - desde.t);
        final suavizado = desde.curva.transform(avance);
        return desde.valor + (hasta.valor - desde.valor) * suavizado;
      }
    }
    return fotogramas.last.valor; // la animación ya terminó: se queda aquí
  }
}
