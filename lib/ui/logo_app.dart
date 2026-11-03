import 'package:flutter/material.dart';
import 'tema.dart';

class LogoApp extends StatelessWidget {
  const LogoApp({super.key, this.tamano = 160});

  final double tamano;

  static const rutaImagen = 'assets/icon/logo_lazarillo_android.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      rutaImagen,
      width: tamano,
      height: tamano,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
      errorBuilder: (context, error, pila) =>
          Icon(Icons.accessibility_new, size: tamano, color: ColoresApp.blanco),
    );
  }
}
