import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/auth/presentation/screens/staff_login_screen.dart';
import '../features/home/presentation/screens/entry_screen.dart';
import '../features/staff_dashboard/presentation/screens/staff_shell_screen.dart';
import 'routes.dart';

class _RouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.listen<AuthState>(
    authControllerProvider,
    (previous, next) => refresh.ping(),
  );
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      if (auth.status == AuthStatus.unknown) return null;

      final loc = state.matchedLocation;
      final isLogin = loc == AppRoutes.staffLogin || loc == AppRoutes.home;
      final isStaffHome = loc == AppRoutes.staffHome;

      if (!auth.isAuthenticated && isStaffHome) {
        return AppRoutes.staffLogin;
      }
      if (auth.isAuthenticated && isLogin) {
        return AppRoutes.staffHome;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const EntryScreen(),
      ),
      GoRoute(
        path: AppRoutes.staffLogin,
        name: 'staffLogin',
        builder: (context, state) => const StaffLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.staffHome,
        name: 'staffHome',
        builder: (context, state) => const StaffShellScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});
