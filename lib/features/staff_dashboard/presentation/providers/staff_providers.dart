import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/repository_providers.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../tables/domain/entities/restaurant_table.dart';
import '../../../tables/domain/repositories/table_repository.dart';
import '../../../menu/domain/entities/menu.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final staffDashboardProvider =
    FutureProvider.autoDispose<DashboardData>((ref) {
  return ref.watch(dashboardRepositoryProvider).getDashboard();
});

final staffOrdersProvider = FutureProvider.autoDispose<List<Order>>((ref) {
  return ref.watch(orderRepositoryProvider).getStaffOrders();
});

final staffTablesProvider =
    FutureProvider.autoDispose<List<RestaurantTable>>((ref) {
  return ref.watch(tableRepositoryProvider).listTables();
});

final staffMenuProvider = FutureProvider.autoDispose<MenuCatalog>((ref) {
  final restaurantId =
      ref.watch(authControllerProvider).user?.restaurantId;
  if (restaurantId == null || restaurantId.isEmpty) {
    throw StateError('Not signed in');
  }
  return ref.watch(menuRepositoryProvider).getStaffMenu(restaurantId);
});

final tableQrProvider =
    FutureProvider.autoDispose.family<TableQrInfo, String>((ref, tableId) {
  return ref.watch(tableRepositoryProvider).getTableQr(tableId);
});
