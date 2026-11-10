// lib/screens/profile_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/profile_icon_rewards.dart';
import '../services/progress_service.dart';
import '../services/app_preferences.dart';
import '../services/reminder_service.dart';
import '../theme/app_theme.dart';
import 'icon_shop_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color verde = Color(0xFFE9B96E);

  final ProgressService _service = ProgressService();

  final TextEditingController _nomeController = TextEditingController();

  bool _editando = false;
  bool _salvando = false;
  bool _rotulosTeclado = true;
  bool _lembreteAtivo = false;
  int _bpm = 80;
  String _tipoNota = 'solfejo';
  TimeOfDay _horaLembrete = const TimeOfDay(hour: 19, minute: 0);
  List<int> _diasLembrete = List<int>.generate(7, (index) => index + 1);

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _carregarPreferencias();
  }

  Future<void> _carregarPreferencias() async {
    final result = await Future.wait([
      AppPreferences.noteType(),
      AppPreferences.showKeyboardLabels(),
      AppPreferences.defaultBpm(),
      AppPreferences.reminderEnabled(),
      AppPreferences.reminderTime(),
      AppPreferences.reminderDays(),
    ]);
    if (!mounted) return;
    final time = result[4] as ({int hour, int minute});
    setState(() {
      _tipoNota = result[0] as String;
      _rotulosTeclado = result[1] as bool;
      _bpm = result[2] as int;
      _lembreteAtivo = result[3] as bool;
      _horaLembrete = TimeOfDay(hour: time.hour, minute: time.minute);
      _diasLembrete = result[5] as List<int>;
    });
  }

  Future<void> _salvarNomenclatura(String valor) async {
    setState(() => _tipoNota = valor);
    await AppPreferences.setNoteType(valor);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'preferencias': {'nomenclatura': valor},
      }, SetOptions(merge: true));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'A preferência foi salva neste aparelho, mas não foi sincronizada com a conta.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _definirLembrete(bool ativo) async {
    if (!ativo) {
      await ReminderService.instance.cancelDaily();
      await AppPreferences.setReminderEnabled(false);
      if (mounted) setState(() => _lembreteAtivo = false);
      return;
    }
    final permission = await ReminderService.instance.requestPermission();
    if (!permission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permita notificações nas configurações do aparelho para ativar o lembrete.',
            ),
          ),
        );
      }
      return;
    }
    final ok = await ReminderService.instance.scheduleWeekly(
      hour: _horaLembrete.hour,
      minute: _horaLembrete.minute,
      dias: _diasLembrete,
    );
    if (ok) {
      await AppPreferences.setReminderEnabled(true);
      if (mounted) setState(() => _lembreteAtivo = true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'O sistema não conseguiu agendar o lembrete neste dispositivo.',
          ),
        ),
      );
    }
  }

  Future<void> _escolherHora() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _horaLembrete,
    );
    if (time == null) return;
    setState(() => _horaLembrete = time);
    await AppPreferences.setReminderTime(time.hour, time.minute);
    if (_lembreteAtivo) {
      final ok = await ReminderService.instance.scheduleWeekly(
        hour: time.hour,
        minute: time.minute,
        dias: _diasLembrete,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível atualizar o horário do lembrete.'),
          ),
        );
      }
    }
  }

  Future<void> _alternarDiaLembrete(int dia) async {
    final dias = List<int>.from(_diasLembrete);
    if (dias.contains(dia)) {
      if (dias.length == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mantenha pelo menos um dia selecionado.'),
          ),
        );
        return;
      }
      dias.remove(dia);
    } else {
      dias.add(dia);
      dias.sort();
    }
    setState(() => _diasLembrete = dias);
    await AppPreferences.setReminderDays(dias);
    if (_lembreteAtivo) {
      final ok = await ReminderService.instance.scheduleWeekly(
        hour: _horaLembrete.hour,
        minute: _horaLembrete.minute,
        dias: dias,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível atualizar os dias do lembrete.'),
          ),
        );
      }
    }
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

  Widget _iconePerfil(
    String? id, {
    double size = 43,
    String nomeFallback = 'Aluno',
  }) {
    final encontrados = allProfileIconRewards.where((item) => item.id == id);
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
    if (recompensa == null) {
      return Text(
        nomeFallback.trim().isEmpty
            ? 'A'
            : nomeFallback.trim().characters.first.toUpperCase(),
        style: TextStyle(
          color: verde,
          fontSize: size * .75,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    return Icon(recompensa.fallbackIcon, color: verde, size: size);
  }

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Usuário não autenticado.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
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
          final iconePerfilId = dados['iconePerfilId'] as String?;
          final fotoUrl = dados['fotoUrl'] as String? ?? usuario.photoURL;

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
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.surfaceRaised,
                          child: fotoUrl == null
                              ? _iconePerfil(
                                  iconePerfilId,
                                  nomeFallback: nome.toString(),
                                )
                              : ClipOval(
                                  child: Image.network(
                                    fotoUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _iconePerfil(
                                      iconePerfilId,
                                      nomeFallback: nome.toString(),
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          nome.toString(),
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          usuario.email ?? '',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Nível $nivel',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const IconShopScreen(initialTab: 1),
                        ),
                      ),
                      icon: const Icon(Icons.collections_outlined),
                      label: const Text('Abrir minha coleção'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildNome(),
                  const SizedBox(height: 14),
                  _buildPreferencias(),
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
                        foregroundColor: AppColors.text,
                        side: const BorderSide(color: AppColors.border),
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

  Widget _buildPreferencias() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preferências de estudo',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        const Text('Nomes das notas', style: TextStyle(color: AppColors.muted)),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'solfejo', label: Text('Dó–Ré–Mi')),
            ButtonSegment(value: 'cifragem', label: Text('C–D–E')),
          ],
          selected: {_tipoNota},
          onSelectionChanged: (values) => _salvarNomenclatura(values.first),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Mostrar nomes no teclado',
            style: TextStyle(color: AppColors.text),
          ),
          value: _rotulosTeclado,
          onChanged: (value) {
            setState(() => _rotulosTeclado = value);
            AppPreferences.setShowKeyboardLabels(value);
          },
        ),
        Text(
          'BPM inicial dos exercícios de ritmo: $_bpm',
          style: const TextStyle(color: AppColors.text),
        ),
        Slider(
          value: _bpm.toDouble(),
          min: 40,
          max: 180,
          divisions: 28,
          label: '$_bpm BPM',
          onChanged: (value) {
            final bpm = value.round();
            setState(() => _bpm = bpm);
            AppPreferences.setDefaultBpm(bpm);
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Lembrete de estudo',
            style: TextStyle(color: AppColors.text),
          ),
          subtitle: Text(
            'Aviso local às ${_horaLembrete.format(context)} nos dias selecionados',
            style: const TextStyle(color: AppColors.muted),
          ),
          value: _lembreteAtivo,
          onChanged: _definirLembrete,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _escolherHora,
            icon: const Icon(Icons.schedule),
            label: Text('Alterar horário · ${_horaLembrete.format(context)}'),
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          children: List.generate(7, (index) {
            final dia = index + 1;
            const rotulos = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
            const nomes = [
              'segunda-feira',
              'terça-feira',
              'quarta-feira',
              'quinta-feira',
              'sexta-feira',
              'sábado',
              'domingo',
            ];
            return Tooltip(
              message: nomes[index],
              child: FilterChip(
                label: Text(rotulos[index]),
                selected: _diasLembrete.contains(dia),
                onSelected: (_) => _alternarDiaLembrete(dia),
                selectedColor: AppColors.primary.withValues(alpha: .25),
                checkmarkColor: AppColors.primary,
                labelStyle: const TextStyle(color: AppColors.text),
              ),
            );
          }),
        ),
        const Text(
          'O lembrete fica salvo neste aparelho. A disponibilidade depende das permissões do sistema.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    ),
  );

  Widget _buildNome() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nome',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nomeController,
            enabled: _editando && !_salvando,
            style: const TextStyle(color: AppColors.text),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceRaised,
              prefixIcon: const Icon(
                Icons.person_outline,
                color: AppColors.primary,
              ),
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
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Desempenho',
            style: TextStyle(
              color: AppColors.text,
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
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(icone, color: AppColors.primary, size: 21),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                Text(
                  valor,
                  style: const TextStyle(
                    color: AppColors.text,
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
