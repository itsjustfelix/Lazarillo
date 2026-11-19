import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/dependencias.dart';
import 'Login/login_view.dart';
import 'modulos/modulos_view.dart';
import 'splash/splash_view.dart';
import 'tema.dart';

/// Coordina el arranque sin bloquear el primer fotograma de Flutter.
class LazarilloApp extends StatefulWidget {
  const LazarilloApp({super.key, required this.dependencias});

  final Dependencias dependencias;

  @override
  State<LazarilloApp> createState() => _LazarilloAppState();
}

class _LazarilloAppState extends State<LazarilloApp> {
  final _navegador = GlobalKey<NavigatorState>();
  bool _splashTerminado = false;
  bool _inicioPreparado = false;
  bool _haySesion = false;

  @override
  void initState() {
    super.initState();
    _prepararInicio();
  }

  Future<void> _prepararInicio() async {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    } catch (error) {
      //-- Ignoramos el error, no es crítico.
    }

    bool haySesion;
    try {
      haySesion = await widget.dependencias.auth.haySesion();
    } catch (error) {
      haySesion = false;
    }
    if (!mounted) return;
    setState(() {
      _haySesion = haySesion;
      _inicioPreparado = true;
    });
  }

  void _alTerminarSplash() {
    if (mounted) setState(() => _splashTerminado = true);
  }

  void _alIniciarSesion() {
    if (mounted) setState(() => _haySesion = true);
  }

  Future<void> _cerrarSesion() async {
    await widget.dependencias.auth.cerrarSesion();
    _navegador.currentState?.popUntil((ruta) => ruta.isFirst);
    if (!mounted) return;
    setState(() => _haySesion = false);
  }

  @override
  Widget build(BuildContext context) {
    final mostrarSplash = !_splashTerminado || !_inicioPreparado;

    return MaterialApp(
      title: 'Lazarillo',
      navigatorKey: _navegador,
      debugShowCheckedModeBanner: false,
      theme: TemaApp.claro,
      home: mostrarSplash
          ? SplashView(onTerminar: _alTerminarSplash)
          : Builder(
              builder: (context) {
                // Flutter dibuja la pantalla anterior mientras la siguiente
                // aparece. Primero se desvanece una; luego entra la otra.
                // No se retrasa la autenticación ni se altera la cámara.
                final reducirMovimiento = MediaQuery.of(context).disableAnimations;
                return ColoredBox(
                  color: ColoresApp.primario,
                  child: AnimatedSwitcher(
                    duration: reducirMovimiento
                        ? Duration.zero
                        : const Duration(milliseconds: 350),
                    switchOutCurve: const Interval(
                      0.53,
                      1.0,
                      curve: Curves.easeInCubic,
                    ),
                    switchInCurve: const Interval(
                      0.47,
                      1.0,
                      curve: Curves.easeOutCubic,
                    ),
                    transitionBuilder: (pantalla, animacion) {
                      return FadeTransition(
                        opacity: animacion,
                        child: pantalla,
                      );
                    },
                    layoutBuilder: (actual, anteriores) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          ...anteriores,
                          if (actual != null) actual,
                        ],
                      );
                    },
                    child: _haySesion
                        ? ModulosView(
                            key: const ValueKey('modulos'),
                            dependencias: widget.dependencias,
                            onCerrarSesion: _cerrarSesion,
                          )
                        : LoginView(
                            key: const ValueKey('login'),
                            auth: widget.dependencias.auth,
                            onLogin: _alIniciarSesion,
                          ),
                  ),
                );
              },
            ),
    );
  }
}
