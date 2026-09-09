import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_ui.dart';
import '../../../../routing/routes.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'staff_dashboard_tab.dart';
import 'staff_menu_tab.dart';
import 'staff_orders_tab.dart';
import 'staff_tables_tab.dart';

class StaffShellScreen extends ConsumerStatefulWidget {
  const StaffShellScreen({super.key});

  @override
  ConsumerState<StaffShellScreen> createState() => _StaffShellScreenState();
}

class _StaffShellScreenState extends ConsumerState<StaffShellScreen> {
  int _index = 0;

  static const _titles = ['Dashboard', 'Orders', 'Tables', 'Menu'];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: PageBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_titles[_index], style: textTheme.headlineMedium),
                          if (user != null)
                            Text(
                              '${user.displayName} · ${user.role.name}',
                              style: textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Sign out',
                      onPressed: () async {
                        await ref.read(authControllerProvider.notifier).logout();
                        if (context.mounted) context.go(AppRoutes.home);
                      },
                      icon: const Icon(Icons.logout_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _index,
                  children: const [
                    StaffDashboardTab(),
                    StaffOrdersTab(),
                    StaffTablesTab(),
                    StaffMenuTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.table_restaurant_rounded),
            label: 'Tables',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_rounded),
            label: 'Menu',
          ),
        ],
      ),
    );
  }
}
