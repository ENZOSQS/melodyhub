import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../services/app_preferences.dart';
import 'guitar_fretboard_screen.dart';
import 'guitar_note_exercise_screen.dart';
import 'keyboard_screen.dart';
import 'history_screen.dart';
import 'learning_path_screen.dart';
import 'music_concepts_screen.dart';
import 'performance_screen.dart';
import 'rhythm_exercise_screen.dart';

class _Activity {
  const _Activity(
    this.title,
    this.description,
    this.level,
    this.icon,
    this.builder,
    this.kind, {
    this.instrumentos = const [],
  });
  final String title, description, level, kind;
  final IconData icon;
  final Widget Function() builder;
  final List<String> instrumentos;
}

class ExerciseCatalogScreen extends StatefulWidget {
  const ExerciseCatalogScreen({super.key});
  @override
  State<ExerciseCatalogScreen> createState() => _ExerciseCatalogScreenState();
}

class _ExerciseCatalogScreenState extends State<ExerciseCatalogScreen> {
  final _search = TextEditingController();
  String _kind = 'Todos';
  String _level = 'Todos';
  String _instrument = 'Todos';

  @override
  void initState() {
    super.initState();
    AppPreferences.catalogInstrument().then((value) {
      if (mounted && ['Todos', 'Teclado', 'Violão'].contains(value)) {
        setState(() => _instrument = value);
      }
    });
  }

  Future<void> _setInstrument(String value) async {
    setState(() => _instrument = value);
    await AppPreferences.setCatalogInstrument(value);
  }

  late final List<_Activity> _activities = [
    _Activity(
      'Prática: reconhecer notas',
      'Ouça e responda no ritmo que funciona para você.',
      'Iniciante',
      Icons.hearing,
      () => const LearningPathScreen(track: LearningTrack.pratica),
      'Prática',
      instrumentos: const ['Teclado'],
    ),
    _Activity(
      'Intervalos auditivos',
      'Compare duas notas e aprenda a reconhecer a distância entre elas.',
      'Iniciante',
      Icons.graphic_eq,
      () => const LearningPathScreen(track: LearningTrack.intervalos),
      'Audição',
      instrumentos: const ['Teclado'],
    ),
    _Activity(
      'Teoria musical',
      'Conceitos organizados em fases de dificuldade crescente.',
      'Iniciante',
      Icons.menu_book,
      () => const LearningPathScreen(track: LearningTrack.teoria),
      'Teoria',
    ),
    _Activity(
      'Ditado rítmico',
      'Ouça o padrão, conte o pulso e repita tocando na tela.',
      'Iniciante',
      Icons.timer,
      () => const RhythmExerciseScreen(),
      'Ritmo',
    ),
    _Activity(
      'Escalas',
      'Reconheça a sonoridade maior, menor e pentatônica.',
      'Intermediário',
      Icons.show_chart,
      () => const MusicConceptsScreen(exercise: ConceptExercise.scale),
      'Harmonia',
    ),
    _Activity(
      'Acordes',
      'Treine a diferença entre acordes maiores, menores e outras cores.',
      'Intermediário',
      Icons.piano,
      () => const MusicConceptsScreen(exercise: ConceptExercise.chord),
      'Harmonia',
      instrumentos: const ['Teclado'],
    ),
    _Activity(
      'Violão: identificar notas',
      'Ouça uma nota e encontre a mesma altura em qualquer corda ou casa.',
      'Iniciante',
      Icons.music_note,
      () => const GuitarNoteExerciseScreen(),
      'Prática',
      instrumentos: const ['Violão'],
    ),
    _Activity(
      'Histórico de estudo',
      'Revise suas respostas, duração e evolução.',
      'Todos',
      Icons.history,
      () => const HistoryScreen(),
      'Progresso',
    ),
    _Activity(
      'Relatório de desempenho',
      'Veja acertos e habilidades que merecem revisão.',
      'Todos',
      Icons.insights,
      () => const PerformanceScreen(),
      'Progresso',
    ),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _activities.where((item) {
      final query = _search.text.trim().toLowerCase();
      return (query.isEmpty ||
              '${item.title} ${item.description} ${item.kind}'
                  .toLowerCase()
                  .contains(query)) &&
          (_kind == 'Todos' || item.kind == _kind) &&
          (_instrument == 'Todos' || item.instrumentos.contains(_instrument)) &&
          (_level == 'Todos' || item.level == 'Todos' || item.level == _level);
    }).toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: Colors.white,
        title: const Text('Explorar atividades'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Escolha uma habilidade para praticar. Cada exercício registra seu progresso e oferece feedback para aprender com as respostas.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar habilidade ou exercício',
            ),
          ),
          const SizedBox(height: 10),
          _filter('Habilidade', _kind, [
            'Todos',
            'Prática',
            'Audição',
            'Teoria',
            'Ritmo',
            'Harmonia',
            'Progresso',
          ], (value) => setState(() => _kind = value)),
          _filter('Nível', _level, [
            'Todos',
            'Iniciante',
            'Intermediário',
            'Avançado',
          ], (value) => setState(() => _level = value)),
          _filter('Instrumento', _instrument, [
            'Todos',
            'Teclado',
            'Violão',
          ], _setInstrument),
          if (_instrument != 'Todos') ...[
            const SizedBox(height: 8),
            Card(
              color: AppColors.surface,
              child: ListTile(
                leading: Icon(
                  _instrument == 'Violão' ? Icons.music_note : Icons.piano,
                  color: AppColors.primary,
                ),
                title: Text(
                  'Abrir simulador de $_instrument',
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: const Icon(Icons.open_in_new, color: Colors.white70),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _instrument == 'Violão'
                        ? const GuitarFretboardScreen()
                        : const KeyboardScreen(),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Nenhuma atividade encontrada. Ajuste os filtros.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ...visible.map(
            (activity) => Card(
              color: AppColors.surface,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.surfaceRaised,
                  child: Icon(activity.icon, color: AppColors.primary),
                ),
                title: Text(
                  activity.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${activity.description}\n${activity.kind} · ${activity.level}',
                  style: const TextStyle(color: Colors.white60, height: 1.45),
                ),
                isThreeLine: true,
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.white60,
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => activity.builder()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filter(
    String label,
    String value,
    List<String> values,
    ValueChanged<String> onSelected,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(label, style: const TextStyle(color: Colors.white70)),
        ),
        Expanded(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: AppColors.surface,
            style: const TextStyle(color: Colors.white),
            items: values
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) {
              if (v != null) onSelected(v);
            },
          ),
        ),
      ],
    ),
  );
}
