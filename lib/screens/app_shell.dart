import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'exercise_catalog_screen.dart';
import 'home_page.dart';
import 'instrument_catalog_screen.dart';
import 'performance_screen.dart';

/// Primary, persistent navigation: bottom bar on compact windows and a rail on
/// wide layouts. Destinations share the same ordering and animated transition.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selected = 0;

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Início',
    ),
    NavigationDestination(
      icon: Icon(Icons.explore_outlined),
      selectedIcon: Icon(Icons.explore_rounded),
      label: 'Aprender',
    ),
    NavigationDestination(
      icon: Icon(Icons.piano_outlined),
      selectedIcon: Icon(Icons.piano),
      label: 'Tocar',
    ),
    NavigationDestination(
      icon: Icon(Icons.insights_outlined),
      selectedIcon: Icon(Icons.insights),
      label: 'Progresso',
    ),
  ];

  Widget _page() => switch (_selected) {
    0 => const HomePage(),
    1 => const ExerciseCatalogScreen(),
    2 => const InstrumentCatalogScreen(),
    _ => const PerformanceScreen(),
  };

  Widget _animatedPage() => AnimatedSwitcher(
    duration: const Duration(milliseconds: 230),
    reverseDuration: const Duration(milliseconds: 170),
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeInCubic,
    transitionBuilder: (child, animation) => FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(.025, .008),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    ),
    child: KeyedSubtree(key: ValueKey(_selected), child: _page()),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 600;
      if (wide) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: _selected,
                onDestinationSelected: (index) =>
                    setState(() => _selected = index),
                labelType: NavigationRailLabelType.all,
                backgroundColor: AppColors.surface,
                indicatorColor: AppColors.primary.withValues(alpha: .18),
                selectedIconTheme: const IconThemeData(
                  color: AppColors.primary,
                ),
                unselectedIconTheme: const IconThemeData(
                  color: AppColors.muted,
                ),
                selectedLabelTextStyle: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelTextStyle: const TextStyle(
                  color: AppColors.muted,
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: Text('Início'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.explore_outlined),
                    selectedIcon: Icon(Icons.explore_rounded),
                    label: Text('Aprender'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.piano_outlined),
                    selectedIcon: Icon(Icons.piano),
                    label: Text('Tocar'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.insights_outlined),
                    selectedIcon: Icon(Icons.insights),
                    label: Text('Progresso'),
                  ),
                ],
              ),
              const VerticalDivider(width: 1, color: AppColors.border),
              Expanded(child: _animatedPage()),
            ],
          ),
        );
      }

      return Scaffold(
        backgroundColor: AppColors.background,
        body: _animatedPage(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selected,
          onDestinationSelected: (index) => setState(() => _selected = index),
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primary.withValues(alpha: .18),
          destinations: _destinations,
        ),
      );
    },
  );
}
