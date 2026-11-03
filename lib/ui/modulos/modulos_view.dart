import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/dependencias.dart';
import '../../services/camara/camara_service.dart';
import '../buscar_objeto/buscar_objeto_view.dart';
import '../describir_escena/describir_escena_view.dart';
import '../extraer_texto/extraer_texto_view.dart';
import '../perfil/perfil_view.dart';
import '../tema.dart';
import 'logo_perfil.dart';
import 'pildora_modulo.dart';

/// Nombre y explicación de un módulo (lo que se ve en la píldora y lo que
/// se dice en voz alta al llegar a él).
class _Modulo {
  const _Modulo(this.nombre, this.instruccion);

  final String nombre;
  final String instruccion;
}

/// Contenedor de los tres módulos. Hace tres cosas:
///  1. Se queda con UNA sola cámara y se la presta a los módulos (Android no
///     deja abrir la misma cámara dos veces a la vez).
///  2. Deja deslizar entre módulos (PageView).
///  3. Dibuja encima de todos la píldora fija y el logo del perfil.
class ModulosView extends StatefulWidget {
  const ModulosView({
    super.key,
    required this.dependencias,
    required this.onCerrarSesion,
    this.camaraInicial,
  });

  final Dependencias dependencias;
  final VoidCallback onCerrarSesion;

  /// Cámara que ya se abrió en el arranque. Si es null, se abre aquí.
  /// Esta pantalla pasa a ser su dueña: la cierra en dispose.
  final CameraController? camaraInicial;

  @override
  State<ModulosView> createState() => _ModulosViewState();
}

class _ModulosViewState extends State<ModulosView> {
  /// En el orden en que aparecen, de izquierda a derecha.
  static const _modulos = [
    _Modulo('Buscar objetos', 'Toca dos veces y di qué quieres buscar.'),
    _Modulo(
      'Describir escena',
      'Toca dos veces para describir lo que tienes enfrente.',
    ),
    _Modulo(
      'Leer texto',
      'Toca dos veces para leer el texto que tienes enfrente.',
    ),
  ];

  /// Módulo con el que se abre la app: 0 buscar, 1 describir, 2 leer texto.
  static const _paginaInicial = 1;

  late final PageController _paginas = PageController(
    initialPage: _paginaInicial,
  );
  CameraController? _camara;
  int _indice = _paginaInicial;

  Dependencias get _d => widget.dependencias;

  @override
  void initState() {
    super.initState();
    // Si la cámara llegó abierta desde el arranque, se ve desde el primer
    // fotograma, sin esperar a que la voz termine de configurarse.
    _camara = widget.camaraInicial;
    _iniciar();
  }

  Future<void> _iniciar() async {
    await _d.voz.iniciar(); // se configura una sola vez para toda la app
    try {
      // Solo se abre aquí si no llegó abierta (primer ingreso tras el login,
      // o si falló en el arranque).
      if (_camara == null) {
        final camara = await CamaraService.abrir();
        if (!mounted) {
          await camara.dispose();
          return;
        }
        setState(() => _camara = camara);
      }

      final nombre = await _d.auth.obtenerNombre() ?? '';
      await _d.voz.hablar(
        'Hola $nombre. Desliza a los lados para cambiar '
        'de módulo. ${_anuncio(_modulos[_indice])}',
      );
    } on CameraException {
      await _d.voz.hablar('No pude abrir la cámara. Revisa el permiso.');
    }
  }

  String _anuncio(_Modulo modulo) => '${modulo.nombre}. ${modulo.instruccion}';

  /// Al llegar a otro módulo: se actualiza la píldora y se anuncia en voz
  /// alta (quien no ve la pantalla no ve la píldora). Hablar corta además
  /// cualquier lectura o guía que estuviera sonando.
  void _alCambiarPagina(int indice) {
    setState(() => _indice = indice);
    unawaited(_d.voz.hablar(_anuncio(_modulos[indice])));
  }

  /// Mantener presionado el logo abre el perfil encima de los módulos.
  /// El perfil se lee ANTES de abrir la pantalla, así llega con los datos
  /// listos y no hay un instante vacío (ni rueda de carga).
  /// Al volver se dice en qué módulo se está, porque PerfilView deja de
  /// hablar y quien no ve la pantalla no sabe dónde quedó.
  Future<void> _abrirPerfil() async {
    final navegador = Navigator.of(context);
    final perfil = await _d.auth.obtenerPerfil();
    if (!mounted) return;

    await navegador.push(
      MaterialPageRoute<void>(
        builder: (_) => PerfilView(
          dependencias: _d,
          perfil: perfil,
          onCerrarSesion: widget.onCerrarSesion,
        ),
      ),
    );
    // Si se cerró la sesión desde el perfil, este contenedor ya no existe.
    if (!mounted) return;
    unawaited(_d.voz.hablar(_anuncio(_modulos[_indice])));
  }

  @override
  void dispose() {
    _paginas.dispose();
    _d.voz.detener();
    _camara?.dispose(); // los módulos se cierran antes que este contenedor
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camara = _camara;

    return Scaffold(
      backgroundColor: ColoresApp.fondoCamara,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (camara == null)
            const Center(child: CircularProgressIndicator())
          else
            PageView(
              controller: _paginas,
              onPageChanged: _alCambiarPagina,
              children: [
                BuscarObjetoView(dependencias: _d, camara: camara),
                DescribirEscenaView(
                  dependencias: _d,
                  camara: camara,
                  onSesionExpirada: widget.onCerrarSesion,
                ),
                ExtraerTextoView(dependencias: _d, camara: camara),
              ],
            ),
          // Va después del PageView, así queda dibujada encima de él.
          PildoraModulo(texto: _modulos[_indice].nombre),
          LogoPerfil(
            alMantener: _abrirPerfil,
            fotoUrl: _d.auth.obtenerFotoUrl(),
          ),
        ],
      ),
    );
  }
}
