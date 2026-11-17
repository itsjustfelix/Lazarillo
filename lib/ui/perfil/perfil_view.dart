import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/dependencias.dart';
import '../../models/perfil_usuario.dart';
import '../tema.dart';

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

    // Anuncio para personas con discapacidad visual.
    unawaited(
      _d.voz.hablar(
        'Perfil de ${widget.perfil.nombre}. '
        'Cuenta conectada con Google. '
        'Puedes volver o cerrar sesión.',
      ),
    );
  }

  // Confirma el cierre para evitar acciones accidentales.
  Future<void> _confirmarCierre() async {
    if (_cerrando) return;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ColoresApp.blanco,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            '¿Cerrar sesión?',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 21,
              fontWeight: FontWeight.w600,
              color: ColoresApp.fondoMensaje,
            ),
          ),
          content: const Text(
            'Tendrás que iniciar sesión nuevamente '
            'para utilizar Lazarillo.',
            style: TextStyle(fontSize: 17, color: ColoresApp.fondoMensaje),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(foregroundColor: ColoresApp.primario),
              child: const Text('Cancelar', style: TextStyle(fontSize: 17)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: ColoresApp.error),
              child: const Text(
                'Cerrar sesión',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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
      // Un error del TTS no debe bloquear el cierre.
    }

    if (mounted) {
      widget.onCerrarSesion();
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfil = widget.perfil;

    return Scaffold(
      backgroundColor: ColoresApp.blanco,
      body: SafeArea(
        child: Column(
          children: [
            // Encabezado con foto y nombre.
            _construirEncabezado(perfil),

            // Información de la cuenta.
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tu cuenta',
                      style: TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                        color: ColoresApp.fondoMensaje,
                      ),
                    ),

                    const SizedBox(height: 16),

                    _construirTarjetaCuenta(),
                  ],
                ),
              ),
            ),

            // Botón de cerrar sesión.
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: OutlinedButton.icon(
                  onPressed: _cerrando ? null : _confirmarCierre,
                  icon: _cerrando
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ColoresApp.error,
                          ),
                        )
                      : const Icon(Icons.logout_rounded, size: 26),
                  label: Text(
                    _cerrando ? 'Cerrando sesión...' : 'Cerrar sesión',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColoresApp.error,
                    side: const BorderSide(color: ColoresApp.error, width: 1.5),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Encabezado morado con foto y nombre.
  Widget _construirEncabezado(PerfilUsuario perfil) {
    return Container(
      width: double.infinity,

      // CAMBIO 1:
      // Reducimos el margen horizontal de 24 a 8.
      // También acercamos ligeramente la fila al borde superior.
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 32),

      decoration: const BoxDecoration(
        color: ColoresApp.primario,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),

      child: Column(
        children: [
          Row(
            children: [
              // CAMBIO 2:
              // Eliminamos el padding interno del IconButton.
              // Conservamos el área táctil de 48 x 48.
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  tooltip: 'Volver a los módulos',
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    size: 28,
                    color: ColoresApp.blanco,
                  ),
                ),
              ),

              // Título centrado.
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

              // Equilibra el espacio de la flecha
              // para mantener el título centrado.
              const SizedBox(width: 48),
            ],
          ),

          const SizedBox(height: 20),

          _FotoPerfil(fotoUrl: perfil.fotoUrl),

          const SizedBox(height: 18),

          Semantics(
            header: true,
            child: Text(
              perfil.nombre,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Sora',
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: ColoresApp.blanco,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tarjeta que muestra el estado de la cuenta.
  Widget _construirTarjetaCuenta() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ColoresApp.blanco,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ColoresApp.primario.withValues(alpha: 0.15)),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 32,
            color: ColoresApp.primario,
          ),

          SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cuenta conectada',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: ColoresApp.fondoMensaje,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Sesión iniciada con Google',
                  style: TextStyle(
                    fontSize: 15,
                    color: ColoresApp.fondoMensaje,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Muestra la foto del usuario obtenida durante el login.
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
          border: Border.all(color: ColoresApp.blanco, width: 2),
        ),
        child: CircleAvatar(
          radius: 52,
          backgroundColor: ColoresApp.secundario,
          foregroundImage: tieneFoto ? NetworkImage(url) : null,
          onForegroundImageError: tieneFoto ? (error, pila) {} : null,
          child: const Icon(
            Icons.person_rounded,
            size: 58,
            color: ColoresApp.blanco,
          ),
        ),
      ),
    );
  }
}
