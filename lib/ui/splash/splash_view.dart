import 'dart:async';

import 'package:flutter/material.dart';

import '../tema.dart';
import 'pintor_ojo.dart';

/// Pantalla de arranque animada: un ojo que se abre y pulsa.
///
/// Es interactiva de dos maneras:
///  - La pupila sigue al dedo mientras se toca o arrastra la pantalla.
///  - Un toque la salta (también el "activar" de TalkBack).
///
/// Cuando la animación termina (o se salta) avisa con [onTerminar]; quien la
/// usa decide a dónde ir después (login o módulos).
class SplashView extends StatefulWidget {
  const SplashView({super.key, required this.onTerminar});

  final VoidCallback onTerminar;

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  /// Misma duración que el diseño original.
  static const _duracion = Duration(milliseconds: 3400);

  /// Un instante con el ojo ya abierto y pulsando, antes de pasar a lo que
  /// sigue, para que no se corte de golpe.
  static const _pausaFinal = Duration(milliseconds: 500);

  /// Cuánto se puede mover la pupila (en unidades del diseño de 390 px).
  /// Con el aro interior de 41 y la pupila de 27,5 caben unos 13 sin salirse.
  static const _desvioMaximo = 12.0;

  late final AnimationController _controlador = AnimationController(
    vsync: this,
    duration: _duracion,
  );

  Timer? _temporizadorFinal;
  Offset _mirada = Offset.zero;
  bool _terminado = false;

  @override
  void initState() {
    super.initState();
    _controlador.addStatusListener((estado) {
      if (estado == AnimationStatus.completed) {
        _temporizadorFinal = Timer(_pausaFinal, _terminar);
      }
    });
    _controlador.forward();
  }

  /// Se protege contra llamarse dos veces (por ejemplo, un toque justo
  /// cuando acaba la animación).
  void _terminar() {
    if (_terminado || !mounted) return;
    _terminado = true;
    // Al saltar, mostramos el ojo abierto hasta que termine la lectura de sesión.
    if (_controlador.value < 1) {
      _controlador.value = 1;
    }
    widget.onTerminar();
  }

  /// Convierte la posición del dedo en un desplazamiento de la pupila: mira
  /// hacia donde está el dedo y se mueve más cuanto más lejos del centro.
  void _mirarHacia(Offset dedo, Size pantalla) {
    final desdeElCentro = dedo - pantalla.center(Offset.zero);
    final distancia = desdeElCentro.distance;
    if (distancia == 0) return;

    final fuerza = (distancia / (pantalla.width / 2)).clamp(0.0, 1.0);
    setState(() {
      _mirada = desdeElCentro / distancia * _desvioMaximo * fuerza;
    });
  }

  void _mirarAlFrente() => setState(() => _mirada = Offset.zero);

  @override
  void dispose() {
    _temporizadorFinal?.cancel();
    _controlador.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresApp.primario,
      body: Semantics(
        button: true,
        label:
            'Lazarillo. Iniciando aplicación. '
            'Toca dos veces para continuar.',
        onTap: _terminar,
        child: LayoutBuilder(
          builder: (context, restricciones) {
            final pantalla = restricciones.biggest;

            return Listener(
              onPointerDown: (e) => _mirarHacia(e.localPosition, pantalla),
              onPointerMove: (e) => _mirarHacia(e.localPosition, pantalla),
              onPointerUp: (_) => _mirarAlFrente(),
              onPointerCancel: (_) => _mirarAlFrente(),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _terminar,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Animación del ojo en el centro.
                    TweenAnimationBuilder<Offset>(
                      tween: Tween<Offset>(end: _mirada),
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOut,
                      builder: (context, mirada, _) {
                        return AnimatedBuilder(
                          animation: _controlador,
                          builder: (context, _) {
                            return CustomPaint(
                              size: Size.infinite,
                              painter: PintorOjo(
                                progreso: _controlador.value,
                                mirada: mirada,
                              ),
                            );
                          },
                        );
                      },
                    ),

                    // Nombre de la app en la parte inferior.
                    Positioned.fill(
                      child: SafeArea(
                        top: false,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 48),
                            child: IgnorePointer(
                              child: ExcludeSemantics(
                                child: Text(
                                  'lazarillo',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: "Sora",
                                    color: ColoresApp.blanco,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
