import 'dart:async';

import 'package:flutter_soloud/flutter_soloud.dart';

/// Engine compartilhado para carregar os samples uma vez e reduzir atrasos
/// entre as notas nos exercícios auditivos e no teclado.
class MusicAudioService {
  MusicAudioService._();

  static final MusicAudioService instance = MusicAudioService._();

  final SoLoud _engine = SoLoud.instance;
  final Map<String, Future<AudioSource>> _loading = {};
  final Map<SoundHandle, AudioSource> _playing = {};
  Future<void>? _initialization;

  Future<void> initialize() {
    return _initialization ??= _engine.init();
  }

  Future<void> preload(Iterable<String> files) async {
    await initialize();
    await Future.wait(files.map(_source));
  }

  Future<void> playFor(
    String file,
    Duration duration, {
    double pitchRatio = 1,
  }) async {
    final source = await _source(file);
    final handle = await _engine.play(source);
    _engine.setRelativePlaySpeed(handle, pitchRatio);
    _playing[handle] = source;

    final fadeDuration = duration < const Duration(milliseconds: 80)
        ? duration
        : const Duration(milliseconds: 60);
    await Future<void>.delayed(duration - fadeDuration);

    if (!_playing.containsKey(handle) ||
        !_engine.getIsValidVoiceHandle(handle)) {
      return;
    }
    if (fadeDuration > Duration.zero) {
      _engine.fadeVolume(handle, 0, fadeDuration);
      await Future<void>.delayed(fadeDuration);
    }
    await _stop(handle);
  }

  Future<void> playToCompletion(String file) async {
    final source = await _source(file);
    final handle = await _engine.play(source);
    _playing[handle] = source;
    await source.soundEvents.firstWhere(
      (event) =>
          event.handle == handle &&
          event.event == SoundEventType.handleIsNoMoreValid,
    );
    _playing.remove(handle);
  }

  /// Starts a note immediately and leaves it active until the key is released.
  Future<SoundHandle> startPianoNote(
    String file, {
    double pitchRatio = 1,
  }) async {
    final source = await _source(file);
    final handle = await _engine.play(source);
    _engine.setRelativePlaySpeed(handle, pitchRatio);
    _playing[handle] = source;
    _trackNaturalEnd(source, handle);
    return handle;
  }

  /// Releases one piano key with a natural tail instead of cutting it off.
  Future<void> stopPianoNote(SoundHandle handle) async {
    if (!_playing.containsKey(handle)) return;
    if (_engine.getIsValidVoiceHandle(handle)) {
      const release = Duration(milliseconds: 1100);
      _engine.fadeVolume(handle, 0, release);
      await Future<void>.delayed(release);
    }
    await _stop(handle);
  }

  Future<void> stopAll() async {
    for (final handle in _playing.keys.toList()) {
      await _stop(handle);
    }
  }

  Future<AudioSource> _source(String file) {
    return _loading.putIfAbsent(file, () async {
      await initialize();
      return _engine.loadAsset('assets/sounds/$file');
    });
  }

  void _trackNaturalEnd(AudioSource source, SoundHandle handle) {
    unawaited(
      source.soundEvents
          .firstWhere(
            (event) =>
                event.handle == handle &&
                event.event == SoundEventType.handleIsNoMoreValid,
          )
          .then((_) => _playing.remove(handle)),
    );
  }

  Future<void> _stop(SoundHandle handle) async {
    if (!_playing.containsKey(handle)) return;
    if (_engine.getIsValidVoiceHandle(handle)) await _engine.stop(handle);
    _playing.remove(handle);
  }
}
