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
  bool _listo = false;
  String? _idioma;

  /// Lo último que se entendió, aunque todavía no sea el resultado final.
  String _ultimasPalabras = '';

  /// Último error que reportó el motor de voz (null si no hubo).
  String? _errorDeEscucha;

  DateTime _inicioEscucha = DateTime.fromMillisecondsSinceEpoch(0);

  /// Pide el permiso de micrófono y prepara el reconocimiento.
  Future<void> iniciar() async {
    if (_listo) return;

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

  /// Escucha durante una ventana FIJA y devuelve lo que se dijo en ella.
  ///
  /// Secuencia: [esperaAntes] -> se abre el micrófono (se llama a [alAbrir])
  /// -> se escucha exactamente [ventana] -> se cierra el micrófono -> se
  /// devuelve lo entendido. Si no se dijo nada, devuelve texto vacío.
  ///
  /// A diferencia de [escuchar], no termina antes aunque la persona calle o
  /// el motor crea que ya acabó: siempre se espera la ventana completa.
  Future<String> escucharVentana({
    Duration ventana = const Duration(seconds: 3),
    Duration esperaAntes = const Duration(milliseconds: 250),
    VoidCallback? alAbrir,
  }) async {
    await iniciar();
    // Pausa corta para no captar la cola de la voz de la propia app.
    await Future<void>.delayed(esperaAntes);

    _pendiente = null; // aquí no se espera un Completer: se espera la ventana
    _ultimasPalabras = '';
    _errorDeEscucha = null;
    _inicioEscucha = DateTime.now();

    await _stt.listen(
      localeId: _idioma,
      // El micrófono lo cierra esta función al acabar la ventana, no el
      // motor: por eso se le da un margen mayor, para que no corte antes.
      listenFor: ventana + const Duration(seconds: 2),
      pauseFor: ventana + const Duration(seconds: 2),
      listenOptions: SpeechListenOptions(
        partialResults: true, // se guarda lo que se va entendiendo
        cancelOnError: true,
      ),
      onResult: (resultado) {
        _ultimasPalabras = resultado.recognizedWords;
        debugPrint(
          'Voz: "${resultado.recognizedWords}" '
          '(final: ${resultado.finalResult})',
        );
      },
    );
    alAbrir?.call(); // aviso de "ya puedes hablar" (por ejemplo, vibración)

    await Future<void>.delayed(ventana);
    await _stt.stop();
    // El resultado final llega un instante después de pedir que se detenga.
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final palabras = _ultimasPalabras.trim();
    if (palabras.isEmpty && _esErrorReal(_errorDeEscucha)) {
      throw const VozException('No pude usar el micrófono. Intenta de nuevo.');
    }
    return palabras;
  }

  /// Escucha una frase y termina cuando el motor decide que acabó.
  /// Devuelve texto vacío si no oyó nada.
  ///
  /// [esperaAntes]: pausa antes de abrir el micrófono.
  /// [maximo]: duración máxima de la escucha.
  /// [pausaParaTerminar]: silencio que se tolera antes de darse por vencido.
  Future<String> escuchar({
    Duration esperaAntes = const Duration(milliseconds: 800),
    Duration maximo = const Duration(seconds: 10),
    Duration pausaParaTerminar = const Duration(seconds: 4),
  }) async {
    await iniciar();
    await Future<void>.delayed(esperaAntes);

    _ultimasPalabras = '';
    final pendiente = _pendiente = Completer<String>();
    _inicioEscucha = DateTime.now();

    await _stt.listen(
      localeId: _idioma,
      listenFor: maximo,
      pauseFor: pausaParaTerminar,
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
      onResult: (resultado) {
        _ultimasPalabras = resultado.recognizedWords;
        debugPrint(
          'Voz: "${resultado.recognizedWords}" '
          '(final: ${resultado.finalResult})',
        );
        if (resultado.finalResult) _completar(pendiente, _ultimasPalabras);
      },
    );

    // Red de seguridad por si ningún evento llega a avisar.
    return pendiente.future.timeout(
      maximo + const Duration(seconds: 3),
      onTimeout: () {
        _stt.stop();
        return _ultimasPalabras.trim();
      },
    );
  }

  Future<void> cancelar() => _stt.cancel();

  void _alCambiarEstado(String estado) {
    debugPrint('Voz: estado "$estado"');
    if (estado != SpeechToText.doneStatus) return;

    // Un "done" justo al abrir el micrófono es residuo de la sesión anterior.
    final desdeElInicio = DateTime.now().difference(_inicioEscucha);
    if (desdeElInicio < const Duration(milliseconds: 500)) return;

    // Margen por si el resultado final llega un instante después del aviso.
    final pendiente = _pendiente;
    Future<void>.delayed(
      const Duration(milliseconds: 400),
      () => _completar(pendiente, _ultimasPalabras),
    );
  }

  void _alFallar(String mensaje) {
    debugPrint('Voz: error "$mensaje"');
    _errorDeEscucha = mensaje;

    final pendiente = _pendiente;
    if (pendiente == null || pendiente.isCompleted) return;

    // Silencio o nada entendido: no es un fallo, solo no se oyó nada.
    if (!_esErrorReal(mensaje)) {
      _completar(pendiente, _ultimasPalabras);
    } else {
      pendiente.completeError(
        const VozException('No pude usar el micrófono. Intenta de nuevo.'),
      );
    }
  }

  /// "no_match" y "speech_timeout" solo significan que no se oyó nada.
  bool _esErrorReal(String? mensaje) =>
      mensaje != null &&
      !mensaje.contains('no_match') &&
      !mensaje.contains('speech_timeout');

  void _completar(Completer<String>? pendiente, String texto) {
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
    return null; // usa el idioma del teléfono
  }
}
