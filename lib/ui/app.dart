import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../core/dependencias.dart';
import 'Login/login_view.dart';
import 'modulos/modulos_view.dart';
import 'tema.dart';

class LazarilloApp extends StatefulWidget {
  const LazarilloApp({
    super.key,
    required this.dependencias,
    required this.haySesionInicial,
    this.camaraInicial,
  });

  final Dependencias dependencias;

  /// Resultado de revisar el almacenamiento antes de abrir la app (main.dart).
  final bool haySesionInicial;

  /// Cámara que main.dart abrió durante el arranque (null si no se pudo o si
  /// no había sesión).
  final CameraController? camaraInicial;

  @override
  State<LazarilloApp> createState() => _LazarilloAppState();
}

class _LazarilloAppState extends State<LazarilloApp> {
  final _navegador = GlobalKey<NavigatorState>();

  /// Empieza con lo que encontró main.dart y cambia al iniciar o cerrar sesión.
  late bool _haySesion = widget.haySesionInicial;

  /// La cámara del arranque sirve para UNA sola visita a los módulos: al
  /// cerrar sesión ModulosView la cierra, así que se suelta aquí para no
  /// volver a entregar una cámara ya cerrada.
  late CameraController? _camaraPrecargada = widget.camaraInicial;

  void _alIniciarSesion() {
    setState(() => _haySesion = true);
  }

  /// Se usa desde el perfil y cuando el servidor dice que la sesión
  /// expiró: vuelve a la pantalla de inicio de sesión.
  Future<void> _cerrarSesion() async {
    await widget.dependencias.auth.cerrarSesion();
    _navegador.currentState?.popUntil((ruta) => ruta.isFirst);
    if (mounted) {
      setState(() {
        _haySesion = false;
        _camaraPrecargada = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lazarillo',
      navigatorKey: _navegador,
      debugShowCheckedModeBanner: false,
      theme: TemaApp.claro,
      home: _haySesion
          ? ModulosView(
              dependencias: widget.dependencias,
              onCerrarSesion: _cerrarSesion,
              camaraInicial: _camaraPrecargada,
            )
          : LoginView(
              auth: widget.dependencias.auth,
              onLogin: _alIniciarSesion,
            ),
    );
  }
}
