enum TipoInstruccion {
  noLoVeo,
  girarIzquierda,
  girarDerecha,
  alFrenteLejos,
  alFrenteCerca,
  alFrenteMuyCerca,
  encontrado,
}

/// Una indicación lista para leer en voz alta.
class Instruccion {
  const Instruccion(this.tipo, this.texto);

  final TipoInstruccion tipo;
  final String texto;
}
