import 'dart:ui';

import 'package:flutter/material.dart';

import '../tema.dart';
import 'icono_google.dart';

/// Botón visual. No conoce servicios de autenticación: el login controla
/// cuándo empieza y termina el procesamiento real de la sesión.
class BotonGoogleCristal extends StatefulWidget {
  const BotonGoogleCristal({
    super.key,
    required this.procesando,
    required this.habilitado,
    required this.alPresionar,
  });

  final bool procesando;
  final bool habilitado;
  final VoidCallback alPresionar;

  @override
  State<BotonGoogleCristal> createState() => _BotonGoogleCristalState();
}

class _BotonGoogleCristalState extends State<BotonGoogleCristal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlPulsos;

  @override
  void initState() {
    super.initState();
    _controlPulsos = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sincronizarPulsos();
  }

  @override
  void didUpdateWidget(covariant BotonGoogleCristal anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.procesando != widget.procesando) {
      _sincronizarPulsos();
    }
  }

  void _sincronizarPulsos() {
    final reducirMovimiento = MediaQuery.of(context).disableAnimations;
    if (widget.procesando && !reducirMovimiento) {
      if (!_controlPulsos.isAnimating) _controlPulsos.repeat();
    } else {
      _controlPulsos.stop();
      _controlPulsos.reset();
    }
  }

  @override
  void dispose() {
    _controlPulsos.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radio = BorderRadius.circular(100);
    final reducirMovimiento = MediaQuery.of(context).disableAnimations;

    return Semantics(
      button: true,
      enabled: widget.habilitado,
      liveRegion: true,
      label: widget.procesando
          ? 'Iniciando sesión con Google'
          : 'Entrar con Google',
      onTap: widget.habilitado ? widget.alPresionar : null,
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: radio,
            boxShadow: const [
              BoxShadow(
                color: Color(0x60000000),
                blurRadius: 34,
                offset: Offset(0, 17),
              ),
              BoxShadow(
                color: Color(0x37000000),
                blurRadius: 13,
                offset: Offset(0, 6),
              ),
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 3,
                offset: Offset(0, 2),
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
                  onTap: widget.habilitado ? widget.alPresionar : null,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: radio,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            stops: const [0, 0.50, 1],
                            colors: [
                              ColoresApp.blanco.withValues(
                                alpha: ColoresApp.tinteBotonGoogle * 1.14,
                              ),
                              ColoresApp.blanco.withValues(
                                alpha: ColoresApp.tinteBotonGoogle,
                              ),
                              ColoresApp.blanco.withValues(
                                alpha: ColoresApp.tinteBotonGoogle * 0.77,
                              ),
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
                            height: 29,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(100),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  ColoresApp.negroCristal.withValues(alpha: 0.12),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animacion) {
                            return FadeTransition(
                              opacity: animacion,
                              child: ScaleTransition(
                                scale: Tween<double>(
                                  begin: 0.92,
                                  end: 1,
                                ).animate(animacion),
                                child: child,
                              ),
                            );
                          },
                          child: widget.procesando
                              ? SizedBox(
                                  key: const ValueKey('pulsos'),
                                  height: 72,
                                  width: double.infinity,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      if (!reducirMovimiento)
                                        Positioned.fill(
                                          child: CustomPaint(
                                            painter: _PintorPulsosCristal(
                                              animacion: _controlPulsos,
                                            ),
                                          ),
                                        ),
                                      const IconoGoogle(tamano: 28),
                                    ],
                                  ),
                                )
                              : const Row(
                                  key: ValueKey('boton'),
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconoGoogle(tamano: 28),
                                    SizedBox(width: 14),
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          'Entrar con Google',
                                          maxLines: 1,
                                          style: TextStyle(
                                            color: ColoresApp.blanco,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w600,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black54,
                                                blurRadius: 6,
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

/// Ondas que se expanden alrededor de la G de Google, sin contorno en el botón.
class _PintorPulsosCristal extends CustomPainter {
  _PintorPulsosCristal({required this.animacion})
      : super(repaint: animacion);

  final Animation<double> animacion;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 3; i++) {
      final fase = (animacion.value + i / 3) % 1.0;
      final radio = 9.0 + 66.0 * fase;
      final desvanecimiento = (1.0 - fase) * (1.0 - fase);
      final intensidad = 0.42 * desvanecimiento;

      canvas.drawCircle(
        centro,
        radio,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = ColoresApp.brilloOndaCristal.withValues(
            alpha: intensidad * 0.48,
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        centro,
        radio,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3
          ..color = ColoresApp.blanco.withValues(alpha: intensidad),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PintorPulsosCristal anterior) =>
      anterior.animacion != animacion;
}
