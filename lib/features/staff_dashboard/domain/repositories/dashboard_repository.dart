import '../../../orders/domain/entities/order.dart';
import '../../../tables/domain/entities/restaurant_table.dart';

class DashboardStats {
  const DashboardStats({
    required this.openSessions,
    required this.activeOrders,
    required this.unpaidSessions,
    required this.tables,
  });

  final int openSessions;
  final int activeOrders;
  final int unpaidSessions;
  final int tables;
}

class DashboardData {
  const DashboardData({
    required this.stats,
    required this.tables,
    required this.recentOrders,
  });

  final DashboardStats stats;
  final List<RestaurantTable> tables;
  final List<Order> recentOrders;
}

abstract class DashboardRepository {
  Future<DashboardData> getDashboard();
}
