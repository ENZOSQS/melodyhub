import 'dart:async';

import 'package:flutter/material.dart';

import '../services/music_audio_service.dart';
import '../services/app_preferences.dart';
import '../theme/app_theme.dart';
import '../utils/guitar_sample_map.dart';
import '../utils/note_names.dart';
import '../utils/orientacao.dart';
import '../widgets/guitar_fretboard.dart';

class GuitarFretboardScreen extends StatefulWidget {
  const GuitarFretboardScreen({super.key});
  @override
  State<GuitarFretboardScreen> createState() => _GuitarFretboardScreenState();
}

class _GuitarFretboardScreenState extends State<GuitarFretboardScreen> {
  static const _tuning = GuitarSampleMap.openMidiNotes;
  static const _strings = ['Mi aguda', 'Si', 'Sol', 'Ré', 'Lá', 'Mi grave'];

  final _audio = MusicAudioService.instance;
  int? _lastMidi;
  (int, int)? _lastPosition;
  bool _loading = true;
  bool _showNoteNames = false;
  String _tipoNota = 'solfejo';

  @override
  void initState() {
    super.initState();
    usarPaisagem();
    _load();
  }

  @override
  void dispose() {
    voltarRetrato();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      _tipoNota = await AppPreferences.noteType();
    } catch (_) {
      _tipoNota = 'solfejo';
    }
    try {
      await _audio.preload([...GuitarSampleMap.fretboardAssets]);
    } catch (error) {
      debugPrint('Não foi possível carregar os samples de violão: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível carregar o áudio do violão.'),
          ),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _play(int string, int fret) async {
    final midi = _tuning[string] + fret;
    setState(() {
      _lastMidi = midi;
      _lastPosition = (string, fret);
    });
    try {
      await _audio.playFor(
        GuitarSampleMap.forPosition(string, fret),
        const Duration(milliseconds: 1900),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível reproduzir essa nota.'),
          ),
        );
      }
    }
  }

  void _handlePosition(int string, int fret, int midi) {
    unawaited(_play(string, fret));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      title: const Text('Braço de violão'),
      actions: [
        TextButton.icon(
          onPressed: () => setState(() => _showNoteNames = !_showNoteNames),
          icon: Icon(_showNoteNames ? Icons.visibility_off : Icons.visibility),
          label: Text(_showNoteNames ? 'Ocultar notas' : 'Ver notas'),
        ),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF34251F), Color(0xFF211A19)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Toque uma corda entre os trastes ou arraste para passear pelo braço.',
                          style: TextStyle(color: AppColors.text, height: 1.4),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Afinação padrão · E A D G B E${_showNoteNames ? ' · Nomes das notas ativados' : ''}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        if (_lastMidi != null) ...[
                          const SizedBox(height: 8),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 160),
                            child: Text(
                              key: ValueKey(_lastMidi),
                              '${nomeNota(_lastMidi!, _tipoNota)} · ${_lastMidi! ~/ 12 - 1}ª oitava  ·  ${_strings[_lastPosition!.$1]} / casa ${_lastPosition!.$2}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 5),
                  child: Text(
                    '6 CORDAS  ·  CASAS 0–12',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                Expanded(
                  child: GuitarFretboard(
                    onPositionPressed: _handlePosition,
                    showNoteNames: _showNoteNames,
                    tipoNota: _tipoNota,
                    activePosition: _lastPosition,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 7, 16, 13),
                  child: Text(
                    'Arraste horizontalmente para alcançar as demais casas. Cada casa reduz o comprimento vibrante da corda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
  );
}
