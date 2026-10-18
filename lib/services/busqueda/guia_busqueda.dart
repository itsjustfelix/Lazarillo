import '../../models/deteccion.dart';
import '../../models/instruccion.dart';

/// Decide QUÉ decir y CUÁNDO, a partir de lo que ve la cámara.
/// No usa cámara, modelo ni voz: solo recibe detecciones y devuelve
/// instrucciones. Por eso se puede probar fácilmente.
///
/// Dos problemas que resuelve:
///  - Parpadeo: el modelo falla en algún fotograma suelto. Una instrucción
///    solo se da cuando se repite varios fotogramas seguidos.
///  - Exceso de voz: no repite lo mismo a cada rato, solo cuando cambia
///    la situación o pasa un tiempo prudente.
class GuiaBusqueda {
  GuiaBusqueda({
    required this.nombreObjeto,
    this.confirmaciones = 2,
    this.fotogramasParaPerder = 4,
    this.confirmacionesParaEncontrar = 3,
    this.pausaMinima = const Duration(milliseconds: 1500),
    this.repetirCada = const Duration(seconds: 4),
    this.repetirNoLoVeoCada = const Duration(seconds: 6),
  });

  final String nombreObjeto;
  final int confirmaciones;
  final int fotogramasParaPerder;
  final int confirmacionesParaEncontrar;
  final Duration pausaMinima;
  final Duration repetirCada;
  final Duration repetirNoLoVeoCada;

  TipoInstruccion? _candidato;
  int _repeticiones = 0;
  int _fotogramasSinVerlo = 0;
  TipoInstruccion? _ultimoDicho;
  DateTime? _ultimaVez;
  bool _terminado = false;

  /// true cuando la persona ya llegó al objeto.
  bool get terminado => _terminado;

  /// [deteccion]: el objeto buscado en este fotograma, o null si no apareció.
  /// Devuelve una instrucción solo si hay algo nuevo que decir.
  Instruccion? evaluar(Deteccion? deteccion, DateTime ahora) {
    if (_terminado) return null;

    final observado = _observar(deteccion);
    if (observado == null) return null;

    _contar(observado);

    if (observado == TipoInstruccion.alFrenteMuyCerca &&
        _repeticiones >= confirmacionesParaEncontrar) {
      _terminado = true;
      return _instruccion(TipoInstruccion.encontrado);
    }
    if (_repeticiones < confirmaciones) return null;
    if (!_tocaHablar(observado, ahora)) return null;

    _ultimoDicho = observado;
    _ultimaVez = ahora;
    return _instruccion(observado);
  }

  /// Qué situación se observa en este fotograma (null = aún no se sabe).
  TipoInstruccion? _observar(Deteccion? deteccion) {
    if (deteccion == null) {
      _fotogramasSinVerlo++;
      // Un fallo suelto no significa que se perdió el objeto.
      return _fotogramasSinVerlo >= fotogramasParaPerder
          ? TipoInstruccion.noLoVeo
          : null;
    }
    _fotogramasSinVerlo = 0;
    return _clasificar(deteccion);
  }

  TipoInstruccion _clasificar(Deteccion d) {
    switch (d.posicion) {
      case PosicionHorizontal.izquierda:
        return TipoInstruccion.girarIzquierda;
      case PosicionHorizontal.derecha:
        return TipoInstruccion.girarDerecha;
      case PosicionHorizontal.centro:
        return switch (d.cercania) {
          Cercania.lejos => TipoInstruccion.alFrenteLejos,
          Cercania.cerca => TipoInstruccion.alFrenteCerca,
          Cercania.muyCerca => TipoInstruccion.alFrenteMuyCerca,
        };
    }
  }

  void _contar(TipoInstruccion observado) {
    if (observado == _candidato) {
      _repeticiones++;
    } else {
      _candidato = observado;
      _repeticiones = 1;
    }
  }

  bool _tocaHablar(TipoInstruccion observado, DateTime ahora) {
    final ultima = _ultimaVez;
    if (ultima == null) return true;

    final transcurrido = ahora.difference(ultima);
    if (transcurrido < pausaMinima) return false;

    final cambioLaSituacion = observado != _ultimoDicho;
    final intervalo = observado == TipoInstruccion.noLoVeo
        ? repetirNoLoVeoCada
        : repetirCada;
    return cambioLaSituacion || transcurrido >= intervalo;
  }

  Instruccion _instruccion(TipoInstruccion tipo) {
    final texto = switch (tipo) {
      TipoInstruccion.noLoVeo => 'No veo $nombreObjeto. Gira despacio.',
      TipoInstruccion.girarIzquierda => 'Gira un poco a la izquierda.',
      TipoInstruccion.girarDerecha => 'Gira un poco a la derecha.',
      TipoInstruccion.alFrenteLejos => 'Está al frente. Avanza con cuidado.',
      TipoInstruccion.alFrenteCerca => 'Está al frente, ya estás cerca.',
      TipoInstruccion.alFrenteMuyCerca =>
        'Lo tienes justo enfrente. Extiende la mano.',
      TipoInstruccion.encontrado => 'Listo, encontraste $nombreObjeto.',
    };
    return Instruccion(tipo, texto);
  }
}
