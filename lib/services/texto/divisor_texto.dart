/// Parte un texto largo en trozos que el lector de voz pueda decir.
/// Android rechaza textos de más de ~4000 caracteres en una sola lectura.
abstract final class DivisorTexto {
  static List<String> dividir(String texto, {int maximo = 1500}) {
    // Se corta al final de cada frase o línea, para no partir a media frase.
    final frases = texto.split(RegExp(r'(?<=[.!?\n])\s+'));
    final trozos = <String>[];
    final actual = StringBuffer();

    void cerrarTrozo() {
      final trozo = actual.toString().trim();
      if (trozo.isNotEmpty) trozos.add(trozo);
      actual.clear();
    }

    for (final frase in frases) {
      for (final parte in _partirSiEsLarga(frase.trim(), maximo)) {
        if (actual.length + parte.length + 1 > maximo) cerrarTrozo();
        actual
          ..write(parte)
          ..write(' ');
      }
    }
    cerrarTrozo();
    return trozos;
  }

  /// Una "frase" sin puntos (por ejemplo, una lista) se corta por espacios.
  static Iterable<String> _partirSiEsLarga(String frase, int maximo) sync* {
    var resto = frase;
    while (resto.length > maximo) {
      var corte = resto.lastIndexOf(' ', maximo);
      if (corte <= 0) corte = maximo;
      yield resto.substring(0, corte);
      resto = resto.substring(corte).trimLeft();
    }
    if (resto.isNotEmpty) yield resto;
  }
}
