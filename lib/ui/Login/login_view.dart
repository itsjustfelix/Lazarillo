import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../services/auth_service.dart';
import '../logo_app.dart';
import '../tema.dart';
import 'icono_google.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key, required this.auth, required this.onLogin});

  final AuthService auth;
  final VoidCallback onLogin;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  static const _duracionError = Duration(seconds: 4);

  static const _acercarNombre = 26.0;

  bool _entrando = false;
  // Solo mostramos el progreso al terminar correctamente el selector de Google.
  bool _procesandoSesion = false;
  String? _error;
  Timer? _temporizadorError;

  Future<void> _entrar() async {
    if (_entrando) return;

    _entrando = true;
    _ocultarError();
    setState(() {});

    try {
      await widget.auth.loginConGoogle(
        alObtenerCredencial: () {
          // Google ya devolvió la credencial; ahora se autentica en el backend.
          if (mounted) setState(() => _procesandoSesion = true);
        },
      );
      if (!mounted) return;
      widget.onLogin();
    } on InicioCancelado {
      // El usuario canceló el inicio de sesión.
    } on ApiException catch (e) {
      _mostrarError(e.message);
    } catch (e) {
      _mostrarError('No pude iniciar sesión. Intenta de nuevo.');
    } finally {
      _entrando = false;
      _procesandoSesion = false;
      if (mounted) setState(() {});
    }
  }

  void _mostrarError(String mensaje) {
    _temporizadorError?.cancel();

    if (!mounted) return;

    setState(() => _error = mensaje);

    _temporizadorError = Timer(_duracionError, () {
      if (mounted) {
        setState(() => _error = null);
      }
    });
  }

  void _ocultarError() {
    _temporizadorError?.cancel();
    _error = null;
  }

  @override
  void dispose() {
    _temporizadorError?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresApp.primario,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LogoApp(tamano: 160),

                      Transform.translate(
                        offset: const Offset(0, -_acercarNombre),
                        child: Semantics(
                          header: true,
                          child: const Text(
                            'Lazarillo',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Sora',
                              fontSize: 38,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              color: ColoresApp.blanco,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_error != null)
                Semantics(
                  liveRegion: true,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColoresApp.blanco,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        color: ColoresApp.error,
                      ),
                    ),
                  ),
                ),

              Semantics(
                button: true,
                liveRegion: true,
                label: _procesandoSesion
                    ? 'Iniciando sesión, espera un momento'
                    : 'Iniciar sesión con Google',
                child: SizedBox(
                  height: 72,
                  child: ElevatedButton(
                    // Evita repetir el login, pero conserva la G mientras Google
                    // muestra la selección de cuenta o si se cancela.
                    onPressed: _entrando ? null : _entrar,
                    style: ElevatedButton.styleFrom(
                      disabledBackgroundColor: ColoresApp.blanco,
                      disabledForegroundColor: ColoresApp.fondoMensaje,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Row(
                        key: ValueKey<bool>(_procesandoSesion),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_procesandoSesion)
                            const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: ColoresApp.primario,
                              ),
                            )
                          else
                            const IconoGoogle(tamano: 28),
                          const SizedBox(width: 12),
                          Text(
                            _procesandoSesion
                                ? 'Iniciando sesión...'
                                : 'Entrar con Google',
                            style: const TextStyle(
                              fontSize: 22,
                              color: ColoresApp.fondoMensaje,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
