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
      final sample = GuitarSampleMap.forPosition(string, fret);
      await _audio.playFor(
        sample.file,
        const Duration(milliseconds: 1900),
        pitchRatio: sample.pitchRatio,
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

  Future<void> _showInstructions() => showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    builder: (context) => const SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Como tocar o braço',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Toque ou arraste sobre uma corda para ouvir a nota. Deslize o braço horizontalmente para chegar às casas 9–12. Cada casa encurta a corda e aumenta a altura do som.',
              style: TextStyle(color: AppColors.muted, height: 1.5),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Braço de violão'),
          Text(
            'Afinação padrão · E A D G B E${_lastMidi == null ? '' : '  ·  ${nomeNota(_lastMidi!, _tipoNota)}'}',
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Como tocar',
          onPressed: _showInstructions,
          icon: const Icon(Icons.info_outline_rounded),
        ),
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
                Expanded(
                  child: GuitarFretboard(
                    onPositionPressed: _handlePosition,
                    showNoteNames: _showNoteNames,
                    tipoNota: _tipoNota,
                    activePosition: _lastPosition,
                  ),
                ),
              ],
            ),
          ),
  );
}
