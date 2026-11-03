import 'package:flutter/material.dart';
import '../tema.dart';

/// El logo fijo de la esquina superior izquierda: al mantenerlo presionado
/// se abre el perfil.
///
/// Igual que la píldora, no pertenece a ningún módulo: lo dibuja ModulosView
/// encima de todos. Se abre con pulsación larga (y no con un toque) para que
/// nadie entre al perfil, y menos cierre sesión, sin querer.
class LogoPerfil extends StatelessWidget {
  const LogoPerfil({
    super.key,
    required this.alMantener,
    required this.fotoUrl,
  });

  /// Se ejecuta al mantener presionado el logo (abrir el perfil).
  final VoidCallback alMantener;
  final Future<String?>? fotoUrl;

  /// 48 es el tamaño mínimo recomendado para un objetivo táctil.
  static const _tamano = 48.0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.only(top: 12, left: 12),
          // Una sola etiqueta para el lector de pantalla; excludeSemantics
          // evita que el ícono de adentro se anuncie por separado.
          child: Semantics(
            button: true,
            label: 'Perfil',
            hint: 'Mantén presionado para abrir',
            onLongPress: alMantener,
            excludeSemantics: true,
            child: GestureDetector(
              onLongPress: alMantener,
              child: Container(
                width: _tamano,
                height: _tamano,
                decoration: BoxDecoration(
                  color: const Color(0x99000000),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: fotoUrl != null
                    ? FutureBuilder<String?>(
                        future: fotoUrl,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError ||
                              snapshot.data == null ||
                              snapshot.data!.isEmpty) {
                            return const Icon(
                              Icons.person_outline,
                              color: ColoresApp.contenidoSobreCamara,
                              size: 28,
                            );
                          } else {
                            return ClipOval(
                              child: Image.network(
                                snapshot.data!,
                                fit: BoxFit.cover,
                                width: _tamano,
                                height: _tamano,
                              ),
                            );
                          }
                        },
                      )
                    : const Icon(
                        Icons.person_outline,
                        color: ColoresApp.contenidoSobreCamara,
                        size: 28,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
