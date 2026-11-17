import 'dart:async';

import 'package:flutter_soloud/flutter_soloud.dart';

import 'audio_engine.dart';
import 'note_synth.dart';

enum NoteInstrument { piano, guitar }

const standardGuitarOpenMidis = [64, 59, 55, 50, 45, 40];

/// Toca notas sintetizadas no app (sem samples) para os exercícios auditivos.
///
/// Cada nota ou acorde é gerado inteiro em memória por [NoteSynth] (WAV PCM
/// 16 bits, 44,1 kHz), carregado com `SoLoud.loadMem` e guardado em cache por
/// (notas, duração, instrumento). Assim cada som é uma única voz, que já começa
/// na frequência exata: nada de deslizar até a nota, estalos ou parciais fora
/// de sincronia.
class NotePlayer {
  NotePlayer._();

  static final NotePlayer instance = NotePlayer._();

  static const int _stopFadeMs = 40;

  final SoLoud _engine = SoLoud.instance;
  final Map<String, Future<AudioSource>> _sources = {};
  final Set<SoundHandle> _playing = {};

  Future<void> initialize() => AudioEngine.ensureInitialized();

  Future<void> playNote(
    int midi, {
    NoteInstrument instrument = NoteInstrument.piano,
    int durationMs = 700,
  }) => _play([midi], instrument, durationMs);

  Future<void> playChord(
    List<int> midis, {
    NoteInstrument instrument = NoteInstrument.piano,
    int durationMs = 700,
  }) async {
    if (midis.isEmpty) return;
    await _play(midis, instrument, durationMs);
  }

  Future<void> playSequence(
    List<int> midis, {
    NoteInstrument instrument = NoteInstrument.piano,
    int durationMs = 500,
    int gapMs = 60,
  }) async {
    for (final midi in midis) {
      await playNote(midi, instrument: instrument, durationMs: durationMs);
      if (gapMs > 0) await Future<void>.delayed(Duration(milliseconds: gapMs));
    }
  }

  /// Interrompe tudo com um fade curto, para não estalar.
  Future<void> stopAll() async {
    if (!_engine.isInitialized) return;
    final handles = _playing.toList();
    _playing.clear();
    for (final handle in handles) {
      if (_engine.getIsValidVoiceHandle(handle)) {
        _engine.fadeVolume(
          handle,
          0,
          const Duration(milliseconds: _stopFadeMs),
        );
        _engine.scheduleStop(
          handle,
          const Duration(milliseconds: _stopFadeMs + 10),
        );
      }
    }
  }

  /// Toca o som e só retorna quando ele termina (sustentação + release),
  /// mantendo o mesmo ritmo que as telas já usavam.
  Future<void> _play(
    List<int> midis,
    NoteInstrument instrument,
    int durationMs,
  ) async {
    await initialize();
    final source = await _source(midis, instrument, durationMs);
    final handle = await _engine.play(source);
    _playing.add(handle);
    await Future<void>.delayed(
      Duration(milliseconds: NoteSynth.totalMs(durationMs)),
    );
    _playing.remove(handle);
  }

  Future<AudioSource> _source(
    List<int> midis,
    NoteInstrument instrument,
    int durationMs,
  ) {
    final key = '${instrument.name}_${midis.join('-')}_$durationMs';
    return _sources.putIfAbsent(key, () async {
      try {
        final timbre = instrument == NoteInstrument.piano
            ? SynthTimbre.piano
            : SynthTimbre.guitar;
        final wav = NoteSynth.renderChord(
          midis,
          durationMs: durationMs,
          timbre: timbre,
        );
        return await _engine.loadMem('melodyhub_synth_$key.wav', wav);
      } catch (_) {
        _sources.remove(key);
        rethrow;
      }
    });
  }
}
