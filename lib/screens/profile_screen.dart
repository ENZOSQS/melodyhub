// lib/screens/profile_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/profile_icon_rewards.dart';
import '../services/progress_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color verde = Color(0xFF16D9C5);

  static const Color preto = Color(0xFF0B1736);

  final ProgressService _service = ProgressService();

  final TextEditingController _nomeController = TextEditingController();

  bool _editando = false;
  bool _salvando = false;
  bool _salvandoIcone = false;

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _salvarNome() async {
    final nome = _nomeController.text.trim();

    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um nome antes de salvar.')),
      );
      return;
    }

    setState(() {
      _salvando = true;
    });

    try {
      await _service.atualizarNome(nome);
    } catch (_) {
      if (mounted) {
        setState(() => _salvando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível salvar o nome. Tente novamente.'),
          ),
        );
      }
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _editando = false;
      _salvando = false;
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) {
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _selecionarIcone(String? id) async {
    if (_salvandoIcone) return;
    setState(() => _salvandoIcone = true);
    try {
      await _service.atualizarIconePerfil(id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Esse ícone ainda não foi desbloqueado.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _salvandoIcone = false);
    }
  }

  Widget _iconePerfil(String? id, {double size = 43}) {
    final encontrados = profileIconRewards.where((item) => item.id == id);
    final recompensa = encontrados.isEmpty ? null : encontrados.first;
    if (recompensa?.assetPath != null) {
      return Image.asset(
        recompensa!.assetPath!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            Icon(recompensa.fallbackIcon, color: verde, size: size),
      );
    }
    return Icon(
      recompensa?.fallbackIcon ?? Icons.person,
      color: verde,
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      return const Scaffold(
        backgroundColor: preto,
        body: Center(
          child: Text(
            'Usuário não autenticado.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: preto,
      appBar: AppBar(
        backgroundColor: preto,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Meu Perfil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(usuario.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Não foi possível carregar seu perfil.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: verde));
          }
          final dados = snapshot.data?.data() ?? {};

          final nome = dados['nome'] ?? usuario.displayName ?? 'Aluno';

          final xp = _numero(dados['xp']);

          final nivel = _numero(dados['nivel']);

          final exercicios = _numero(dados['exerciciosRespondidos']);

          final acertos = _numero(dados['acertos']);

          final erros = _numero(dados['erros']);

          final sequencia = _numero(dados['melhorSequencia']);

          final melhorSequenciaDias = _numero(dados['melhorSequenciaDias']);
          final precisao = exercicios == 0
              ? 0
              : (acertos * 100 / exercicios).round();

          final conquistas = List<String>.from(dados['conquistas'] ?? []);
          final iconesComprados = List<String>.from(
            dados['iconesComprados'] ?? <String>[],
          );
          final iconePerfilId = dados['iconePerfilId'] as String?;

          if (!_editando && _nomeController.text != nome.toString()) {
            _nomeController.text = nome.toString();
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: preto,
                          child: _iconePerfil(iconePerfilId),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          nome.toString(),
                          style: const TextStyle(
                            color: preto,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          usuario.email ?? '',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Nível $nivel',
                          style: const TextStyle(
                            color: verdeEscuro,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildNome(),
                  const SizedBox(height: 14),
                  _buildIconesPerfil(
                    conquistas,
                    iconesComprados,
                    iconePerfilId,
                  ),
                  const SizedBox(height: 14),
                  _buildDesempenho(
                    xp,
                    nivel,
                    exercicios,
                    acertos,
                    erros,
                    sequencia,
                    melhorSequenciaDias,
                    precisao,
                    conquistas.length,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Sair da conta'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNome() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nome',
            style: TextStyle(
              color: preto,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nomeController,
            enabled: _editando && !_salvando,
            style: const TextStyle(color: preto),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF4F6FA),
              prefixIcon: const Icon(Icons.person_outline, color: preto),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton.icon(
              onPressed: _salvando
                  ? null
                  : () {
                      if (_editando) {
                        _salvarNome();
                      } else {
                        setState(() {
                          _editando = true;
                        });
                      }
                    },
              icon: Icon(_editando ? Icons.save : Icons.edit),
              label: Text(_editando ? 'Salvar nome' : 'Editar nome'),
              style: ElevatedButton.styleFrom(
                backgroundColor: preto,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconesPerfil(
    List<String> conquistas,
    List<String> iconesComprados,
    String? selecionado,
  ) {
    final desbloqueados = profileIconRewards
        .where(
          (item) =>
              conquistas.contains(item.achievementId) ||
              iconesComprados.contains(item.id),
        )
        .toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ícone de perfil',
            style: TextStyle(
              color: preto,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Desbloqueie ícones especiais ao conquistar marcos musicais.',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _opcaoIcone(
                id: null,
                nome: 'Padrão',
                icone: Icons.person_outline,
                selecionado: selecionado == null,
              ),
              ...desbloqueados.map(
                (item) => _opcaoIcone(
                  id: item.id,
                  nome: item.name,
                  icone: item.fallbackIcon,
                  assetPath: item.assetPath,
                  selecionado: selecionado == item.id,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _opcaoIcone({
    required String? id,
    required String nome,
    required IconData icone,
    required bool selecionado,
    String? assetPath,
  }) {
    return ChoiceChip(
      selected: selecionado,
      onSelected: _salvandoIcone ? null : (_) => _selecionarIcone(id),
      avatar: CircleAvatar(
        backgroundColor: preto,
        child: assetPath == null
            ? Icon(icone, color: verde, size: 18)
            : Image.asset(
                assetPath,
                width: 22,
                height: 22,
                errorBuilder: (_, __, ___) =>
                    Icon(icone, color: verde, size: 18),
              ),
      ),
      label: Text(nome),
      selectedColor: verde.withValues(alpha: 0.25),
      labelStyle: const TextStyle(color: preto, fontSize: 12),
      side: BorderSide(color: selecionado ? verde : Colors.black12),
    );
  }

  Widget _buildDesempenho(
    int xp,
    int nivel,
    int exercicios,
    int acertos,
    int erros,
    int sequencia,
    int melhorSequenciaDias,
    int precisao,
    int conquistas,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Desempenho',
            style: TextStyle(
              color: preto,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _card(Icons.star, 'XP', '$xp')),
              const SizedBox(width: 8),
              Expanded(child: _card(Icons.trending_up, 'Nível', '$nivel')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _card(Icons.quiz, 'Exercícios', '$exercicios')),
              const SizedBox(width: 8),
              Expanded(child: _card(Icons.check_circle, 'Acertos', '$acertos')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _card(Icons.cancel, 'Erros', '$erros')),
              const SizedBox(width: 8),
              Expanded(
                child: _card(
                  Icons.local_fire_department,
                  'Recorde de dias',
                  '$melhorSequenciaDias',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _card(Icons.track_changes, 'Precisão geral', '$precisao%'),
          const SizedBox(height: 8),
          _card(Icons.bolt, 'Acertos consecutivos', '$sequencia'),
          const SizedBox(height: 8),
          _card(Icons.emoji_events, 'Conquistas', '$conquistas'),
        ],
      ),
    );
  }

  Widget _card(IconData icone, String titulo, String valor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(icone, color: preto, size: 21),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(color: Colors.black54, fontSize: 11),
                ),
                Text(
                  valor,
                  style: const TextStyle(
                    color: preto,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _numero(dynamic valor) {
    if (valor is int) {
      return valor;
    }

    if (valor is num) {
      return valor.toInt();
    }

    return 0;
  }
}

const Color verdeEscuro = Color(0xFF0B756A);
