import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/progress_service.dart';

class PerformanceScreen extends StatelessWidget {
  const PerformanceScreen({super.key});

  static const Color verde = Color(0xFF16D9C5);
  static const Color preto = Color(0xFF0B1736);

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
      appBar: AppBar(
        backgroundColor: preto,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Desempenho',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
          final acertos = exercicios.where((e) => e['acertou'] == true).length;
          final total = exercicios.length;
          final precisao = total == 0 ? 0 : (acertos * 100 / total).round();
          final xpSemana = exercicios.fold<int>(
            0,
            (soma, item) => soma + _numero(item['xpGanho']),
          );
          final segundos = exercicios.fold<int>(
            0,
            (soma, item) => soma + _numero(item['duracaoSegundos']),
          );
          final dias = List.generate(7, (i) => inicio.add(Duration(days: i)));
          final porDia = List<int>.filled(7, 0);
          final acertosPorDia = List<int>.filled(7, 0);
          final categorias = <String, int>{};
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
            final tipo = (exercicio['tipo'] as String?) ?? 'Outro';
            categorias.update(tipo, (valor) => valor + 1, ifAbsent: () => 1);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                'Últimos 7 dias · ${_data(inicio)} a ${_data(hoje)}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _metric('Exercícios', '$total', Icons.quiz_outlined),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _metric(
                      'Precisão',
                      '$precisao%',
                      Icons.track_changes,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: _metric(
                      'XP na semana',
                      '$xpSemana',
                      Icons.star_outline,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _metric(
                      'Acertos',
                      '$acertos',
                      Icons.check_circle_outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _painel(
                titulo: 'Precisão por dia',
                child: SizedBox(
                  height: 164,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (i) {
                      final percentual = porDia[i] == 0
                          ? 0
                          : (acertosPorDia[i] * 100 / porDia[i]).round();
                      final altura = porDia[i] == 0
                          ? 5.0
                          : 80.0 * percentual / 100;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                porDia[i] == 0 ? '—' : '$percentual%',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                height: altura,
                                decoration: BoxDecoration(
                                  color: porDia[i] == 0
                                      ? Colors.white12
                                      : verde,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                _diaSemana(dias[i]),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _painel(
                titulo: 'Tempo de prática registrado',
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: verde, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _duracao(segundos),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.info_outline,
                      color: Colors.white54,
                      size: 18,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Tempo somado enquanto você responde exercícios; pausas e simulador livre não entram nessa conta.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
              if (categorias.isNotEmpty) ...[
                const SizedBox(height: 12),
                _painel(
                  titulo: 'Por tipo de exercício',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categorias.entries
                        .map(
                          (e) => Chip(
                            backgroundColor: const Color(0xFF142548),
                            label: Text(
                              '${e.key}: ${e.value}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            side: BorderSide.none,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
              if (total == 0)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text(
                    'Seus exercícios aparecerão aqui conforme você praticar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _metric(String titulo, String valor, IconData icone) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
    decoration: BoxDecoration(
      color: const Color(0xFF142548),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, color: verde, size: 20),
        const SizedBox(height: 8),
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
        Text(
          titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    ),
  );

  Widget _painel({required String titulo, required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF142548),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );

  static int _numero(dynamic valor) => valor is num ? valor.toInt() : 0;

  static String _data(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}';

  static String _diaSemana(DateTime data) =>
      const ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'][data.weekday - 1];

  static String _duracao(int segundos) {
    if (segundos < 60) return '$segundos s';
    final minutos = segundos ~/ 60;
    final resto = segundos % 60;
    if (minutos < 60)
      return resto == 0 ? '$minutos min' : '$minutos min $resto s';
    return '${minutos ~/ 60} h ${minutos % 60} min';
  }
}
