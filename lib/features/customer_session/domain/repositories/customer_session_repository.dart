import '../../../orders/domain/entities/order.dart';
import '../../../payments/domain/entities/payment.dart';
import '../../../tables/domain/entities/restaurant.dart';
import '../../../tables/domain/entities/restaurant_table.dart';
import '../entities/dining_session.dart';

class TableResolveResult {
  const TableResolveResult({
    required this.restaurant,
    required this.table,
    required this.session,
    required this.sessionToken,
    this.payment,
  });

  final Restaurant restaurant;
  final RestaurantTable table;
  final DiningSession session;
  final String sessionToken;
  final Payment? payment;
}

/// Session detail including nested orders / payment when the API returns them.
class DiningSessionDetail {
  const DiningSessionDetail({
    required this.session,
    this.orders = const [],
    this.payment,
    this.table,
  });

  final DiningSession session;
  final List<Order> orders;
  final Payment? payment;
  final RestaurantTable? table;
}

abstract class CustomerSessionRepository {
  Future<TableResolveResult> resolveTable({required String tablePublicToken});

  Future<DiningSessionDetail> getSession(String sessionId);
}
