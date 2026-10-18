import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class TextoException implements Exception {
  const TextoException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Extrae el texto de una foto con Google ML Kit (en el teléfono, sin internet).
class ReconocedorTextoService {
  ReconocedorTextoService([TextRecognizer? reconocedor])
    : _reconocedor =
          reconocedor ?? TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _reconocedor;

  // Palabra cortada con guion al final de una línea: "pala-\nbra" -> "palabra".
  static final _guionDeFinDeLinea = RegExp(
    r'(?<=\p{L})-\n(?=\p{L})',
    unicode: true,
  );
  static final _saltoDeLinea = RegExp(r'\s*\n\s*');
  static final _terminaEnPuntuacion = RegExp(r'[.!?:;]$');

  /// Devuelve el texto de la foto, o una cadena vacía si no encontró nada.
  Future<String> extraerDeArchivo(String rutaFoto) async {
    final RecognizedText resultado;
    try {
      resultado = await _reconocedor.processImage(
        InputImage.fromFilePath(rutaFoto),
      );
    } catch (error) {
      debugPrint('ML Kit: $error');
      throw const TextoException('No pude analizar la imagen.');
    }
    return _armarTexto(resultado);
  }

  Future<void> cerrar() => _reconocedor.close();

  /// ML Kit separa el texto en bloques (más o menos, párrafos). Cada bloque
  /// se une en una sola línea y se separa del siguiente, para que la voz
  /// lea con pausas naturales y no con cada salto de renglón.
  String _armarTexto(RecognizedText reconocido) {
    final parrafos = reconocido.blocks
        .map((bloque) => _limpiarBloque(bloque.text))
        .where((parrafo) => parrafo.isNotEmpty);
    return parrafos.join('\n');
  }

  String _limpiarBloque(String texto) {
    final unido = texto
        .replaceAll(_guionDeFinDeLinea, '')
        .replaceAll(_saltoDeLinea, ' ')
        .trim();
    if (unido.isEmpty) return '';
    // Un título sin punto se leería pegado al párrafo siguiente.
    return _terminaEnPuntuacion.hasMatch(unido) ? unido : '$unido.';
  }
}
