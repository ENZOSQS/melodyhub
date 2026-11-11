import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/progress_service.dart';
import '../domain/report_rules.dart';
import '../theme/app_theme.dart';
import '../widgets/mh_ui.dart';
import 'exercises_screen.dart';
import 'guitar_fretboard_screen.dart';
import 'guitar_note_exercise_screen.dart';
import 'interval_exercises_screen.dart';
import 'music_concepts_screen.dart';
import 'profile_screen.dart';
import 'rhythm_exercise_screen.dart';
import 'theory_exercises_screen.dart';

class PerformanceScreen extends StatelessWidget {
  const PerformanceScreen({super.key});

  static const Color verde = Color(0xFFE9B96E);
  static const Color preto = Color(0xFF171316);

  @override
  Widget build(BuildContext context) {
    final service = ProgressService();
    final hoje = DateTime.now();
    final inicio = DateTime(
      hoje.year,
      hoje.month,
      hoje.day,
    ).subtract(const Duration(days: 6));
    return Scaffold(
      backgroundColor: preto,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.ouvirHistorico(dias: 7, limite: null),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: verde));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  'Não foi possível carregar o relatório semanal. Tente novamente mais tarde.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            );
          }

          final exercicios =
              snapshot.data?.docs.map((doc) => doc.data()).toList() ?? [];
          final eventosParaRevisao = exercicios.map((evento) {
            final data = evento['data'];
            return <String, dynamic>{
              ...evento,
              if (data is Timestamp) 'data': data.toDate().toLocal(),
            };
          });
          final itensCriticos = agruparErrosCriticos(
            eventosParaRevisao,
            agora: DateTime.now(),
          );
          final acertos = exercicios.where((e) => e['acertou'] == true).length;
          final total = exercicios.length;
          final precisao = total == 0 ? 0 : (acertos * 100 / total).round();
          final xpSemana = exercicios.fold<int>(
            0,
            (soma, item) => soma + _numero(item['xpGanho']),
          );
          final milissegundos = exercicios.fold<int>(
            0,
            (soma, item) =>
                soma +
                (item['duracaoMilissegundos'] is num
                    ? _numero(item['duracaoMilissegundos'])
                    : _numero(item['duracaoSegundos']) * 1000),
          );
          final dias = List.generate(7, (i) => inicio.add(Duration(days: i)));
          final porDia = List<int>.filled(7, 0);
          final acertosPorDia = List<int>.filled(7, 0);
          final categorias = <String, int>{};
          final resultadosCategoria = <String, List<int>>{};
          for (final exercicio in exercicios) {
            final valor = exercicio['data'];
            if (valor is Timestamp) {
              final data = valor.toDate().toLocal();
              final indice = DateTime(
                data.year,
                data.month,
                data.day,
              ).difference(inicio).inDays;
              if (indice >= 0 && indice < porDia.length) {
                porDia[indice]++;
                if (exercicio['acertou'] == true) acertosPorDia[indice]++;
              }
            }
            final tipo =
                (exercicio['categoria'] as String?) ??
                (exercicio['tipo'] as String?) ??
                'Outro';
            categorias.update(tipo, (valor) => valor + 1, ifAbsent: () => 1);
            final resultado = resultadosCategoria.putIfAbsent(
              tipo,
              () => [0, 0],
            );
            resultado[0]++;
            if (exercicio['acertou'] == true) resultado[1]++;
          }

          final sugestoes = _sugestoes(resultadosCategoria);
          return ListView(
            padding: const EdgeInsets.only(bottom: 28),
            children: [
              MelodyHeader(
                onNotificacoes: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
              ),
              MhPageTitle(
                'Relatório da semana',
                subtitulo: 'Últimos 7 dias · ${_data(inicio)} a ${_data(hoje)}',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: MhStatCard(
                            icone: Icons.track_changes_rounded,
                            rotulo: 'Precisão',
                            valor: '$precisao%',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: MhStatCard(
                            icone: Icons.star_outline_rounded,
                            corIcone: AppColors.primary,
                            rotulo: 'XP na semana',
                            valor: '$xpSemana',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: MhStatCard(
                            icone: Icons.schedule_rounded,
                            rotulo: 'Tempo de estudo',
                            valor: _duracao((milissegundos / 1000).round()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$total exercícios · $acertos acertos. O tempo soma só o período respondendo exercícios.',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),
                    MhCard(
                      padding: const EdgeInsets.fromLTRB(12, 18, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 6, bottom: 10),
                            child: Text(
                              'Precisão por dia (%)',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          _GraficoPrecisao(
                            dias: [for (final dia in dias) _diaSemana(dia)],
                            percentuais: [
                              for (var i = 0; i < 7; i++)
                                porDia[i] == 0
                                    ? null
                                    : acertosPorDia[i] * 100 / porDia[i],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const MhSectionTitle('O que mais precisa de revisão'),
                    if (itensCriticos.isEmpty)
                      const MhCard(
                        child: Text(
                          'Ainda não há itens com dois ou mais erros nos últimos sete dias. Continue praticando para identificar o que merece revisão.',
                          style: TextStyle(color: AppColors.muted, height: 1.4),
                        ),
                      ),
                    for (final item in itensCriticos)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MhCard(
                          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                          child: Row(
                            children: [
                              MhIconTile(
                                icone: _iconeTipo(item.tipo),
                                cor: AppColors.secondary,
                                tamanho: 54,
                              ),
                              const MhDividerVertical(altura: 50),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${item.item} –',
                                      style: const TextStyle(
                                        color: AppColors.text,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item.erros} erros em ${item.tentativas} tentativas',
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () =>
                                    _abrirExercicio(context, item.tipo),
                                child: const Text('Praticar'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (categorias.isNotEmpty) ...[
                      const MhSectionTitle('Por tipo de exercício'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final e in categorias.entries)
                            MhBadge(texto: '${e.key}: ${e.value}'),
                        ],
                      ),
                    ],
                    const MhSectionTitle('O que praticar em seguida'),
                    if (sugestoes.isEmpty)
                      const MhCard(
                        child: Text(
                          'Nenhuma habilidade precisa de reforço com os dados atuais. Abaixo de três respostas, ainda é cedo para apontar uma dificuldade.',
                          style: TextStyle(color: AppColors.muted, height: 1.4),
                        ),
                      ),
                    for (final item in sugestoes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: MhCard(
                          padding: const EdgeInsets.all(14),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => item.$3()),
                          ),
                          child: Row(
                            children: [
                              const MhIconTile(
                                icone: Icons.lightbulb_outline_rounded,
                                tamanho: 46,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.$1,
                                      style: const TextStyle(
                                        color: AppColors.text,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.$2,
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (total == 0)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Text(
                          'Seus exercícios aparecerão aqui conforme você praticar.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
        ),
      ),
    );
  }

  List<(String, String, Widget Function())> _sugestoes(
    Map<String, List<int>> categorias,
  ) {
    final suggestions = <(String, String, Widget Function())>[];
    for (final entry in categorias.entries) {
      final total = entry.value[0];
      final rate = total == 0 ? 100 : entry.value[1] * 100 / total;
      if (total < 3 || rate > 70) continue;
      final key = entry.key.toLowerCase();
      if (key.contains('interval')) {
        suggestions.add((
          'Revisar intervalos',
          '$total respostas · ${rate.round()}% de acerto. Volte aos intervalos menores e compare as duas notas.',
          () => const IntervalExercisesScreen(),
        ));
      } else if (key.contains('ritmo')) {
        suggestions.add((
          'Revisar ritmo',
          '$total respostas · ${rate.round()}% de acerto. Reduza o BPM e conte as subdivisões em voz alta.',
          () => const RhythmExerciseScreen(),
        ));
      } else if (key.contains('escala')) {
        suggestions.add((
          'Revisar escalas',
          '$total respostas · ${rate.round()}% de acerto. Compare a terça maior e a menor.',
          () => const MusicConceptsScreen(exercise: ConceptExercise.scale),
        ));
      } else if (key.contains('acorde')) {
        suggestions.add((
          'Revisar acordes',
          '$total respostas · ${rate.round()}% de acerto. Escute a terça e a quinta do acorde.',
          () => const MusicConceptsScreen(exercise: ConceptExercise.chord),
        ));
      } else if (key.contains('memória') || key.contains('prát')) {
        suggestions.add((
          'Revisar memória de notas',
          '$total respostas · ${rate.round()}% de acerto. Use sequências menores e ouça novamente.',
          () => const ExercisesScreen(),
        ));
      } else if (key.contains('teor') ||
          key.contains('nota') ||
          key.contains('partitura') ||
          key.contains('harmonia')) {
        suggestions.add((
          'Revisar teoria',
          '$total respostas · ${rate.round()}% de acerto. Releia a explicação antes da próxima tentativa.',
          () => const TheoryExercisesScreen(),
        ));
      }
    }
    if (suggestions.isEmpty && categorias.isNotEmpty) {
      suggestions.add((
        'Explorar outra habilidade',
        'Seus resultados recentes estão consistentes. Pratique um conteúdo diferente para ampliar sua percepção.',
        () => const GuitarFretboardScreen(),
      ));
    }
    return suggestions.take(3).toList();
  }

  void _abrirExercicio(BuildContext context, String tipo) {
    final destino = switch (tipo) {
      'Violão' => const GuitarNoteExerciseScreen(),
      'Intervalo' => const IntervalExercisesScreen(),
      'Escala' => const MusicConceptsScreen(exercise: ConceptExercise.scale),
      'Acorde' => const MusicConceptsScreen(exercise: ConceptExercise.chord),
      'Teórico' => const TheoryExercisesScreen(),
      'Ritmo' => const RhythmExerciseScreen(),
      _ => const ExercisesScreen(),
    };
    Navigator.push(context, MaterialPageRoute(builder: (_) => destino));
  }

  static IconData _iconeTipo(String tipo) => switch (tipo) {
    'Intervalo' => Icons.graphic_eq_rounded,
    'Violão' => Icons.music_note_outlined,
    'Teórico' => Icons.menu_book_outlined,
    'Ritmo' => Icons.timer_outlined,
    'Escala' => Icons.show_chart_rounded,
    'Acorde' => Icons.piano_outlined,
    _ => Icons.hearing_rounded,
  };

  static int _numero(dynamic valor) => valor is num ? valor.toInt() : 0;

  static String _data(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}';

  static String _diaSemana(DateTime data) =>
      const ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'][data.weekday - 1];

  static String _duracao(int segundos) {
    if (segundos < 60) return '${segundos}s';
    final minutos = segundos ~/ 60;
    if (minutos < 60) return '${minutos}min';
    return '${minutos ~/ 60}h ${minutos % 60}min';
  }
}

/// Gráfico de barras da precisão diária, com linhas de grade de 0 a 100.
class _GraficoPrecisao extends StatelessWidget {
  const _GraficoPrecisao({required this.dias, required this.percentuais});

  final List<String> dias;

  /// `null` quando não houve exercício no dia.
  final List<double?> percentuais;

  static const _altura = 190.0;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: _altura + 26,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 34,
          height: _altura,
          child: Stack(
            children: [
              for (var marca = 0; marca <= 100; marca += 20)
                Positioned(
                  right: 6,
                  top: _altura * (1 - marca / 100) - 8,
                  child: Text(
                    '$marca',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              SizedBox(
                height: _altura,
                child: Stack(
                  children: [
                    for (var marca = 0; marca <= 100; marca += 20)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: _altura * (1 - marca / 100),
                        child: Container(
                          height: 1,
                          color: AppColors.border.withValues(alpha: .7),
                        ),
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final percentual in percentuais)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                  begin: 0,
                                  end: percentual == null
                                      ? 3.0
                                      : (_altura * percentual / 100)
                                            .clamp(3.0, _altura)
                                            .toDouble(),
                                ),
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeOutCubic,
                                builder: (context, altura, _) => Container(
                                  height: altura,
                                  decoration: BoxDecoration(
                                    gradient: percentual == null
                                        ? null
                                        : const LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Color(0xFFF7CD86),
                                              Color(0xFFDDA552),
                                            ],
                                          ),
                                    color: percentual == null
                                        ? AppColors.surfaceHighlight
                                        : null,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final dia in dias)
                    Expanded(
                      child: Text(
                        dia,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
