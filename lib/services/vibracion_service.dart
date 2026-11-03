import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Vibra para avisar a la persona (por ejemplo: "ya puedes hablar").
class VibracionService {
  /// Cada vez que se empieza o se corta una secuencia de pulsos, este número
  /// sube. Cada secuencia recuerda el suyo y se detiene sola cuando ya no
  /// coincide: así [detener] corta bien aunque enseguida se empiece otra.
  int _turno = 0;

  /// Vibra una vez. Usa el motor de vibración directamente, sin depender del
  /// ajuste "vibración al tocar" del teléfono (del que sí depende
  /// HapticFeedback). Si el paquete falla, prueba con el aviso del sistema.
  Future<void> avisar({
    Duration duracion = const Duration(milliseconds: 300),
  }) async {
    try {
      if (await Vibration.hasVibrator() == true) {
        await Vibration.vibrate(duration: duracion.inMilliseconds);
        return;
      }
    } catch (_) {
      // Se prueba con el aviso del sistema.
    }
    await HapticFeedback.heavyImpact();
  }

  /// Vibra varios golpecitos suaves y seguidos: "pum, pum, pum, pum".
  ///
  /// - [pulsos]: cuántos golpecitos da.
  /// - [duracionPulso]: lo que dura cada uno (corto = más seco y suave).
  /// - [pausa]: el silencio entre un golpecito y el siguiente.
  /// - [intensidad]: de 1 (casi no se siente) a 255 (la más fuerte). Para
  ///   que sea suave, deja un valor bajo.
  ///
  /// Termina cuando suena el último pulso, o antes si se llama a [detener].
  Future<void> pulsar({
    int pulsos = 4,
    Duration duracionPulso = const Duration(milliseconds: 60),
    Duration pausa = const Duration(milliseconds: 140),
    int intensidad = 80,
  }) async {
    final miTurno = ++_turno;
    try {
      final amplitud = await _amplitudParaUsar(intensidad);
      if (amplitud == null) {
        await HapticFeedback.lightImpact();
        return;
      }

      for (var i = 0; i < pulsos; i++) {
        if (miTurno != _turno) return;
        await Vibration.vibrate(
          duration: duracionPulso.inMilliseconds,
          amplitude: amplitud,
        );
        final esUltimo = i == pulsos - 1;
        await Future<void>.delayed(
          esUltimo ? duracionPulso : duracionPulso + pausa,
        );
      }
    } catch (_) {
      await HapticFeedback.lightImpact();
    }
  }

  Future<void> pulsarEnEspera({
    Duration duracionPulso = const Duration(milliseconds: 60),
    Duration pausa = const Duration(milliseconds: 550),
    int intensidad = 10,
  }) async {
    final miTurno = ++_turno;
    try {
      final amplitud = await _amplitudParaUsar(intensidad);
      if (amplitud == null) return;

      while (miTurno == _turno) {
        await Vibration.vibrate(
          duration: duracionPulso.inMilliseconds,
          amplitude: amplitud,
        );
        await Future<void>.delayed(duracionPulso + pausa);
      }
    } catch (_) {
      // Es solo un acompañamiento de la espera: si falla, no se hace nada.
    }
  }

  /// Corta los pulsos que estén sonando ([pulsar] o [pulsarEnEspera]).
  /// Se puede llamar aunque no haya nada vibrando.
  Future<void> detener() async {
    _turno++;
    try {
      await Vibration.cancel();
    } catch (_) {}
  }

  Future<int?> _amplitudParaUsar(int intensidad) async {
    if (await Vibration.hasVibrator() != true) return null;
    final controlaIntensidad = await Vibration.hasAmplitudeControl() == true;
    return controlaIntensidad ? intensidad.clamp(1, 255).toInt() : -1;
  }
}
