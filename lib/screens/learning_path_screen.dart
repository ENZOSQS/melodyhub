import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/progress_service.dart';
import 'exercises_screen.dart';
import 'interval_exercises_screen.dart';
import 'theory_exercises_screen.dart';

enum LearningTrack { teoria, pratica, intervalos }

class LearningPathScreen extends StatefulWidget {
  const LearningPathScreen({super.key, this.track = LearningTrack.teoria});

  final LearningTrack track;

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen> {
  static const _background = Color(0xFF0B1736);
  static const _accent = Color(0xFF16D9C5);
  final _progress = ProgressService();
  late LearningTrack _track;
  Map<String, dynamic> _data = {};
  bool _loading = true;
  String? _error;

  static const _titles = {
    LearningTrack.teoria: [
      'Primeiras notas',
      'Ritmo e intervalos',
      'Escalas e acordes',
      'Harmonia avançada',
      'Desafio especialista',
    ],
    LearningTrack.pratica: [
      'Uma nota de cada vez',
      'Primeiras sequências',
      'Memória em movimento',
      'Sequências avançadas',
      'Concerto final',
    ],
    LearningTrack.intervalos: [
      'Segundas e terças',
      'Quarta justa',
      'Quintas',
      'Sextas e direção',
      'Ouvido especialista',
    ],
  };

  @override
  void initState() {
    super.initState();
    _track = widget.track;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _progress.buscarProgresso();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Não foi possível carregar o mapa. Verifique sua conexão.';
          _loading = false;
        });
      }
    }
  }

  String get _levelKey => switch (_track) {
    LearningTrack.teoria => 'nivelTeoria',
    LearningTrack.pratica => 'nivelPratico',
    LearningTrack.intervalos => 'nivelIntervalos',
  };

  String get _stageMapKey => switch (_track) {
    LearningTrack.teoria => 'teoriaEtapas',
    LearningTrack.pratica => 'praticaEtapas',
    LearningTrack.intervalos => 'intervaloEtapas',
  };

  String get _trackName => switch (_track) {
    LearningTrack.teoria => 'Trilha teórica',
    LearningTrack.pratica => 'Trilha prática',
    LearningTrack.intervalos => 'Intervalos auditivos',
  };

  int get _currentLevel {
    final value = _data[_levelKey];
    return (value is num ? value.toInt() : 1).clamp(1, 5).toInt();
  }

  Future<void> _openStage(int level) async {
    if (level > _currentLevel) return;
    final page = switch (_track) {
      LearningTrack.teoria => TheoryExercisesScreen(nivelSelecionado: level),
      LearningTrack.pratica => ExercisesScreen(nivelSelecionado: level),
      LearningTrack.intervalos => IntervalExercisesScreen(
        nivelSelecionado: level,
      ),
    };
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _load();
  }

  Map<String, dynamic> _stageStats(int level) {
    final stages = Map<String, dynamic>.from(
      _data[_stageMapKey] as Map? ?? const <String, dynamic>{},
    );
    return Map<String, dynamic>.from(
      stages['$level'] as Map? ?? const <String, dynamic>{},
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuário não autenticado.')),
      );
    }
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        title: const Text('Jornada musical'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _load,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: LearningTrack.values.map((track) {
                      return ChoiceChip(
                        label: Text(switch (track) {
                          LearningTrack.teoria => 'Teoria',
                          LearningTrack.pratica => 'Prática',
                          LearningTrack.intervalos => 'Intervalos',
                        }),
                        selected: _track == track,
                        onSelected: (_) => setState(() => _track = track),
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Text(
                    '$_trackName · fase $_currentLevel de 5',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
                    itemCount: 9,
                    itemBuilder: (context, index) {
                      if (index.isOdd) {
                        return const SizedBox(
                          height: 30,
                          child: Center(
                            child: SizedBox(
                              width: 4,
                              child: ColoredBox(color: Colors.white24),
                            ),
                          ),
                        );
                      }
                      final level = index ~/ 2 + 1;
                      final unlocked = level <= _currentLevel;
                      final stats = _stageStats(level);
                      final completed =
                          level < _currentLevel ||
                          (level == _currentLevel &&
                              stats['concluida'] == true);
                      final tries = stats['tentativas'] is num
                          ? (stats['tentativas'] as num).toInt()
                          : 0;
                      final correct = stats['acertos'] is num
                          ? (stats['acertos'] as num).toInt()
                          : 0;
                      final left = level.isOdd;
                      return Align(
                        alignment: left
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: SizedBox(
                          width: MediaQuery.sizeOf(context).width * 0.76,
                          child: _stageCard(
                            level: level,
                            title: _titles[_track]![level - 1],
                            unlocked: unlocked,
                            completed: completed,
                            attempts: tries,
                            correct: correct,
                            onTap: unlocked ? () => _openStage(level) : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _stageCard({
    required int level,
    required String title,
    required bool unlocked,
    required bool completed,
    required int attempts,
    required int correct,
    required VoidCallback? onTap,
  }) {
    final color = completed
        ? Colors.amber
        : unlocked
        ? _accent
        : Colors.white24;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: unlocked ? Colors.white : const Color(0xFF182544),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 2),
          boxShadow: unlocked
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.14),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: color,
              child: Icon(
                completed
                    ? Icons.star_rounded
                    : unlocked
                    ? Icons.play_arrow_rounded
                    : Icons.lock_rounded,
                color: _background,
                size: 27,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fase $level',
                    style: TextStyle(
                      color: unlocked ? Colors.black54 : Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      color: unlocked ? _background : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    !unlocked
                        ? 'Conclua a fase anterior para liberar'
                        : completed
                        ? 'Concluída · $correct acertos em $attempts tentativas'
                        : 'Fase atual · toque para continuar',
                    style: TextStyle(
                      color: unlocked ? Colors.black54 : Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (completed)
              const Text(
                'Refazer',
                style: TextStyle(
                  color: _background,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
