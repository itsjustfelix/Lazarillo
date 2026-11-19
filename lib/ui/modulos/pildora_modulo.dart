import 'dart:ui';

import 'package:flutter/material.dart';

import '../tema.dart';

/// Indicador flotante del módulo activo. El cristal deja ver la cámara:
/// no es un botón y no cambia la navegación táctil de los tres módulos.
class PildoraModulo extends StatelessWidget {
  const PildoraModulo({
    super.key,
    required this.texto,
    required this.icono,
  });

  final String texto;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final anchoDisponible = MediaQuery.sizeOf(context).width - 132;
    final radio = BorderRadius.circular(100);

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: anchoDisponible > 128 ? anchoDisponible.clamp(128.0, 300.0) : 128,
            ),
            child: Semantics(
              label: 'Módulo actual: $texto',
              child: Container(
                height: 55,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: radio,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x59000000),
                      blurRadius: 22,
                      offset: Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 7,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: radio,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: ColoresApp.desenfoqueCristal,
                      sigmaY: ColoresApp.desenfoqueCristal,
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: radio,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              stops: const [0, 0.42, 1],
                              colors: [
                                ColoresApp.blanco.withValues(
                                  alpha: ColoresApp.tintePildoraCristal,
                                ),
                                ColoresApp.blanco.withValues(
                                  alpha: ColoresApp.tintePildoraCristal * 0.45,
                                ),
                                ColoresApp.negroCristal.withValues(alpha: 0.035),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: IgnorePointer(
                            child: Container(
                              height: 24,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(100),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    ColoresApp.negroCristal.withValues(alpha: 0.07),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: ExcludeSemantics(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 240),
                              child: Row(
                                key: ValueKey(texto),
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    icono,
                                    size: 23,
                                    color: ColoresApp.contenidoSobreCamara,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        texto,
                                        maxLines: 1,
                                        style: const TextStyle(
                                          fontFamily: 'Sora',
                                          color: ColoresApp.contenidoSobreCamara,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black54,
                                              blurRadius: 7,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
