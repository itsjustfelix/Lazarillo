import 'package:flutter/widgets.dart';

import 'core/dependencias.dart';
import 'ui/app.dart';

/// Dibujamos Flutter cuanto antes para reducir el tiempo del arranque nativo.
/// La comprobación de sesión ocurre durante la animación, no antes de runApp.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(LazarilloApp(dependencias: Dependencias()));
}
