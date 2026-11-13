import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/mh_ui.dart';
import '../services/app_preferences.dart';
import 'guitar_fretboard_screen.dart';
import 'guitar_note_exercise_screen.dart';
import 'keyboard_screen.dart';
import 'history_screen.dart';
import 'learning_path_screen.dart';
import 'music_concepts_screen.dart';
import 'performance_screen.dart';
import 'profile_screen.dart';
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
      'Identificar a nota',
      'Ouça a nota dentro do tom de Dó e descubra qual é.',
      'Iniciante',
      Icons.hearing,
      () => const LearningPathScreen(track: LearningTrack.pratica),
      'Prática',
      instrumentos: const ['Teclado'],
    ),
    _Activity(
      'Intervalos auditivos',
      'Ouça duas notas e diga qual é a distância entre elas.',
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
      'Andamento (BPM)',
      'Ouça um andamento e ajuste o BPM até ficar igual.',
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            MelodyHeader(
              onNotificacoes: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
            ),
            const MhPageTitle('Aprender'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Instrumento',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (valor, icone) in const [
                        ('Todos', null),
                        ('Teclado', Icons.piano_outlined),
                        ('Violão', Icons.music_note_outlined),
                      ])
                        MhChoiceChip(
                          texto: valor,
                          icone: icone,
                          selecionado: _instrument == valor,
                          onTap: () => _setInstrument(valor),
                        ),
                    ],
                  ),
                  if (_instrument != 'Todos') ...[
                    const SizedBox(height: 18),
                    MhCard(
                      destaque: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 22,
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _instrument == 'Violão'
                              ? const GuitarFretboardScreen()
                              : const KeyboardScreen(),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 76,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.secondary,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              _instrument == 'Violão'
                                  ? Icons.music_note_rounded
                                  : Icons.piano_rounded,
                              color: AppColors.text,
                              size: 34,
                            ),
                          ),
                          const MhDividerVertical(altura: 56),
                          Expanded(
                            child: Text(
                              'Abrir simulador de $_instrument',
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.primary,
                            size: 30,
                          ),
                        ],
                      ),
                    ),
                  ],
                  Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      iconColor: AppColors.primary,
                      collapsedIconColor: AppColors.muted,
                      title: const Text(
                        'Mais filtros',
                        style: TextStyle(color: AppColors.muted, fontSize: 15),
                      ),
                      children: [
                        TextField(
                          controller: _search,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(color: AppColors.text),
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
                      ],
                    ),
                  ),
                  const MhSectionTitle('Exercícios'),
                  if (visible.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Nenhuma atividade encontrada. Ajuste os filtros.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                  for (final activity in visible)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _cartaoAtividade(activity),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cartaoAtividade(_Activity activity) => MhCard(
    padding: const EdgeInsets.fromLTRB(16, 16, 10, 16),
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => activity.builder()),
    ),
    child: Row(
      children: [
        MhIconTile(icone: activity.icon, tamanho: 62),
        const MhDividerVertical(altura: 54),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.title,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                activity.level == 'Todos'
                    ? activity.kind
                    : '${activity.kind} · ${activity.level}',
                style: const TextStyle(color: AppColors.muted, fontSize: 14),
              ),
            ],
          ),
        ),
        for (final instrumento in activity.instrumentos) ...[
          const SizedBox(width: 8),
          MhBadge(
            texto: instrumento,
            icone: instrumento == 'Violão'
                ? Icons.music_note_outlined
                : Icons.piano_outlined,
          ),
        ],
        const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
      ],
    ),
  );

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
          child: Text(label, style: const TextStyle(color: AppColors.muted)),
        ),
        Expanded(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: AppColors.surface,
            style: const TextStyle(color: AppColors.text),
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
