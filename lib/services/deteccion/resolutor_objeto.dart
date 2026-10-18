import '../../core/etiquetas_coco.dart';

/// Convierte lo que dijo la persona ("busca mi celular") en un id de clase.
abstract final class ResolutorObjeto {
  static final List<_Patron> _patrones = _construirPatrones();

  /// Devuelve el id de clase o null si no reconoce ningún objeto.
  static int? claseDesdeFrase(String frase) {
    final texto = _sinTildes(frase.toLowerCase());
    for (final patron in _patrones) {
      if (patron.regex.hasMatch(texto)) return patron.claseId;
    }
    return null;
  }

  static List<_Patron> _construirPatrones() {
    final entradas = <String, int>{
      for (var i = 0; i < EtiquetasCoco.espanol.length; i++)
        _sinTildes(EtiquetasCoco.espanol[i]): i,
      ...EtiquetasCoco.sinonimos,
    };

    // Las frases más largas primero: "perro caliente" gana sobre "perro".
    final ordenadas = entradas.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));

    return [
      for (final e in ordenadas)
        // \b evita que "oso" coincida dentro de "esposo"; s? admite plural.
        _Patron(RegExp('\\b${RegExp.escape(e.key)}s?\\b'), e.value),
    ];
  }

  static String _sinTildes(String texto) {
    const con = 'áéíóúü';
    const sin = 'aeiouu';
    var resultado = texto;
    for (var i = 0; i < con.length; i++) {
      resultado = resultado.replaceAll(con[i], sin[i]);
    }
    return resultado;
  }
}

class _Patron {
  const _Patron(this.regex, this.claseId);
  final RegExp regex;
  final int claseId;
}
