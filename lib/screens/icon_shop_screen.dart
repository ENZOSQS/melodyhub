import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/profile_icon_rewards.dart';
import '../services/progress_service.dart';

class IconShopScreen extends StatefulWidget {
  const IconShopScreen({super.key});

  @override
  State<IconShopScreen> createState() => _IconShopScreenState();
}

class _IconShopScreenState extends State<IconShopScreen> {
  static const _background = Color(0xFF0B1736);
  static const _accent = Color(0xFF16D9C5);
  final _progress = ProgressService();
  String? _buying;

  Future<void> _buy(String id) async {
    setState(() => _buying = id);
    try {
      await _progress.comprarIconePerfil(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ícone comprado! Você já pode equipá-lo no perfil.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        final message = error.toString().contains('insuficientes')
            ? 'Você ainda não tem pontos suficientes.'
            : 'Não foi possível concluir a compra.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _buying = null);
    }
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
        title: const Text('Loja de ícones'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Não foi possível carregar a loja.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _accent),
            );
          }
          final data = snapshot.data?.data() ?? <String, dynamic>{};
          final points = data['pontos'] is num
              ? (data['pontos'] as num).toInt()
              : 0;
          final owned = List<String>.from(
            data['iconesComprados'] ?? <String>[],
          );
          final achievements = List<String>.from(
            data['conquistas'] ?? <String>[],
          );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      color: _background,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Seus pontos',
                        style: TextStyle(
                          color: _background,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '$points',
                      style: const TextStyle(
                        color: _background,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Ganhe pontos respondendo exercícios. Acertos em níveis mais altos rendem mais.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 18),
              ...profileIconRewards.map((reward) {
                final purchased = owned.contains(reward.id);
                final earned = achievements.contains(reward.achievementId);
                final isOwned = purchased || earned;
                final busy = _buying == reward.id;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    title: Text(
                      reward.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      purchased
                          ? 'Comprado'
                          : earned
                          ? 'Desbloqueado por conquista'
                          : '${reward.price} pontos',
                    ),
                    trailing: isOwned
                        ? Text(
                            purchased ? 'Comprado' : 'Desbloqueado',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : FilledButton(
                            onPressed: busy ? null : () => _buy(reward.id),
                            child: busy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Comprar'),
                          ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
