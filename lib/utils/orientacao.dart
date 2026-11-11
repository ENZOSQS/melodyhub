import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

bool get _celular =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

/// Coloca a tela na horizontal (instrumentos que precisam de largura).
void usarPaisagem() {
  if (!_celular) return;
  unawaited(
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]),
  );
}

/// Volta à orientação padrão do app, em pé.
void voltarRetrato() {
  if (!_celular) return;
  unawaited(
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]),
  );
}
