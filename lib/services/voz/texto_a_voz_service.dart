import 'package:flutter_tts/flutter_tts.dart';

import '../texto/divisor_texto.dart';

/// Lee texto en voz alta.
class TextoAVozService {
  TextoAVozService([FlutterTts? tts]) : _tts = tts ?? FlutterTts();

  static const _idiomasPreferidos = ['es-CO', 'es-MX', 'es-US', 'es-ES'];

  final FlutterTts _tts;
  bool _lecturaCancelada = false;

  /// Llamar una vez antes de usar [hablar].
  /// [velocidad]: 0.0 a 1.0 (0.5 es normal). Muchas personas ciegas
  /// prefieren más rápido; conviene dejarlo configurable.
  Future<void> iniciar({double velocidad = 0.5}) async {
    // Hace que hablar() termine cuando acaba de hablar, no cuando empieza.
    await _tts.awaitSpeakCompletion(true);
    await _tts.setLanguage(await _elegirIdioma());
    await _tts.setSpeechRate(velocidad);
    await _tts.setPitch(1.0);
  }

  /// Si [interrumpir] es true, corta lo que esté diciendo y dice esto.
  Future<void> hablar(String texto, {bool interrumpir = true}) async {
    if (texto.trim().isEmpty) return;
    if (interrumpir) {
      _lecturaCancelada = true; // también corta una lectura larga en curso
      await _tts.stop();
    }
    await _tts.speak(texto);
  }

  /// Lee un texto largo por partes. Termina al acabar el texto o cuando
  /// alguien llama a [detener] u [hablar].
  Future<void> leerTextoLargo(String texto) async {
    await _tts.stop();
    _lecturaCancelada = false;

    for (final trozo in DivisorTexto.dividir(texto)) {
      if (_lecturaCancelada) return;
      await _tts.speak(trozo);
    }
  }

  Future<void> detener() {
    _lecturaCancelada = true;
    return _tts.stop();
  }

  Future<String> _elegirIdioma() async {
    for (final idioma in _idiomasPreferidos) {
      final disponible = await _tts.isLanguageAvailable(idioma);
      if (disponible == true || disponible == 1) return idioma;
    }
    return 'es-ES';
  }
}
