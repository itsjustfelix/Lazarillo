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

  @override
  void initState() {
    super.initState();
    unawaited(
      _d.voz.hablar(
        'Perfil de ${widget.perfil.nombre}. Hay dos botones: '
        'cerrar sesión y volver.',
      ),
    );
  }

  Future<void> _cerrarSesion() async {
    await _d.voz.hablar('Cerrando sesión.');
    widget.onCerrarSesion();
  }

  @override
  Widget build(BuildContext context) {
    final perfil = widget.perfil;

    return Scaffold(
      backgroundColor: ColoresApp.blanco,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Row(
                children: [
                  _FotoPerfil(fotoUrl: perfil.fotoUrl),
                  const SizedBox(width: 20),
                  Expanded(
                    // header: el lector de pantalla lo anuncia como título.
                    child: Semantics(
                      header: true,
                      child: Text(
                        perfil.nombre,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: ColoresApp.fondoMensaje,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                            ColoresApp.secundario,
                          ),
                        ),
                        onPressed: _cerrarSesion,
                        child: const Text(
                          'Cerrar sesión',
                          style: TextStyle(
                            fontSize: 18,
                            color: ColoresApp.fondoMensaje,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FotoPerfil extends StatelessWidget {
  const _FotoPerfil({required this.fotoUrl});

  final String? fotoUrl;

  static const _radio = 40.0;

  @override
  Widget build(BuildContext context) {
    final url = fotoUrl;
    final tieneFoto = url != null && url.isNotEmpty;

    return ExcludeSemantics(
      child: CircleAvatar(
        radius: _radio,
        backgroundColor: ColoresApp.secundario,
        foregroundImage: tieneFoto ? NetworkImage(url) : null,
        onForegroundImageError: tieneFoto ? (error, pila) {} : null,
        child: const Icon(Icons.person, size: 80, color: ColoresApp.blanco),
      ),
    );
  }
}
