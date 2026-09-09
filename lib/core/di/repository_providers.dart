import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../network/api_client.dart';
import '../network/auth_token_store.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/customer_session/data/repositories/customer_session_repository_impl.dart';
import '../../features/customer_session/domain/repositories/customer_session_repository.dart';
import '../../features/menu/data/repositories/menu_repository_impl.dart';
import '../../features/menu/domain/repositories/menu_repository.dart';
import '../../features/orders/data/repositories/order_repository_impl.dart';
import '../../features/orders/domain/repositories/order_repository.dart';
import '../../features/payments/data/repositories/payment_repository_impl.dart';
import '../../features/payments/domain/repositories/payment_repository.dart';
import '../../features/staff_dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../features/staff_dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/tables/data/repositories/table_repository_impl.dart';
import '../../features/tables/domain/repositories/table_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    apiClient: ref.watch(apiClientProvider),
    tokenStore: ref.watch(authTokenStoreProvider),
  );
});

final customerSessionRepositoryProvider =
    Provider<CustomerSessionRepository>((ref) {
  return CustomerSessionRepositoryImpl(
    apiClient: ref.watch(apiClientProvider),
    tokenStore: ref.watch(authTokenStoreProvider),
  );
});

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MenuRepositoryImpl(apiClient: ref.watch(apiClientProvider));
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepositoryImpl(apiClient: ref.watch(apiClientProvider));
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl(apiClient: ref.watch(apiClientProvider));
});

final tableRepositoryProvider = Provider<TableRepository>((ref) {
  return TableRepositoryImpl(
    apiClient: ref.watch(apiClientProvider),
    config: ref.watch(appConfigProvider),
  );
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(apiClient: ref.watch(apiClientProvider));
});
