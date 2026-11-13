import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../services/app_preferences.dart';
import '../services/note_player.dart';
import '../services/progress_service.dart';
import '../utils/note_names.dart';
import '../widgets/piano_answer_keyboard.dart';
import '../data/theory_explanations.dart';
import '../widgets/theory_explanation_sheet.dart';

enum ConceptExercise { scale, chord }

class MusicConceptsScreen extends StatefulWidget {
  const MusicConceptsScreen({super.key, required this.exercise});
  final ConceptExercise exercise;

  @override
  State<MusicConceptsScreen> createState() => _MusicConceptsScreenState();
}

class _MusicConceptsScreenState extends State<MusicConceptsScreen> {
  static const _scaleData = <String, List<int>>{
    'Maior': [0, 2, 4, 5, 7, 9, 11, 12],
    'Menor natural': [0, 2, 3, 5, 7, 8, 10, 12],
    'Pentatônica maior': [0, 2, 4, 7, 9, 12],
    'Pentatônica menor': [0, 3, 5, 7, 10, 12],
  };
  static const _chordData = <String, List<int>>{
    'Maior': [0, 4, 7],
    'Menor': [0, 3, 7],
    'Diminuto': [0, 3, 6],
    'Aumentado': [0, 4, 8],
  };

  final _random = Random();
  final _progress = ProgressService();
  final _notePlayer = NotePlayer.instance;
  int _level = 1;
  int _root = 0;
  bool _loading = true;
  bool _playing = false;
  bool _saving = false;
  bool _showHint = false;
  bool? _correct;
  String? _answer;
  String? _noteType;
  final Set<int> _chordMidiSelection = <int>{};
  Map<String, List<int>> get _options {
    if (widget.exercise == ConceptExercise.scale) {
      return Map.fromEntries(
        _scaleData.entries.where(
          (e) => _level < 2
              ? e.key == 'Maior' || e.key == 'Menor natural'
              : _level < 3
              ? e.key != 'Pentatônica menor'
              : true,
        ),
      );
    }
    return Map.fromEntries(
      _chordData.entries.where(
        (e) => _level < 2
            ? e.key == 'Maior' || e.key == 'Menor'
            : _level < 3
            ? e.key != 'Aumentado'
            : true,
      ),
    );
  }

  String get _type =>
      widget.exercise == ConceptExercise.scale ? 'Escala' : 'Acorde';
  String get _skill =>
      widget.exercise == ConceptExercise.scale ? 'escalas' : 'acordes';
  String get _title => widget.exercise == ConceptExercise.scale
      ? 'Reconhecer escalas'
      : 'Reconhecer acordes';
  String get _noteName => nomeNota(_root, _noteType ?? 'solfejo');
  int _midi(int semitone) => 48 + _root + semitone;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final data = await _progress.buscarProgresso();
      final skills = Map<String, dynamic>.from(
        data['habilidadesEtapas'] as Map? ?? {},
      );
      final skill = Map<String, dynamic>.from(skills[_skill] as Map? ?? {});
      _level = (skill['nivel'] as num?)?.toInt().clamp(1, 5) ?? 1;
      _noteType = await AppPreferences.noteType();
      await _notePlayer.initialize();
    } catch (_) {
      _noteType = 'solfejo';
    }
    if (mounted) setState(() => _loading = false);
    if (mounted) unawaited(_playQuestion());
  }

  Future<void> _playQuestion({bool newQuestion = true}) async {
    if (_playing || _saving || _loading) return;
    setState(() {
      _playing = true;
      if (newQuestion) {
        _correct = null;
        _answer = null;
        _showHint = false;
        _chordMidiSelection.clear();
        _root = _random.nextInt(12);
        final choices = _options.keys.toList();
        _answer = choices[_random.nextInt(choices.length)];
      }
    });
    try {
      final intervals = _options[_answer]!;
      if (widget.exercise == ConceptExercise.scale) {
        for (final semitone in intervals) {
          await _notePlayer.playNote(_midi(semitone), durationMs: 280);
          await Future<void>.delayed(const Duration(milliseconds: 55));
        }
      } else {
        await _notePlayer.playChord(
          intervals.map(_midi).toList(),
          durationMs: 850,
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível tocar o som. Confira o volume e toque em Ouvir novamente.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _playing = false);
    }
  }

  Future<void> _select(String choice) async {
    if (_correct != null || _saving || _answer == null) return;
    final correct = choice == _answer;
    await _submit(correct, choice);
  }

  Future<void> _submit(bool correct, String response) async {
    if (_correct != null || _saving || _answer == null) return;
    setState(() {
      _correct = correct;
      _saving = true;
    });
    try {
      await _progress.registrarExercicio(
        acertou: correct,
        tipo: _type,
        pergunta:
            'Identifique ${widget.exercise == ConceptExercise.scale ? 'a escala' : 'a qualidade do acorde'} ouvido na nota $_noteName.',
        resposta: response,
        respostaCorreta: _answer,
        dificuldade: _level,
        categoria: widget.exercise == ConceptExercise.scale
            ? 'Escalas'
            : 'Acordes',
        itemAvaliado: _answer,
      );
      final data = await _progress.buscarProgresso();
      final skills = Map<String, dynamic>.from(
        data['habilidadesEtapas'] as Map? ?? {},
      );
      final skill = Map<String, dynamic>.from(skills[_skill] as Map? ?? {});
      if (mounted) {
        setState(() {
          _level = (skill['nivel'] as num?)?.toInt().clamp(1, 5) ?? _level;
          _saving = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar o progresso.')),
        );
      }
    }
  }

  Future<void> _pressChordKey(int midi) async {
    if (_correct != null || _saving || _playing) return;
    setState(() {
      if (_chordMidiSelection.contains(midi)) {
        _chordMidiSelection.remove(midi);
      } else if (_chordMidiSelection.length < 3) {
        _chordMidiSelection.add(midi);
      }
    });
    try {
      await _notePlayer.playNote(midi, durationMs: 520);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível tocar o som. Confira o volume e tente novamente.',
            ),
          ),
        );
      }
    }
    if (!mounted || _chordMidiSelection.length != 3) return;
    final expected = _options[_answer]!
        .map((interval) => (_root + interval) % 12)
        .toSet();
    final actual = _chordMidiSelection.map((note) => note % 12).toSet();
    final pickedNames = _chordMidiSelection
        .map((note) => nomeNota(note, _noteType ?? 'solfejo'))
        .join(', ');
    await _submit(
      actual.length == 3 && actual.containsAll(expected),
      pickedNames,
    );
  }

  String _explanation() {
    final intervals = _options[_answer]!;
    final label = intervals.map((n) => '$n semitons').join(', ');
    if (widget.exercise == ConceptExercise.scale) {
      return 'A escala $_answer tem os graus separados por $label. Ouça se o 3º grau soa maior (4 semitons) ou menor (3 semitons); depois compare a cor dos demais intervalos. Tônica: $_noteName.';
    }
    return 'O acorde $_answer é formado pelos intervalos $label a partir da fundamental $_noteName. Compare a terça: 4 semitons tende à sonoridade maior; 3 semitons, menor. O diminuto reduz também a quinta.';
  }

  Future<void> _openTheory() => showTheoryExplanationSheet(
    context,
    explanation: TheoryExplanation(
      objective: theoryObjectiveForCategory(
        widget.exercise == ConceptExercise.scale ? 'Escalas' : 'Acordes',
      ),
      theory: _explanation(),
    ),
    theory: _explanation(),
    onPlayExample: _playing ? null : () => _playQuestion(newQuestion: false),
    exampleLabel: 'Ouvir este exemplo novamente',
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF171316),
    appBar: AppBar(
      backgroundColor: const Color(0xFF171316),
      foregroundColor: Colors.white,
      title: Text(_title),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Text(
                        'Nível $_level · progressão gradual',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.exercise == ConceptExercise.scale
                            ? 'Escute a sequência e identifique sua família. Primeiro compare maior e menor; as formas pentatônicas aparecem depois.'
                            : 'Escute as notas simultâneas e identifique a qualidade do acorde. Comece distinguindo maior e menor.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fundamental de referência: $_noteName',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _playing
                    ? null
                    : () => _playQuestion(newQuestion: false),
                icon: Icon(_playing ? Icons.graphic_eq : Icons.replay),
                label: Text(_playing ? 'Escutando…' : 'Ouvir novamente'),
              ),
              const SizedBox(height: 8),
              if (widget.exercise == ConceptExercise.chord) ...[
                const Text(
                  'Monte o acorde tocando as três notas no piano. A fundamental está indicada acima.',
                  style: TextStyle(color: Colors.white, height: 1.4),
                ),
                const SizedBox(height: 10),
                PianoAnswerKeyboard(
                  firstMidi: 48,
                  noteCount: 12,
                  enabled: !_playing && !_saving && _correct == null,
                  selectedMidi: _chordMidiSelection,
                  tipoNota: _noteType ?? 'solfejo',
                  onNotePressed: _pressChordKey,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _correct == null && !_saving
                        ? () => setState(_chordMidiSelection.clear)
                        : null,
                    icon: const Icon(Icons.backspace_outlined),
                    label: const Text('Limpar notas'),
                  ),
                ),
              ] else ...[
                const Text(
                  'Ouça, compare a terça e escolha a família sonora. Você pode repetir o trecho antes de responder.',
                  style: TextStyle(color: Colors.white, height: 1.4),
                ),
                const SizedBox(height: 8),
                ..._options.keys.map(
                  (name) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: FilledButton.tonal(
                      onPressed: _playing || _saving
                          ? null
                          : () => _select(name),
                      child: Text(name),
                    ),
                  ),
                ),
              ],
              if (_correct != null)
                Card(
                  color: _correct!
                      ? const Color(0xFFEFE0CF)
                      : const Color(0xFFFFE8E5),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      '${_correct! ? 'Correto!' : 'Resposta: $_answer.'} ${_explanation()}',
                      style: const TextStyle(
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _playing
                        ? null
                        : () => setState(() => _showHint = !_showHint),
                    icon: const Icon(Icons.lightbulb_outline),
                    label: Text(
                      _showHint ? 'Ocultar dica' : 'Preciso de uma dica',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _openTheory,
                    icon: const Icon(Icons.menu_book),
                    label: const Text('Entenda a teoria'),
                  ),
                ],
              ),
              if (_showHint)
                Card(
                  color: const Color(0xFFEFE0CF),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      widget.exercise == ConceptExercise.scale
                          ? 'Tente acompanhar o caminho entre os sons. Uma escala maior costuma ter uma terça mais aberta; a menor natural tem terça e sexta menores. Ouça de novo, sem pressa.'
                          : 'Ouça principalmente a distância entre as duas primeiras notas e depois a estabilidade da quinta. Se ajudar, cante a fundamental e compare a terça do acorde.',
                      style: const TextStyle(
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              if (_correct != null && !_saving)
                FilledButton.icon(
                  onPressed: _playQuestion,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Próximo exercício'),
                ),
              if (_saving)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
  );
}
