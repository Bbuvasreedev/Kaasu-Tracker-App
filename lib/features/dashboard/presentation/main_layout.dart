import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kaasutracker/core/localization/generated/app_localizations.dart';
import 'package:kaasutracker/core/routing/app_router.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final l10n = AppLocalizations.of(context)!;
    final selectedIndex = switch (location) {
      AppRoutes.analytics => 1,
      AppRoutes.profile => 2,
      _ => 0,
    };

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          final route = switch (index) {
            1 => AppRoutes.analytics,
            2 => AppRoutes.profile,
            _ => AppRoutes.dashboard,
          };
          if (route != location) context.go(route);
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: l10n.navDashboard,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart_rounded),
            label: l10n.navAnalytics,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: l10n.navProfile,
          ),
        ],
      ),
    );
  }
}
