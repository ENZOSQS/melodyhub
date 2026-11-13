import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_piano_pro/flutter_piano_pro.dart';
import 'package:flutter_piano_pro/note_names.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../services/music_audio_service.dart';
import '../services/app_preferences.dart';
import '../utils/note_names.dart';
import '../utils/sample_map.dart';
import '../widgets/keyboard_octave_selector.dart';

class KeyboardScreen extends StatefulWidget {
  const KeyboardScreen({super.key});

  @override
  State<KeyboardScreen> createState() => _KeyboardScreenState();
}

class _KeyboardScreenState extends State<KeyboardScreen> {
  static const _whiteNoteOffsets = [0, 2, 4, 5, 7, 9, 11];
  static const _blackKeyBoundaries = {1, 2, 4, 5, 6};
  static final Map<LogicalKeyboardKey, int> _keyOffsets = {
    LogicalKeyboardKey.keyZ: 0,
    LogicalKeyboardKey.keyS: 1,
    LogicalKeyboardKey.keyX: 2,
    LogicalKeyboardKey.keyD: 3,
    LogicalKeyboardKey.keyC: 4,
    LogicalKeyboardKey.keyV: 5,
    LogicalKeyboardKey.keyG: 6,
    LogicalKeyboardKey.keyB: 7,
    LogicalKeyboardKey.keyH: 8,
    LogicalKeyboardKey.keyN: 9,
    LogicalKeyboardKey.keyJ: 10,
    LogicalKeyboardKey.keyM: 11,
    LogicalKeyboardKey.keyQ: 12,
    LogicalKeyboardKey.digit2: 13,
    LogicalKeyboardKey.keyW: 14,
    LogicalKeyboardKey.digit3: 15,
    LogicalKeyboardKey.keyE: 16,
    LogicalKeyboardKey.keyR: 17,
    LogicalKeyboardKey.digit5: 18,
    LogicalKeyboardKey.keyT: 19,
    LogicalKeyboardKey.digit6: 20,
    LogicalKeyboardKey.keyY: 21,
    LogicalKeyboardKey.digit7: 22,
    LogicalKeyboardKey.keyU: 23,
  };

  static const _background = Color(0xFF171316);
  static const _panel = Color(0xFF211C20);
  static const _accent = Color(0xFFE9B96E);
  static const _pressedKey = Color(0xFFE9B96E);

  final MusicAudioService _audio = MusicAudioService.instance;
  final Map<int, int> _activeNotes = {};
  final Map<int, SoundHandle> _activeHandles = {};
  final Map<int, Duration> _noteStartTimes = {};
  final Map<LogicalKeyboardKey, int> _physicalPointers = {};
  final Set<SoundHandle> _sustainedHandles = {};
  final List<_RecordedNote> _recordedNotes = [];
  final Stopwatch _recordClock = Stopwatch();
  final ScrollController _pianoScrollController = ScrollController();

  int _octaveCount = 1;
  int _playbackToken = 0;
  bool _loadingAudio = true;
  bool _recording = false;
  bool _playingSong = false;
  bool _sustainEnabled = true;
  bool _showNoteNames = true;
  NoteType _noteType = NoteType.romance;
  String? _audioError;
  bool _centerMiddleCOnOpen = true;

  int get _firstOctave => 3 - ((_octaveCount - 1) ~/ 2);

  @override
  void initState() {
    super.initState();
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      unawaited(
        SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]),
      );
    }
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    final defaultOctaveCount = MediaQuery.sizeOf(context).width >= 1000 ? 2 : 1;
    try {
      final values = await Future.wait([
        _audio.preload(SampleMap.pianoAssets),
        AppPreferences.showKeyboardLabels(),
        AppPreferences.noteType(),
        AppPreferences.keyboardOctaveCount(),
      ]);
      final savedOctaveCount = values[3] as int?;
      if (mounted) {
        setState(() {
          _showNoteNames = values[1] as bool;
          _noteType = (values[2] as String) == 'cifragem'
              ? NoteType.english
              : NoteType.romance;
          _octaveCount = (savedOctaveCount ?? defaultOctaveCount).clamp(1, 4);
          _loadingAudio = false;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingAudio = false;
        _audioError = 'O áudio não carregou. Tente novamente.';
      });
      debugPrint('Falha ao carregar o teclado: $error');
    }
  }

  void _setOctaveCount(int count) {
    final bounded = count.clamp(1, 4);
    if (bounded == _octaveCount) return;
    _releaseAll();
    _releaseSustainedNotes();
    setState(() {
      _octaveCount = bounded;
      _centerMiddleCOnOpen = true;
    });
    unawaited(AppPreferences.setKeyboardOctaveCount(bounded));
  }

  int _midiAt(Offset point, Size size, int whiteKeyCount) {
    if (point.dx < 0 || point.dx >= size.width || point.dy < 0) return -1;
    final whiteWidth = size.width / whiteKeyCount;
    final whiteIndex = (point.dx / whiteWidth).floor();
    final baseMidi = 12 + _firstOctave * 12;
    final blackWidth = whiteWidth * 0.58;
    final blackHeight = size.height * 0.60;

    if (point.dy < blackHeight) {
      for (var boundary = 1; boundary < whiteKeyCount; boundary++) {
        if (!_blackKeyBoundaries.contains(boundary % 7)) continue;
        final center = boundary * whiteWidth;
        if ((point.dx - center).abs() <= blackWidth / 2) {
          final leftWhite = boundary - 1;
          final natural =
              (leftWhite ~/ 7) * 12 + _whiteNoteOffsets[leftWhite % 7];
          return baseMidi + natural + 1;
        }
      }
    }

    return baseMidi +
        (whiteIndex ~/ 7) * 12 +
        _whiteNoteOffsets[whiteIndex % 7];
  }

  void _pointerDown(PointerDownEvent event, Size size, int whiteKeyCount) {
    final midi = _midiAt(event.localPosition, size, whiteKeyCount);
    if (midi >= 0) _startNote(event.pointer, midi);
  }

  void _pointerMove(PointerMoveEvent event, Size size, int whiteKeyCount) {
    final midi = _midiAt(event.localPosition, size, whiteKeyCount);
    if (midi < 0) {
      _releasePointer(event.pointer);
    } else {
      _startNote(event.pointer, midi);
    }
  }

  Future<void> _startNote(int pointer, int midi) async {
    if (_loadingAudio || _audioError != null || _playingSong) return;
    if (_activeNotes[pointer] == midi) return;
    _releasePointer(pointer);

    setState(() {
      _activeNotes[pointer] = midi;
      if (_recording) _noteStartTimes[pointer] = _recordClock.elapsed;
    });

    try {
      final sample = SampleMap.piano(midi);
      final handle = await _audio.startPianoNote(
        sample.file,
        pitchRatio: sample.pitchRatio,
      );
      if (_activeNotes[pointer] == midi) {
        _activeHandles[pointer] = handle;
      } else {
        await _audio.stopPianoNote(handle);
      }
    } catch (error) {
      debugPrint('Falha ao tocar nota MIDI $midi: $error');
    }
  }

  void _releasePointer(int pointer) {
    final midi = _activeNotes.remove(pointer);
    final handle = _activeHandles.remove(pointer);
    final startedAt = _noteStartTimes.remove(pointer);
    if (midi == null) return;

    if (_recording && startedAt != null) {
      final endedAt = _recordClock.elapsed;
      _recordedNotes.add(
        _RecordedNote(
          midi: midi,
          start: startedAt,
          duration: endedAt - startedAt,
        ),
      );
    }
    if (handle != null) {
      if (_sustainEnabled) {
        _sustainedHandles.add(handle);
      } else {
        unawaited(_audio.stopPianoNote(handle));
      }
    }
    if (mounted) setState(() {});
  }

  void _releaseAll() {
    for (final pointer in _activeNotes.keys.toList()) {
      _releasePointer(pointer);
    }
  }

  void _setSustain(bool enabled) {
    setState(() => _sustainEnabled = enabled);
    if (!enabled) _releaseSustainedNotes();
  }

  void _releaseSustainedNotes() {
    final handles = _sustainedHandles.toList();
    _sustainedHandles.clear();
    for (final handle in handles) {
      unawaited(_audio.stopPianoNote(handle));
    }
  }

  KeyEventResult _handleKey(KeyEvent event) {
    final offset = _keyOffsets[event.logicalKey];
    if (event is KeyDownEvent && offset != null) {
      if (!_physicalPointers.containsKey(event.logicalKey)) {
        final pointer = -event.logicalKey.keyId;
        _physicalPointers[event.logicalKey] = pointer;
        _startNote(pointer, 12 + _firstOctave * 12 + offset);
      }
      return KeyEventResult.handled;
    }
    if (event is KeyUpEvent && offset != null) {
      final pointer = _physicalPointers.remove(event.logicalKey);
      if (pointer != null) _releasePointer(pointer);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _toggleRecording() {
    if (_recording) {
      _releaseAll();
      setState(() {
        _recording = false;
        _recordClock.stop();
      });
    } else {
      setState(() {
        _recordedNotes.clear();
        _recordClock
          ..reset()
          ..start();
        _recording = true;
      });
    }
  }

  Future<void> _playRecording() async {
    if (_recordedNotes.isEmpty || _playingSong || _loadingAudio) return;
    _releaseAll();
    _releaseSustainedNotes();
    final token = ++_playbackToken;
    final notes = List<_RecordedNote>.from(_recordedNotes)
      ..sort((a, b) => a.start.compareTo(b.start));
    setState(() => _playingSong = true);

    final clock = Stopwatch()..start();
    try {
      await Future.wait(
        notes.map((note) async {
          final wait = note.start - clock.elapsed;
          if (wait > Duration.zero) await Future<void>.delayed(wait);
          if (!mounted || token != _playbackToken) return;
          final sample = SampleMap.piano(note.midi);
          final handle = await _audio.startPianoNote(
            sample.file,
            pitchRatio: sample.pitchRatio,
          );
          try {
            if (note.duration > Duration.zero) {
              await Future<void>.delayed(note.duration);
            }
          } finally {
            await _audio.stopPianoNote(handle);
          }
        }),
      );
    } catch (error) {
      debugPrint('Falha ao reproduzir a gravação: $error');
      if (mounted && token == _playbackToken) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível tocar a gravação.')),
        );
      }
    } finally {
      if (mounted && token == _playbackToken) {
        setState(() => _playingSong = false);
      }
    }
  }

  void _stopPlayback() {
    ++_playbackToken;
    setState(() => _playingSong = false);
    unawaited(_audio.stopAll());
    _sustainedHandles.clear();
  }

  @override
  void dispose() {
    _recordClock.stop();
    _pianoScrollController.dispose();
    unawaited(_audio.stopAll());
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      unawaited(
        SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]),
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final landscape = viewport.width > viewport.height;
    final octaveCount = _octaveCount;
    final range =
        '${nomeNota(0, _noteType == NoteType.english ? 'cifragem' : 'solfejo')}$_firstOctave–'
        '${nomeNota(11, _noteType == NoteType.english ? 'cifragem' : 'solfejo')}${_firstOctave + octaveCount - 1}';

    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) => _handleKey(event),
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: _background,
          foregroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 16,
          toolbarHeight: landscape ? 42 : 56,
          title: landscape
              ? Text(
                  'Piano acústico · $range',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Teclado Musical',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Piano acústico',
                      style: TextStyle(fontSize: 11, color: Colors.white60),
                    ),
                  ],
                ),
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final whiteKeyCount = _octaveCount * 7;
              final compact = constraints.maxHeight < 410;
              final lastOctave = _firstOctave + (whiteKeyCount ~/ 7) - 1;
              final tipoNome = _noteType == NoteType.english
                  ? 'cifragem'
                  : 'solfejo';
              final rangeLabel =
                  '${nomeNota(0, tipoNome)}$_firstOctave–${nomeNota(11, tipoNome)}$lastOctave';

              return Column(
                children: [
                  if (!compact) _instrumentBar(rangeLabel, compact: compact),
                  _performanceControls(compact: compact),
                  _recordingControls(compact: compact),
                  if (_audioError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Text(
                        _audioError!,
                        style: const TextStyle(color: Colors.orangeAccent),
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 3, 8, 8),
                      child: LayoutBuilder(
                        builder: (context, pianoConstraints) => _buildPiano(
                          whiteKeyCount,
                          pianoConstraints.maxHeight,
                        ),
                      ),
                    ),
                  ),
                  if (_loadingAudio)
                    const LinearProgressIndicator(
                      minHeight: 2,
                      color: _accent,
                      backgroundColor: Colors.transparent,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _instrumentBar(String range, {required bool compact}) => Container(
    margin: EdgeInsets.fromLTRB(12, compact ? 2 : 4, 12, compact ? 3 : 6),
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 4 : 7),
    decoration: BoxDecoration(
      color: _panel,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.piano, color: _accent, size: 22),
        const SizedBox(width: 8),
        const Text(
          'Grand Piano',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            range,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ],
    ),
  );

  Widget _performanceControls({required bool compact}) => Padding(
    padding: EdgeInsets.fromLTRB(10, compact ? 0 : 2, 10, compact ? 1 : 5),
    child: Row(
      children: [
        KeyboardOctaveSelector(
          octaveCount: _octaveCount,
          onChanged: _setOctaveCount,
          compact: compact,
        ),
        const Spacer(),
        _controlChip(
          icon: Icons.music_note,
          label: 'Notas',
          selected: _showNoteNames,
          onPressed: () {
            final value = !_showNoteNames;
            setState(() => _showNoteNames = value);
            unawaited(AppPreferences.setShowKeyboardLabels(value));
          },
          compact: compact,
        ),
        const SizedBox(width: 7),
        _controlChip(
          icon: Icons.surround_sound,
          label: 'Sustain',
          selected: _sustainEnabled,
          onPressed: () => _setSustain(!_sustainEnabled),
          compact: compact,
        ),
      ],
    ),
  );

  Widget _recordingControls({required bool compact}) => Padding(
    padding: EdgeInsets.fromLTRB(12, compact ? 1 : 4, 12, compact ? 1 : 5),
    child: Row(
      children: [
        Expanded(
          child: SizedBox(
            height: compact ? 34 : 40,
            child: FilledButton.icon(
              onPressed: _playingSong ? null : _toggleRecording,
              style: FilledButton.styleFrom(
                backgroundColor: _recording
                    ? const Color(0xFFB93845)
                    : const Color(0xFF30272C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              icon: Icon(
                _recording ? Icons.stop_rounded : Icons.fiber_manual_record,
                size: 18,
              ),
              label: Text(_recording ? 'Parar' : 'Gravar'),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: compact ? 34 : 40,
            child: FilledButton.icon(
              onPressed: _playingSong
                  ? _stopPlayback
                  : _recordedNotes.isEmpty
                  ? null
                  : _playRecording,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF70502E),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF30272C),
                disabledForegroundColor: Colors.white38,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              icon: Icon(
                _playingSong ? Icons.stop_rounded : Icons.play_arrow_rounded,
                size: 20,
              ),
              label: Text(_playingSong ? 'Parar música' : 'Ouvir'),
            ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'Apagar gravação',
          onPressed: _recording || _playingSong || _recordedNotes.isEmpty
              ? null
              : () => setState(_recordedNotes.clear),
          icon: const Icon(Icons.delete_outline, color: Colors.white70),
        ),
      ],
    ),
  );

  Widget _buildPiano(int whiteKeyCount, double height) {
    final activeColors = <int, Color>{
      for (final midi in _activeNotes.values) midi: _pressedKey,
    };

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF100D10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      padding: const EdgeInsets.all(4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportWidth = constraints.maxWidth;
          final keyWidth = viewportWidth / whiteKeyCount;
          final contentWidth = keyWidth < 36
              ? whiteKeyCount * 36.0
              : viewportWidth;
          if (_centerMiddleCOnOpen) {
            _centerMiddleCOnOpen = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_pianoScrollController.hasClients) return;
              final centralCIndex =
                  (_firstOctave <= 3 ? 3 - _firstOctave : 0) * 7;
              final centralCX = centralCIndex * (contentWidth / whiteKeyCount);
              final offset = (centralCX - viewportWidth / 2)
                  .clamp(0.0, math.max(0.0, contentWidth - viewportWidth))
                  .toDouble();
              _pianoScrollController.jumpTo(offset);
            });
          }
          final keySize = Size(contentWidth, constraints.maxHeight);
          return SingleChildScrollView(
            controller: _pianoScrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: contentWidth,
              height: constraints.maxHeight,
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (event) =>
                    _pointerDown(event, keySize, whiteKeyCount),
                onPointerMove: (event) =>
                    _pointerMove(event, keySize, whiteKeyCount),
                onPointerUp: (event) => _releasePointer(event.pointer),
                onPointerCancel: (event) => _releasePointer(event.pointer),
                child: PianoPro(
                  noteCount: whiteKeyCount,
                  expand: true,
                  whiteHeight: height - 8,
                  showNames: _showNoteNames,
                  showOctave: true,
                  firstNoteIndex: 0,
                  firstOctave: _firstOctave,
                  noteType: _noteType,
                  buttonColors: activeColors,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _controlChip({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onPressed,
    required bool compact,
  }) => Material(
    color: selected ? const Color(0xFF70502E) : _panel,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 5 : 7,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? _accent : Colors.white70),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RecordedNote {
  const _RecordedNote({
    required this.midi,
    required this.start,
    required this.duration,
  });

  final int midi;
  final Duration start;
  final Duration duration;
}
