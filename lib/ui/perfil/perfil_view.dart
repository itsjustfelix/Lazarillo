import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/dependencias.dart';
import '../../models/perfil_usuario.dart';
import '../tema.dart';
import 'boton_cerrar_sesion_cristal.dart';

class PerfilView extends StatefulWidget {
  const PerfilView({
    super.key,
    required this.dependencias,
    required this.perfil,
    required this.onCerrarSesion,
  });

  final Dependencias dependencias;
  final PerfilUsuario perfil;
  final VoidCallback onCerrarSesion;

  @override
  State<PerfilView> createState() => _PerfilViewState();
}

class _PerfilViewState extends State<PerfilView> {
  Dependencias get _d => widget.dependencias;

  bool _cerrando = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      _d.voz.hablar(
        'Perfil de ${widget.perfil.nombre}. '
        'Cuenta conectada con Google. '
        'Puedes volver o cerrar sesión.',
      ),
    );
  }

  /// El cierre real no cambia: se confirma primero, se anuncia y después
  /// se delega al contenedor principal para eliminar la sesión.
  Future<void> _confirmarCierre() async {
    if (_cerrando) return;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogoContexto) {
        return AlertDialog(
          backgroundColor: ColoresApp.blanco,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            '¿Cerrar sesión?',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 21,
              fontWeight: FontWeight.w600,
              color: ColoresApp.textoPerfil,
            ),
          ),
          content: const Text(
            'Tendrás que iniciar sesión nuevamente '
            'para utilizar Lazarillo.',
            style: TextStyle(
              fontSize: 17,
              color: ColoresApp.textoPerfil,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogoContexto).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: ColoresApp.primario,
              ),
              child: const Text('Cancelar', style: TextStyle(fontSize: 17)),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogoContexto).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: ColoresApp.error,
              ),
              child: const Text(
                'Cerrar sesión',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmado != true) return;

    setState(() => _cerrando = true);
    try {
      await _d.voz.hablar('Cerrando sesión.');
    } catch (_) {
      // La voz no debe bloquear el cierre de sesión.
    }
    if (mounted) widget.onCerrarSesion();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: ColoresApp.blanco,
        systemNavigationBarDividerColor: ColoresApp.blanco,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        // El fondo del sistema inferior es blanco. El morado queda reservado
        // al encabezado y se extiende detrás de la barra de notificaciones.
        backgroundColor: ColoresApp.blanco,
        body: Column(
          children: [
            ColoredBox(
              color: ColoresApp.primario,
              child: Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top,
                ),
                child: _construirEncabezado(widget.perfil),
              ),
            ),
            Expanded(
              child: ClipPath(
                clipper: const _CurvaSuperiorPerfil(),
                child: ColoredBox(
                  color: ColoresApp.fondoPerfil,
                  child: Padding(
                    // El cuerpo empieza después de la curva ascendente.
                    padding: const EdgeInsets.only(top: 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(
                              24,
                              12,
                              24,
                              16,
                            ),
                            child: _construirContenidoCuenta(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            24,
                            10,
                            24,
                            20,
                          ),
                          child: BotonCerrarSesionCristal(
                            cerrando: _cerrando,
                            alPresionar: _confirmarCierre,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Respeta el área de gestos de Android y evita un fondo morado
            // o azulado detrás de la barra de navegación de Samsung.
            SizedBox(
              height: MediaQuery.paddingOf(context).bottom,
              child: const ColoredBox(color: ColoresApp.blanco),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirEncabezado(PerfilUsuario perfil) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  tooltip: 'Volver a los módulos',
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: ColoresApp.blanco,
                    size: 28,
                  ),
                ),
              ),
              const Expanded(
                child: Text(
                  'Mi perfil',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    color: ColoresApp.blanco,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 13),
          _FotoPerfil(fotoUrl: perfil.fotoUrl),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(
              perfil.nombre,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Sora',
                fontSize: 25,
                fontWeight: FontWeight.w600,
                color: ColoresApp.blanco,
              ),
            ),
          ),
          const SizedBox(height: 11),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: ColoresApp.blanco.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFFBAF7D8),
                  size: 18,
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Conectado con Google',
                    maxLines: 1,
                    style: TextStyle(
                      color: ColoresApp.blanco,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
        ],
      ),
    );
  }

  Widget _construirContenidoCuenta() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Expanded(
              child: Text(
                'Tu cuenta',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: ColoresApp.textoPerfil,
                ),
              ),
            ),
            Text(
              'Información de acceso',
              style: TextStyle(
                fontSize: 12,
                color: ColoresApp.textoPerfilSecundario,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            color: ColoresApp.blanco,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: ColoresApp.primario.withValues(alpha: 0.13),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: ColoresApp.negroCristal.withValues(alpha: 0.035),
                blurRadius: 7,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: ColoresApp.fondoIconoCuenta,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: ColoresApp.secundario,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cuenta activa',
                          style: TextStyle(
                            color: ColoresApp.textoPerfil,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Sesión iniciada con Google',
                          style: TextStyle(
                            color: ColoresApp.textoPerfilSecundario,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 23,
                    color: ColoresApp.cuentaActiva,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(
                height: 1,
                thickness: 1,
                color: ColoresApp.primario.withValues(alpha: 0.08),
              ),
              const SizedBox(height: 14),
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Proveedor de acceso',
                      style: TextStyle(
                        color: ColoresApp.textoPerfilSecundario,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    'Google',
                    style: TextStyle(
                      color: ColoresApp.primario,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// El fondo claro asciende suavemente por el centro, sobre el encabezado.
class _CurvaSuperiorPerfil extends CustomClipper<Path> {
  const _CurvaSuperiorPerfil();

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 28)
      ..quadraticBezierTo(size.width / 2, -16, size.width, 28)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant _CurvaSuperiorPerfil oldClipper) => false;
}

/// Foto de Google elevada con dos sombras y anillo violeta discreto.
class _FotoPerfil extends StatelessWidget {
  const _FotoPerfil({required this.fotoUrl});

  final String? fotoUrl;

  @override
  Widget build(BuildContext context) {
    final url = fotoUrl;
    final tieneFoto = url != null && url.isNotEmpty;

    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ColoresApp.blanco.withValues(alpha: 0.22),
          boxShadow: [
            BoxShadow(
              color: ColoresApp.negroCristal.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 13),
            ),
            BoxShadow(
              color: ColoresApp.secundario.withValues(alpha: 0.23),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 49,
          backgroundColor: ColoresApp.secundario,
          foregroundImage: tieneFoto ? NetworkImage(url) : null,
          onForegroundImageError: tieneFoto ? (error, pila) {} : null,
          child: const Icon(
            Icons.person_rounded,
            size: 56,
            color: ColoresApp.blanco,
          ),
        ),
      ),
    );
  }
}
