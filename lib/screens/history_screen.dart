import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/progress_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const Color verde = Color(0xFF16D9C5);
  static const Color preto = Color(0xFF0B1736);
  final ProgressService _service = ProgressService();
  int? _periodo;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _documentos = [];
  QueryDocumentSnapshot<Map<String, dynamic>>? _ultimoDocumento;
  bool _carregando = true;
  bool _temMais = true;
  bool _erro = false;
  int _versaoConsulta = 0;

  @override
  void initState() {
    super.initState();
    _carregarMais();
  }

  Future<void> _carregarMais() async {
    final versao = _versaoConsulta;
    if (mounted) setState(() => _carregando = true);
    try {
      final pagina = await _service.buscarHistorico(
        dias: _periodo,
        depoisDe: _ultimoDocumento,
      );
      if (!mounted || versao != _versaoConsulta) return;
      setState(() {
        _documentos.addAll(pagina.docs);
        if (pagina.docs.isNotEmpty) _ultimoDocumento = pagina.docs.last;
        _temMais = pagina.docs.length == 50;
        _carregando = false;
        _erro = false;
      });
    } catch (_) {
      if (!mounted || versao != _versaoConsulta) return;
      setState(() {
        _carregando = false;
        _erro = true;
      });
    }
  }

  Future<void> _alterarPeriodo(int? value) async {
    setState(() {
      _periodo = value;
      _documentos.clear();
      _ultimoDocumento = null;
      _temMais = true;
      _erro = false;
      _versaoConsulta++;
    });
    await _carregarMais();
  }

  Future<void> _atualizar() async {
    setState(() {
      _documentos.clear();
      _ultimoDocumento = null;
      _temMais = true;
      _erro = false;
      _versaoConsulta++;
    });
    await _carregarMais();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: preto,
      appBar: AppBar(
        backgroundColor: preto,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Histórico',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Período',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                DropdownButton<int?>(
                  value: _periodo,
                  dropdownColor: preto,
                  style: const TextStyle(color: Colors.white),
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Tudo')),
                    DropdownMenuItem(value: 7, child: Text('7 dias')),
                    DropdownMenuItem(value: 30, child: Text('30 dias')),
                    DropdownMenuItem(value: 90, child: Text('90 dias')),
                  ],
                  onChanged: (value) => _alterarPeriodo(value),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: verde,
              onRefresh: _atualizar,
              child: _documentos.isEmpty && _carregando
                  ? const Center(child: CircularProgressIndicator(color: verde))
                  : _documentos.isEmpty && _erro
                  ? _estado(
                      'Não foi possível carregar o histórico.',
                      acao: _carregarMais,
                    )
                  : _documentos.isEmpty
                  ? _estado('Nenhum exercício encontrado neste período.')
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: _documentos.length + 1,
                      itemBuilder: (context, index) {
                        if (index < _documentos.length) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _item(_documentos[index].data()),
                          );
                        }
                        if (_carregando) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(color: verde),
                            ),
                          );
                        }
                        if (_erro) {
                          return Center(
                            child: TextButton(
                              onPressed: _carregarMais,
                              child: const Text(
                                'Falha ao carregar. Tentar novamente',
                              ),
                            ),
                          );
                        }
                        if (_temMais) {
                          return Center(
                            child: TextButton.icon(
                              onPressed: _carregarMais,
                              icon: const Icon(Icons.expand_more),
                              label: const Text(
                                'Carregar exercícios anteriores',
                              ),
                            ),
                          );
                        }
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              'Fim do histórico',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _estado(String mensagem, {VoidCallback? acao}) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.history, color: verde, size: 56),
          const SizedBox(height: 16),
          Text(
            mensagem,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          if (acao != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: acao, child: const Text('Tentar novamente')),
          ],
        ],
      ),
    ),
  );

  Widget _item(Map<String, dynamic> dados) {
    final acertou = dados['acertou'] == true;
    final data = dados['data'];
    final pergunta = dados['pergunta'] as String?;
    final resposta = dados['resposta'] as String?;
    final correta = dados['respostaCorreta'] as String?;
    final duracao = _numero(dados['duracaoSegundos']);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            acertou ? Icons.check_circle : Icons.cancel,
            color: acertou ? Colors.green : Colors.red,
            size: 25,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exercício ${dados['tipo'] ?? 'Prático'}',
                  style: const TextStyle(
                    color: preto,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  acertou ? 'Resposta correta' : 'Resposta incorreta',
                  style: TextStyle(color: acertou ? Colors.green : Colors.red),
                ),
                if (pergunta != null && pergunta.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(pergunta, style: const TextStyle(color: preto)),
                ],
                if (resposta != null)
                  Text(
                    'Sua resposta: $resposta',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                if (!acertou && correta != null)
                  Text(
                    'Resposta correta: $correta',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                const SizedBox(height: 5),
                Text(
                  '${_formatarData(data)}  •  ${_formatarDuracao(duracao)}',
                  style: const TextStyle(color: Colors.black45, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+${_numero(dados['xpGanho'])} XP',
            style: const TextStyle(color: preto, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatarData(dynamic valor) {
    if (valor is! Timestamp) return 'Data não disponível';
    final data = valor.toDate().toLocal();
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year} às $hora:$minuto';
  }

  String _formatarDuracao(int segundos) {
    if (segundos < 60) return '$segundos s';
    return '${segundos ~/ 60} min ${segundos % 60} s';
  }

  int _numero(dynamic valor) => valor is num ? valor.toInt() : 0;
}
