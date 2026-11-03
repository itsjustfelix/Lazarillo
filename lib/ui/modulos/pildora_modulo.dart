import 'package:flutter/material.dart';

import '../tema.dart';

/// La píldora fija de arriba: muestra el nombre del módulo actual.
///
/// No pertenece a ninguna pantalla: la dibuja ModulosView encima de todas,
/// por eso no se mueve cuando se desliza entre módulos; solo cambia el texto.
class PildoraModulo extends StatelessWidget {
  const PildoraModulo({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            decoration: BoxDecoration(
              color: ColoresApp.fondoSobreCamara,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: ColoresApp.bordeSobreCamara),
            ),
            // El texto cambia con un fundido suave al deslizar.
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                texto,
                key: ValueKey(texto),
                style: const TextStyle(
                  color: ColoresApp.contenidoSobreCamara,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
