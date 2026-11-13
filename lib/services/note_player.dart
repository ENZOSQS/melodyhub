import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_soloud/flutter_soloud.dart';

enum NoteInstrument { piano, guitar }

const standardGuitarOpenMidis = [64, 59, 55, 50, 45, 40];

/// Sintetiza notas MIDI com parciais via SoLoud, sem samples instrumentais.
class NotePlayer {
  NotePlayer._();

  static final NotePlayer instance = NotePlayer._();

  static const int _attackMs = 5;
  static const int _releaseMs = 300;
  static const double _maxGain = 0.24;
  final SoLoud _engine = SoLoud.instance;
  final Map<(int, NoteInstrument, int, WaveForm), Future<AudioSource>>
  _sources = {};
  final Set<SoundHandle> _playing = {};
  final Set<SoundHandle> _releasing = {};
  final Map<SoundHandle, double> _peakVolumes = {};
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
    // Dividing by the number of notes bounds the sum even for four-note chords.
    final chordGain = 1 / midis.length;
    for (final midi in midis) {
      handles.addAll(await _start(midi, instrument, chordGain));
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

  Future<void> stopAll() async => _release(_playing.toList());

  Future<List<SoundHandle>> _start(
    int midi,
    NoteInstrument instrument,
    double chordGain,
  ) async {
    if (midi < 0 || midi > 127) throw RangeError.range(midi, 0, 127, 'midi');
    await initialize();
    final partials = instrument == NoteInstrument.piano
        ? const [
            (1, WaveForm.sin, 1.0),
            (2, WaveForm.sin, 0.35),
            (3, WaveForm.sin, 0.12),
          ]
        : const [(1, WaveForm.triangle, 1.0), (2, WaveForm.sin, 0.25)];
    final totalWeight = partials.fold<double>(
      0,
      (total, partial) => total + partial.$3,
    );
    final handles = <SoundHandle>[];
    for (final partial in partials) {
      final source = await _source(midi, instrument, partial.$1, partial.$2);
      final peak = _maxGain * chordGain * partial.$3 / totalWeight;
      final handle = await _engine.play(source, volume: 0, looping: true);
      _engine.fadeVolume(handle, peak, const Duration(milliseconds: _attackMs));
      _playing.add(handle);
      _peakVolumes[handle] = peak;
      handles.add(handle);
    }
    unawaited(_decay(handles, instrument));
    return handles;
  }

  Future<AudioSource> _source(
    int midi,
    NoteInstrument instrument,
    int harmonic,
    WaveForm waveform,
  ) => _sources.putIfAbsent((midi, instrument, harmonic, waveform), () async {
    final source = await _engine.loadWaveform(waveform, false, 1, 0);
    final fundamental = 440 * math.pow(2, (midi - 69) / 12);
    _engine.setWaveformFreq(source, (fundamental * harmonic).toDouble());
    return source;
  });

  Future<void> _decay(
    List<SoundHandle> handles,
    NoteInstrument instrument,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: _attackMs));
    final decayMs = instrument == NoteInstrument.piano ? 800 : 500;
    final sustain = instrument == NoteInstrument.piano ? 0.35 : 0.20;
    for (final handle in handles) {
      final peak = _peakVolumes[handle];
      if (peak != null &&
          _playing.contains(handle) &&
          !_releasing.contains(handle) &&
          _engine.getIsValidVoiceHandle(handle)) {
        _engine.fadeVolume(
          handle,
          peak * sustain,
          Duration(milliseconds: decayMs),
        );
      }
    }
  }

  Future<void> _release(Iterable<SoundHandle> handles) async {
    final active = handles.where(_playing.contains).toList();
    for (final handle in active) {
      _releasing.add(handle);
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
      _releasing.remove(handle);
      _peakVolumes.remove(handle);
    }
  }
}
