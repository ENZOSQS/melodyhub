import 'package:flutter_soloud/flutter_soloud.dart';

/// Inicialização única do SoLoud, compartilhada por todos os serviços de áudio.
///
/// Chamar `SoLoud.init()` de novo com o motor já ativo reinicia o motor e
/// invalida os sons carregados por outro serviço (por exemplo, os cliques do
/// metrônomo). Por isso NotePlayer e MusicAudioService passam sempre por aqui.
abstract final class AudioEngine {
  static Future<void>? _initialization;

  static Future<void> ensureInitialized() {
    if (SoLoud.instance.isInitialized) return Future<void>.value();
    return _initialization ??= _init();
  }

  static Future<void> _init() async {
    try {
      await SoLoud.instance.init();
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }
}
