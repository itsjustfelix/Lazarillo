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
  /// Cuánto tiempo se queda el mensaje de error en pantalla.
  static const _duracionError = Duration(seconds: 4);

  static const _acercarNombre = 10.0;
  bool _entrando = false;
  String? _error;
  Timer? _temporizadorError;

  Future<void> _entrar() async {
    if (_entrando) return;
    _entrando = true;
    _ocultarError();
    setState(() {});
    try {
      await widget.auth.loginConGoogle();
      widget.onLogin(); // app.dart cambia a la pantalla principal
    } on InicioCancelado {
      // La persona cerró la ventana de Google a propósito: no se muestra nada.
    } on ApiException catch (e) {
      _mostrarError(e.message);
    } catch (e) {
      debugPrint('Login: $e');
      _mostrarError('No pude iniciar sesión. Intenta de nuevo.');
    } finally {
      _entrando = false;
      if (mounted) setState(() {});
    }
  }

  void _mostrarError(String mensaje) {
    _temporizadorError?.cancel();
    if (!mounted) return;
    setState(() => _error = mensaje);
    _temporizadorError = Timer(_duracionError, () {
      if (mounted) setState(() => _error = null);
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
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
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
                label: _entrando
                    ? 'Iniciando sesión, espera un momento'
                    : 'Iniciar sesión con Google',
                child: SizedBox(
                  height: 72,
                  child: ElevatedButton(
                    onPressed: _entrar,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconoGoogle(tamano: 28),
                        SizedBox(width: 12),
                        Text(
                          'Entrar con Google',
                          style: TextStyle(
                            fontSize: 22,
                            color: ColoresApp.fondoMensaje,
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
    );
  }
}
