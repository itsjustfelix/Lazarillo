import 'package:flutter/material.dart';

/// Todos los colores de Lazarillo, tomados del logo.
///
/// Regla de la app: ningún archivo escribe un color a mano. Si necesita uno,
/// lo pide aquí (ColoresApp) o lo hereda del tema (TemaApp). Así, cambiar un
/// color en este archivo lo cambia en toda la app.
class ColoresApp {
  ColoresApp._(); // solo guarda constantes: no se crea con ColoresApp()

  // ---- Paleta del logo ----
  static const primario = Color(0xFF391894); // el color principal del logo
  static const secundario = Color(0xFF387EF5); // el color secundario del logo
  static const blanco = Color(0xFFFFFFFF);

  // ---- Apoyo (no vienen del logo) ----
  /// Errores. Se muestran dentro de una caja blanca, donde este rojo oscuro
  /// se lee bien (sobre el morado casi no se vería).
  static const error = Color(0xFFB3261E);

  // ---- Elementos que se dibujan ENCIMA de la cámara ----
  /// Fondo mientras la cámara carga o cuando no hay imagen.
  static const fondoCamara = Color(0xFF000000);

  /// Píldora y logo del perfil: el color principal, con 85 % de opacidad
  /// (D9 en hexadecimal) para que se note la cámara debajo pero el texto
  /// se lea.
  static const fondoSobreCamara = Color(0xD9391894);

  /// Borde fino que separa píldora y logo de la imagen de la cámara.
  static const bordeSobreCamara = secundario;

  /// Texto e íconos sobre la píldora y el logo.
  static const contenidoSobreCamara = blanco;

  /// Cuadro de texto técnico que se muestra sobre la cámara (errores para
  /// quien desarrolla). Negro al 80 % (CC en hexadecimal).
  static const fondoMensaje = Color(0xCC000000);

  // ---- Marca de Google (solo para dibujar la G del botón de login) ----
  static const googleAzul = Color(0xFF4285F4);
  static const googleRojo = Color(0xFFEA4335);
  static const googleAmarillo = Color(0xFFFBBC05);
  static const googleVerde = Color(0xFF34A853);
}

/// El tema de toda la app. Se entrega a MaterialApp una sola vez (en app.dart)
/// y de ahí lo heredan los botones, el Scaffold, los indicadores de carga...
/// sin que cada pantalla tenga que pintarlos.
///
/// Las pantallas con formularios (login y perfil) llevan el color principal
/// de fondo y letras blancas: por eso el esquema es "oscuro" (fondo oscuro,
/// contenido claro), como el modo oscuro de Material.
class TemaApp {
  TemaApp._();

  /// Se define el ColorScheme completo a mano y no con fromSeed: fromSeed
  /// inventa tonos parecidos y los colores del logo no saldrían exactos.
  ///
  /// Ojo con `primary: blanco`: en un fondo oscuro, lo que Material llama
  /// "primario" (cursor, foco, indicadores) debe ser claro para verse. El
  /// color de marca va de fondo (`surface`).
  static const _esquema = ColorScheme(
    brightness: Brightness.dark,
    primary: ColoresApp.blanco,
    onPrimary: ColoresApp.primario, // lo que va encima de lo "primario"
    secondary: ColoresApp.secundario,
    onSecondary: ColoresApp.blanco,
    error: ColoresApp.error,
    onError: ColoresApp.blanco,
    surface: ColoresApp.primario,
    onSurface: ColoresApp.blanco,
  );

  static final ThemeData claro = ThemeData(
    useMaterial3: true,
    colorScheme: _esquema,
    scaffoldBackgroundColor: ColoresApp.primario,

    // Botón principal: relleno blanco con texto del color principal
    // (contraste de 12 a 1; el mejor de la paleta).
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColoresApp.blanco,
        foregroundColor: ColoresApp.primario,
      ),
    ),

    // Botón secundario: contorno y texto blancos.
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ColoresApp.blanco,
        side: const BorderSide(color: ColoresApp.blanco, width: 2),
      ),
    ),

    // Indicadores de carga blancos: se ven sobre el morado y sobre la cámara.
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: ColoresApp.blanco,
    ),
  );
}
