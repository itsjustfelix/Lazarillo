import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Vibra para avisar a la persona (por ejemplo: "ya puedes hablar").
class VibracionService {
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
}
