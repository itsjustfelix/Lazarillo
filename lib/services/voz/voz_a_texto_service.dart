import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VozException implements Exception {
  const VozException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Convierte lo que dice la persona en texto.
class VozATextoService {
  VozATextoService([SpeechToText? stt]) : _stt = stt ?? SpeechToText();

  final SpeechToText _stt;
  Completer<String>? _pendiente;
  Timer? _timerLimite;
  bool _listo = false;
  String? _idioma;

  String _ultimasPalabras = '';

  /// Pide el permiso de micrófono y prepara el reconocimiento.
  Future<void> iniciar() async {
    if (_listo && _stt.isAvailable) return;

    _listo = await _stt.initialize(
      onError: (error) => _alFallar(error.errorMsg),
      onStatus: _alCambiarEstado,
    );
    if (!_listo) {
      throw const VozException(
        'No tengo permiso para usar el micrófono o este teléfono no '
        'tiene reconocimiento de voz.',
      );
    }
    _idioma = await _elegirIdiomaEspanol();
    debugPrint('Voz: idioma de reconocimiento = $_idioma');
  }

  /// Escucha una frase y devuelve lo que entendió.
  /// Devuelve texto vacío si no oyó nada tras los 3 segundos.
  Future<String> escuchar() async {
    await iniciar();

    // Limpiar cualquier sesión anterior que haya quedado colgada
    if (_stt.isListening) {
      await _stt.stop();
      await Future.delayed(const Duration(milliseconds: 200));
    }

    _ultimasPalabras = '';
    final pendiente = _pendiente = Completer<String>();

    // Escuchar limpio (deja que Android use los defaults nativos del micro)
    await _stt.listen(
      onResult: (resultado) {
        _ultimasPalabras = resultado.recognizedWords;
        debugPrint(
          'Voz: "${resultado.recognizedWords}" '
          '(final: ${resultado.finalResult})',
        );
        if (resultado.finalResult) {
          _completar(pendiente, _ultimasPalabras);
        }
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
      ),
    );

    // Temporizador de 3 segundos exactos controlado por Flutter
    _timerLimite?.cancel();
    _timerLimite = Timer(const Duration(seconds: 3), () async {
      if (!pendiente.isCompleted) {
        await _stt.stop();
        _completar(pendiente, _ultimasPalabras);
      }
    });

    return pendiente.future;
  }

  Future<void> detener() async {
    _timerLimite?.cancel();
    if (_stt.isListening) {
      await _stt.stop();
    }
  }

  Future<void> cancelar() async {
    _timerLimite?.cancel();
    await _stt.cancel();
  }

  void _alCambiarEstado(String estado) {
    debugPrint('Voz: estado "$estado"');
    // Si el estado indica que el micrófono se apagó (por pausa o tiempo)
    if (estado == SpeechToText.doneStatus ||
        estado == SpeechToText.notListeningStatus) {
      final pendiente = _pendiente;
      // Pequeño margen por si el último fragmento de voz viene en camino
      Future.delayed(
        const Duration(milliseconds: 200),
        () => _completar(pendiente, _ultimasPalabras),
      );
    }
  }

  void _alFallar(String mensaje) {
    debugPrint('Voz: error nativo "$mensaje"');
    final pendiente = _pendiente;
    if (pendiente == null || pendiente.isCompleted) return;

    // Solo se lanza excepción si falla el hardware/permisos.
    // Si es silencio, timeout o no-match, se trata como respuesta vacía.
    final esErrorHardware =
        mensaje.toLowerCase().contains('permission') ||
        mensaje.toLowerCase().contains('insufficient');

    if (esErrorHardware) {
      pendiente.completeError(
        const VozException('No pude usar el micrófono. Intenta de nuevo.'),
      );
    } else {
      _completar(pendiente, _ultimasPalabras);
    }
  }

  void _completar(Completer<String>? pendiente, String texto) {
    _timerLimite?.cancel();
    if (pendiente != null && !pendiente.isCompleted) {
      pendiente.complete(texto.trim());
    }
  }

  Future<String?> _elegirIdiomaEspanol() async {
    final idiomas = await _stt.locales();
    String limpiar(String id) => id.replaceAll('-', '_').toLowerCase();

    for (final preferido in ['es_co', 'es_mx', 'es_us', 'es_es']) {
      for (final idioma in idiomas) {
        if (limpiar(idioma.localeId) == preferido) return idioma.localeId;
      }
    }
    for (final idioma in idiomas) {
      if (limpiar(idioma.localeId).startsWith('es')) return idioma.localeId;
    }
    return null;
  }
}
