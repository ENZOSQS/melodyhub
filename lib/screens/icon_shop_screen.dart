import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/profile_icon_rewards.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';

class IconShopScreen extends StatefulWidget {
  const IconShopScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<IconShopScreen> createState() => _IconShopScreenState();
}

class _IconShopScreenState extends State<IconShopScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _progress = ProgressService();
  String? _buying;
  String? _equipping;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 2,
      initialIndex: widget.initialTab.clamp(0, 1),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _buy(ProfileIconReward reward) async {
    setState(() => _buying = reward.id);
    try {
      await _progress.comprarIconePerfil(reward.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ícone adicionado à sua coleção.')),
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

  Future<void> _equip(ProfileIconReward reward) async {
    setState(() => _equipping = reward.id);
    try {
      await _progress.atualizarIconePerfil(reward.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${reward.name} equipado no perfil.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível equipar este ícone.')),
        );
      }
    } finally {
      if (mounted) setState(() => _equipping = null);
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ícones musicais'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.storefront_outlined), text: 'Loja'),
            Tab(icon: Icon(Icons.collections_outlined), text: 'Coleção'),
          ],
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Não foi possível carregar seus ícones.'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() ?? <String, dynamic>{};
          final points = _number(data['pontos']);
          final owned = List<String>.from(
            data['iconesComprados'] ?? <String>[],
          );
          final achievements = List<String>.from(
            data['conquistas'] ?? <String>[],
          );
          final equippedId = data['iconePerfilId'] as String?;
          final collection = profileIconRewards
              .where(
                (item) =>
                    owned.contains(item.id) ||
                    (item.achievementId != null &&
                        achievements.contains(item.achievementId)),
              )
              .toList();
          final available = profileIconRewards
              .where(
                (item) =>
                    !owned.contains(item.id) &&
                    (item.achievementId == null ||
                        !achievements.contains(item.achievementId)),
              )
              .toList();

          return Column(
            children: [
              _collectionSummary(points: points, count: collection.length),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    available.isEmpty
                        ? _emptyState(
                            icon: Icons.celebration_outlined,
                            title: 'Você já tem todos os ícones',
                            message: 'Sua coleção está completa.',
                          )
                        : _itemGrid(
                            available,
                            mode: _GridMode.shop,
                            equippedId: equippedId,
                          ),
                    collection.isEmpty
                        ? _emptyState(
                            icon: Icons.collections_bookmark_outlined,
                            title: 'Sua coleção começa aqui',
                            message:
                                'Adquira ícones na loja para personalizar seu perfil.',
                            action: FilledButton.icon(
                              onPressed: () => _tabs.animateTo(0),
                              icon: const Icon(Icons.storefront_outlined),
                              label: const Text('Explorar loja'),
                            ),
                          )
                        : _itemGrid(
                            collection,
                            mode: _GridMode.collection,
                            equippedId: equippedId,
                          ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _collectionSummary({required int points, required int count}) {
    final progress = count / profileIconRewards.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.surfaceRaised, AppColors.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.stars_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Sua coleção musical',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$points',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'pontos',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ícones colecionados',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                Text(
                  '$count/${profileIconRewards.length}',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: AppColors.surfaceHighlight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemGrid(
    List<ProfileIconReward> items, {
    required _GridMode mode,
    required String? equippedId,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 4
            : constraints.maxWidth >= 640
            ? 3
            : 2;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: mode == _GridMode.shop ? 365 : 410,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return mode == _GridMode.shop
                ? _shopCard(item, busy: _buying == item.id)
                : _collectionCard(
                    item,
                    isEquipped: equippedId == item.id,
                    busy: _equipping == item.id,
                  );
          },
        );
      },
    );
  }

  Widget _shopCard(ProfileIconReward item, {required bool busy}) {
    return _itemCardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _artwork(item, onTap: () => _showPreview(item))),
          const SizedBox(height: 10),
          _itemTitle(item),
          const SizedBox(height: 6),
          _tags(item),
          const SizedBox(height: 6),
          Text(
            item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${item.price} pts',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              FilledButton(
                onPressed: busy ? null : () => _buy(item),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(88, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Adquirir'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _collectionCard(
    ProfileIconReward item, {
    required bool isEquipped,
    required bool busy,
  }) {
    return _itemCardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: _artwork(item, onTap: () => _showPreview(item)),
                ),
                if (isEquipped)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _statusBadge('No perfil', AppColors.primary),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _itemTitle(item),
          const SizedBox(height: 6),
          _tags(item),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showPreview(item),
              icon: const Icon(Icons.zoom_in_rounded, size: 18),
              label: const Text('Visualizar'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
          const SizedBox(height: 7),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isEquipped || busy ? null : () => _equip(item),
              icon: Icon(
                isEquipped ? Icons.check_rounded : Icons.person_pin_circle,
                size: 18,
              ),
              label: Text(isEquipped ? 'Em uso' : 'Usar no perfil'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemCardFrame({required Widget child}) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }

  Widget _artwork(ProfileIconReward item, {required VoidCallback onTap}) {
    return Material(
      color: AppColors.surfaceRaised,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.surfaceRaised, AppColors.surfaceHighlight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Center(
            child: Image.asset(
              item.assetPath!,
              width: 142,
              height: 142,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  Icon(item.fallbackIcon, size: 72, color: AppColors.primary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _itemTitle(ProfileIconReward item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 14,
            height: 1.15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          item.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
      ],
    );
  }

  Widget _tags(ProfileIconReward item) {
    return Row(
      children: [
        _rarityBadge(item.rarity),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            item.category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ),
      ],
    );
  }

  Widget _rarityBadge(String rarity) {
    final color = switch (rarity) {
      'Lendário' => AppColors.secondary,
      'Épico' => const Color(0xFF8AA3FF),
      'Raro' => const Color(0xFF69C6F0),
      'Incomum' => const Color(0xFF70D6A5),
      _ => AppColors.muted,
    };
    return _statusBadge(rarity, color);
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, color: AppColors.primary, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            if (action != null) ...[const SizedBox(height: 18), action],
          ],
        ),
      ),
    );
  }

  Future<void> _showPreview(ProfileIconReward item) {
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.surfaceRaised,
                      AppColors.surfaceHighlight,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Image.asset(item.assetPath!, fit: BoxFit.contain),
              ),
              const SizedBox(height: 14),
              Text(
                item.description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              _tags(item),
            ],
          ),
        ),
      ),
    );
  }

  int _number(dynamic value) => value is num ? value.toInt() : 0;
}

enum _GridMode { shop, collection }
