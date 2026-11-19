import 'dart:ui';

import 'package:flutter/material.dart';

import '../tema.dart';

/// Botón de salida con cristal rojizo. Su única responsabilidad es la vista:
/// la confirmación y el cierre de sesión viven en PerfilView.
class BotonCerrarSesionCristal extends StatefulWidget {
  const BotonCerrarSesionCristal({
    super.key,
    required this.cerrando,
    required this.alPresionar,
  });

  final bool cerrando;
  final VoidCallback alPresionar;

  @override
  State<BotonCerrarSesionCristal> createState() =>
      _BotonCerrarSesionCristalState();
}

class _BotonCerrarSesionCristalState extends State<BotonCerrarSesionCristal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulsos;

  @override
  void initState() {
    super.initState();
    _pulsos = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sincronizarAnimacion();
  }

  @override
  void didUpdateWidget(covariant BotonCerrarSesionCristal anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.cerrando != widget.cerrando) {
      _sincronizarAnimacion();
    }
  }

  void _sincronizarAnimacion() {
    final reducirMovimiento = MediaQuery.of(context).disableAnimations;
    if (widget.cerrando && !reducirMovimiento) {
      if (!_pulsos.isAnimating) _pulsos.repeat();
    } else {
      _pulsos.stop();
      _pulsos.reset();
    }
  }

  @override
  void dispose() {
    _pulsos.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radio = BorderRadius.circular(100);
    final reducirMovimiento = MediaQuery.of(context).disableAnimations;

    return Semantics(
      button: true,
      enabled: !widget.cerrando,
      liveRegion: widget.cerrando,
      label: widget.cerrando ? 'Cerrando sesión' : 'Cerrar sesión',
      onTap: widget.cerrando ? null : widget.alPresionar,
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          height: 68,
          decoration: BoxDecoration(
            borderRadius: radio,
            // Relieve sin dibujar un borde o una raya blanca.
            boxShadow: [
              BoxShadow(
                color: ColoresApp.rojoCristalSalir.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 15),
              ),
              BoxShadow(
                color: ColoresApp.primario.withValues(alpha: 0.11),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: ColoresApp.negroCristal.withValues(alpha: 0.07),
                blurRadius: 3,
                offset: const Offset(0, 2),
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
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: radio,
                  onTap: widget.cerrando ? null : widget.alPresionar,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: radio,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            stops: const [0, 0.48, 1],
                            colors: [
                              ColoresApp.rojoCristalSalir.withValues(
                                alpha: ColoresApp.tinteCristalSalir * 1.16,
                              ),
                              ColoresApp.rojoCristalSalir.withValues(
                                alpha: ColoresApp.tinteCristalSalir,
                              ),
                              ColoresApp.rojoCristalSalir.withValues(
                                alpha: ColoresApp.tinteCristalSalir * 0.75,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Sombra interior inferior: volumen sin contornos.
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          child: Container(
                            height: 28,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(100),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  ColoresApp.textoCristalSalir.withValues(
                                    alpha: 0.09,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          child: widget.cerrando
                              ? SizedBox(
                                  key: const ValueKey('pulsos-cierre'),
                                  height: 68,
                                  width: double.infinity,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      if (!reducirMovimiento)
                                        Positioned.fill(
                                          child: CustomPaint(
                                            painter: _PintorPulsosSalida(
                                              animacion: _pulsos,
                                            ),
                                          ),
                                        ),
                                      const Icon(
                                        Icons.logout_rounded,
                                        color: ColoresApp.textoCristalSalir,
                                        size: 27,
                                      ),
                                    ],
                                  ),
                                )
                              : const Row(
                                  key: ValueKey('cerrar-sesion'),
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.logout_rounded,
                                      color: ColoresApp.textoCristalSalir,
                                      size: 26,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Cerrar sesión',
                                      style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w700,
                                        color: ColoresApp.textoCristalSalir,
                                      ),
                                    ),
                                  ],
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
    );
  }
}

/// Ondas rojas que se expanden solo mientras termina el cierre de sesión.
class _PintorPulsosSalida extends CustomPainter {
  _PintorPulsosSalida({required this.animacion}) : super(repaint: animacion);

  final Animation<double> animacion;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);

    for (var i = 0; i < 3; i++) {
      final fase = (animacion.value + i / 3) % 1.0;
      final radio = 9.0 + 55.0 * fase;
      final opacidad = 0.32 * (1.0 - fase) * (1.0 - fase);

      canvas.drawCircle(
        centro,
        radio,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = ColoresApp.rojoCristalSalir.withValues(
            alpha: opacidad * 0.38,
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      canvas.drawCircle(
        centro,
        radio,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = ColoresApp.textoCristalSalir.withValues(alpha: opacidad),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PintorPulsosSalida anterior) =>
      anterior.animacion != animacion;
}
