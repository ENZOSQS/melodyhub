// lib/screens/profile_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/profile_icon_rewards.dart';
import '../services/progress_service.dart';
import '../services/app_preferences.dart';
import '../services/reminder_service.dart';
import '../theme/app_theme.dart';
import '../widgets/mh_ui.dart';
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
            child: ListView(
              padding: const EdgeInsets.only(bottom: 28),
              children: [
                const MelodyHeader(),
                const MhPageTitle('Perfil'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surfaceRaised,
                              border: Border.all(
                                color: AppColors.secondary,
                                width: 2.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            clipBehavior: Clip.antiAlias,
                            child: fotoUrl == null
                                ? _iconePerfil(
                                    iconePerfilId,
                                    size: 58,
                                    nomeFallback: nome.toString(),
                                  )
                                : Image.network(
                                    fotoUrl,
                                    width: 112,
                                    height: 112,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _iconePerfil(
                                      iconePerfilId,
                                      size: 58,
                                      nomeFallback: nome.toString(),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nome.toString(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.text,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  usuario.email ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Nível $nivel',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const IconShopScreen(initialTab: 1),
                          ),
                        ),
                        icon: const Icon(Icons.collections_outlined),
                        label: const Text('Abrir minha coleção'),
                      ),
                      const SizedBox(height: 16),
                      _buildNomenclatura(),
                      const SizedBox(height: 16),
                      _buildLembrete(),
                      const SizedBox(height: 16),
                      _buildPreferencias(),
                      const SizedBox(height: 16),
                      _buildSobreSons(),
                      const SizedBox(height: 16),
                      _buildNome(),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 22),
                      SizedBox(
                        height: 60,
                        child: OutlinedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text(
                            'Sair',
                            style: TextStyle(fontSize: 18),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.secondary,
                            side: const BorderSide(
                              color: AppColors.secondary,
                              width: 1.6,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _titulo(String texto) => Text(
    texto,
    style: const TextStyle(
      color: AppColors.text,
      fontSize: 21,
      fontWeight: FontWeight.w800,
    ),
  );

  Widget _buildSobreSons() => Card(
    color: AppColors.surface,
    child: const ListTile(
      leading: Icon(Icons.music_note, color: verde),
      title: Text('Sobre os sons'),
      subtitle: Text(
        'Simuladores: samples Tone.js Instruments (CC BY 3.0). '
        'Exercícios auditivos: som sintetizado no próprio app.',
      ),
    ),
  );

  Widget _buildNomenclatura() => MhCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo('Nomenclatura das notas'),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _opcaoRadio('Dó-Ré-Mi', 'solfejo')),
            const SizedBox(width: 12),
            Expanded(child: _opcaoRadio('C-D-E', 'cifragem')),
          ],
        ),
      ],
    ),
  );

  Widget _opcaoRadio(String rotulo, String valor) {
    final selecionado = _tipoNota == valor;
    return Semantics(
      selected: selecionado,
      button: true,
      child: Material(
        color: selecionado
            ? AppColors.primary.withValues(alpha: .14)
            : AppColors.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selecionado ? AppColors.primary : AppColors.border,
            width: selecionado ? 1.6 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _salvarNomenclatura(valor),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Row(
              children: [
                Icon(
                  selecionado
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selecionado ? AppColors.primary : AppColors.muted,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    rotulo,
                    style: const TextStyle(color: AppColors.text, fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLembrete() {
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
    return MhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _titulo('Lembrete de estudo')),
              Switch(value: _lembreteAtivo, onChanged: _definirLembrete),
            ],
          ),
          const SizedBox(height: 12),
          MhCard(
            corFundo: AppColors.background.withValues(alpha: .35),
            padding: const EdgeInsets.all(16),
            onTap: _escolherHora,
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  color: AppColors.secondary,
                  size: 34,
                ),
                const SizedBox(width: 18),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Horário',
                      style: TextStyle(color: AppColors.text, fontSize: 15),
                    ),
                    Text(
                      _horaLembrete.format(context),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          MhCard(
            corFundo: AppColors.background.withValues(alpha: .35),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.secondary,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dias da semana',
                        style: TextStyle(color: AppColors.text, fontSize: 15),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: List.generate(7, (index) {
                          final dia = index + 1;
                          final ativo = _diasLembrete.contains(dia);
                          return Tooltip(
                            message: nomes[index],
                            child: Material(
                              color: ativo
                                  ? AppColors.primary
                                  : AppColors.surfaceRaised,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: ativo
                                      ? AppColors.primary
                                      : AppColors.border,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _alternarDiaLembrete(dia),
                                child: SizedBox(
                                  width: 36,
                                  height: 40,
                                  child: Center(
                                    child: Text(
                                      rotulos[index],
                                      style: TextStyle(
                                        color: ativo
                                            ? AppColors.background
                                            : AppColors.text,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'O lembrete fica salvo neste aparelho. A disponibilidade depende das permissões do sistema.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencias() => MhCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo('Preferências de estudo'),
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
