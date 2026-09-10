import '../../../shared/domain/enums.dart';
import '../entities/order.dart';

class PlaceOrderItemRequest {
  const PlaceOrderItemRequest({
    required this.menuItemId,
    required this.quantity,
    this.note,
  });

  final String menuItemId;
  final int quantity;
  final String? note;
}

class OrderStatusFilter {
  const OrderStatusFilter({this.statuses});
  final List<OrderStatus>? statuses;
}

abstract class OrderRepository {
  Future<Order> placeOrder({
    required String sessionId,
    required List<PlaceOrderItemRequest> items,
    String? orderNote,
    String? idempotencyKey,
  });

  /// Staff places an order for a guest at [tableId] (opens session if needed).
  Future<Order> placeStaffOrderForTable({
    required String tableId,
    required List<PlaceOrderItemRequest> items,
    String? orderNote,
    String? idempotencyKey,
  });

  Future<List<Order>> getSessionOrders(String sessionId);

  Future<List<Order>> getStaffOrders({OrderStatusFilter? filter});

  Future<Order> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  });
}
