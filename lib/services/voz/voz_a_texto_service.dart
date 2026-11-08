import 'dart:async';
import 'dart:ui';

import 'package:speech_to_text/speech_to_text.dart';

class VozException implements Exception {
  const VozException(this.message);
  final String message;

  @override
  String toString() => message;
}

class VozATextoService {
  VozATextoService([SpeechToText? stt]) : _stt = stt ?? SpeechToText();

  final SpeechToText _stt;
  Completer<String>? _pendiente;
  bool _listo = false;
  String? _idioma;

  String _ultimasPalabras = '';

  String? _errorDeEscucha;

  DateTime _inicioEscucha = DateTime.fromMillisecondsSinceEpoch(0);

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
  }

  Future<String> escucharVentana({
    Duration ventana = const Duration(seconds: 3),
    Duration esperaAntes = const Duration(milliseconds: 250),
    VoidCallback? alAbrir,
  }) async {
    await iniciar();

    await Future<void>.delayed(esperaAntes);

    _pendiente = null;
    _ultimasPalabras = '';
    _errorDeEscucha = null;
    _inicioEscucha = DateTime.now();

    await _stt.listen(
      listenOptions: SpeechListenOptions(
        localeId: _idioma,
        listenFor: ventana + const Duration(seconds: 2),
        pauseFor: ventana + const Duration(seconds: 2),
        partialResults: true,
        cancelOnError: true,
      ),
      onResult: (resultado) {
        _ultimasPalabras = resultado.recognizedWords;
      },
    );
    alAbrir?.call();

    await Future<void>.delayed(ventana);
    await _stt.stop();
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final palabras = _ultimasPalabras.trim();
    if (palabras.isEmpty && _esErrorReal(_errorDeEscucha)) {
      throw const VozException('No pude usar el micrófono. Intenta de nuevo.');
    }
    return palabras;
  }

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
      listenOptions: SpeechListenOptions(
        localeId: _idioma,
        listenFor: maximo,
        pauseFor: pausaParaTerminar,
        partialResults: true,
        cancelOnError: true,
      ),
      onResult: (resultado) {
        _ultimasPalabras = resultado.recognizedWords;
        if (resultado.finalResult) _completar(pendiente, _ultimasPalabras);
      },
    );

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
    if (estado != SpeechToText.doneStatus) return;

    final desdeElInicio = DateTime.now().difference(_inicioEscucha);
    if (desdeElInicio < const Duration(milliseconds: 500)) return;

    final pendiente = _pendiente;
    Future<void>.delayed(
      const Duration(milliseconds: 400),
      () => _completar(pendiente, _ultimasPalabras),
    );
  }

  void _alFallar(String mensaje) {
    _errorDeEscucha = mensaje;

    final pendiente = _pendiente;
    if (pendiente == null || pendiente.isCompleted) return;

    if (!_esErrorReal(mensaje)) {
      _completar(pendiente, _ultimasPalabras);
    } else {
      pendiente.completeError(
        const VozException('No pude usar el micrófono. Intenta de nuevo.'),
      );
    }
  }

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
    return null;
  }
}
