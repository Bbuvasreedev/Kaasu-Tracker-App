import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kaasutracker/core/network/supabase_client_provider.dart';
import 'package:kaasutracker/features/analytics/presentation/analytics_screen.dart';
import 'package:kaasutracker/features/auth/login_screen.dart';
import 'package:kaasutracker/features/dashboard/presentation/dashboard_page.dart';
import 'package:kaasutracker/features/dashboard/presentation/main_layout.dart';
import 'package:kaasutracker/features/emis/presentation/emi_screen.dart';
import 'package:kaasutracker/features/expenses/presentation/add_expense_screen.dart';
import 'package:kaasutracker/features/profile/presentation/profile_screen.dart';
import 'package:kaasutracker/features/splash/presentation/splash_page.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const analytics = '/analytics';
  static const profile = '/profile';
  static const addExpense = '/expenses/add';
  static const emis = '/emis';
}

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final authRefresh = ValueNotifier<int>(0);
  final authSubscription = supabase.auth.onAuthStateChange.listen((_) {
    authRefresh.value++;
  });

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final session = supabase.auth.currentSession;
      final location = state.matchedLocation;
      final isGoingToLogin = location == AppRoutes.login;

      if (session == null && !isGoingToLogin) {
        return AppRoutes.login;
      }

      if (session != null && (isGoingToLogin || location == AppRoutes.splash)) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.analytics,
            name: 'analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.addExpense,
        name: 'add-expense',
        builder: (context, state) => const AddExpenseScreen(),
      ),
      GoRoute(
        path: AppRoutes.emis,
        name: 'emis',
        builder: (context, state) => const EmiScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
  );

  ref.onDispose(() {
    authSubscription.cancel();
    router.dispose();
    authRefresh.dispose();
  });
  return router;
}
