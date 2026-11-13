import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_soloud/flutter_soloud.dart';

enum NoteInstrument { piano, guitar }

const standardGuitarOpenMidis = [64, 59, 55, 50, 45, 40];

/// Sintetiza notas MIDI com senoidal + triangular usando o SoLoud.
class NotePlayer {
  NotePlayer._();

  static final NotePlayer instance = NotePlayer._();

  static const int _attackMs = 5;
  static const int _releaseMs = 300;
  static const double _maxGain = 0.24;
  final SoLoud _engine = SoLoud.instance;
  final Map<(int, NoteInstrument, WaveForm), Future<AudioSource>> _sources = {};
  final Set<SoundHandle> _playing = {};
  Future<void>? _initialization;

  Future<void> initialize() => _initialization ??= _engine.init();

  Future<void> playNote(
    int midi, {
    NoteInstrument instrument = NoteInstrument.piano,
    int durationMs = 700,
  }) async {
    final handles = await _start(midi, instrument, 1);
    await Future<void>.delayed(Duration(milliseconds: durationMs));
    await _release(handles);
  }

  Future<void> playChord(
    List<int> midis, {
    NoteInstrument instrument = NoteInstrument.piano,
    int durationMs = 700,
  }) async {
    if (midis.isEmpty) return;
    final handles = <SoundHandle>[];
    final gain = 1 / math.sqrt(midis.length);
    for (final midi in midis) {
      handles.addAll(await _start(midi, instrument, gain));
    }
    await Future<void>.delayed(Duration(milliseconds: durationMs));
    await _release(handles);
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

  /// Starts a sustained note for touch and computer-keyboard instruments.
  Future<List<SoundHandle>> startNote(
    int midi, {
    NoteInstrument instrument = NoteInstrument.piano,
  }) => _start(midi, instrument, 1);

  Future<void> stopNote(List<SoundHandle> handles) => _release(handles);

  Future<void> stopAll() async {
    await _release(_playing.toList());
  }

  Future<List<SoundHandle>> _start(
    int midi,
    NoteInstrument instrument,
    double chordGain,
  ) async {
    if (midi < 0 || midi > 127) throw RangeError.range(midi, 0, 127, 'midi');
    await initialize();
    final frequency = (440 * math.pow(2, (midi - 69) / 12)).toDouble();
    final sine = await _source(midi, instrument, WaveForm.sin);
    final triangle = await _source(midi, instrument, WaveForm.triangle);
    final instrumentGain = instrument == NoteInstrument.piano ? 0.16 : 0.20;
    final handles = <SoundHandle>[];
    for (final entry in [
      (sine, _maxGain * instrumentGain * chordGain),
      (triangle, _maxGain * (1 - instrumentGain) * chordGain),
    ]) {
      final handle = await _engine.play(entry.$1, looping: true);
      _engine.setWaveformFreq(entry.$1, frequency);
      _engine.setVolume(handle, 0);
      _engine.fadeVolume(
        handle,
        entry.$2,
        const Duration(milliseconds: _attackMs),
      );
      _playing.add(handle);
      handles.add(handle);
    }
    return handles;
  }

  Future<AudioSource> _source(
    int midi,
    NoteInstrument instrument,
    WaveForm waveform,
  ) => _sources.putIfAbsent((midi, instrument, waveform), () async {
    final source = await _engine.loadWaveform(waveform, false, 1, 0);
    _engine.setWaveformFreq(
      source,
      (440 * math.pow(2, (midi - 69) / 12)).toDouble(),
    );
    return source;
  });

  Future<void> _release(Iterable<SoundHandle> handles) async {
    final active = handles.where(_playing.contains).toList();
    for (final handle in active) {
      if (_engine.getIsValidVoiceHandle(handle)) {
        _engine.fadeVolume(handle, 0, const Duration(milliseconds: _releaseMs));
      }
    }
    if (active.isNotEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: _releaseMs));
    }
    for (final handle in active) {
      if (_engine.getIsValidVoiceHandle(handle)) await _engine.stop(handle);
      _playing.remove(handle);
    }
  }
}
