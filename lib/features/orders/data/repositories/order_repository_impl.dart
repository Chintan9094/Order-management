import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception_guard.dart';
import '../../../../core/network/json_helpers.dart';
import '../../../shared/domain/enums.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../mappers/order_mapper.dart';

class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  @override
  Future<Order> placeOrder({
    required String sessionId,
    required List<PlaceOrderItemRequest> items,
    String? orderNote,
    String? idempotencyKey,
  }) {
    return guardApiCall(() async {
      // PlaceOrderRequest validates snake_case field names.
      final body = <String, dynamic>{
        'items': items
            .map(
              (item) => {
                'menu_item_id': int.tryParse(item.menuItemId) ?? item.menuItemId,
                'quantity': item.quantity,
                if (item.note != null && item.note!.isNotEmpty)
                  'note': item.note,
              },
            )
            .toList(),
        if (orderNote != null && orderNote.isNotEmpty) 'notes': orderNote,
        if (idempotencyKey != null && idempotencyKey.isNotEmpty)
          'idempotency_key': idempotencyKey,
      };

      final response = await _api.post<Map<String, dynamic>>(
        ApiEndpoints.sessionOrders(sessionId),
        data: body,
      );
      final data = JsonHelpers.unwrapDataMap(response.data);
      return OrderMapper.fromJson(data);
    });
  }

  @override
  Future<Order> placeStaffOrderForTable({
    required String tableId,
    required List<PlaceOrderItemRequest> items,
    String? orderNote,
    String? idempotencyKey,
  }) {
    return guardApiCall(() async {
      final body = <String, dynamic>{
        'items': items
            .map(
              (item) => {
                'menu_item_id': int.tryParse(item.menuItemId) ?? item.menuItemId,
                'quantity': item.quantity,
                if (item.note != null && item.note!.isNotEmpty)
                  'note': item.note,
              },
            )
            .toList(),
        if (orderNote != null && orderNote.isNotEmpty) 'notes': orderNote,
        if (idempotencyKey != null && idempotencyKey.isNotEmpty)
          'idempotency_key': idempotencyKey,
      };

      final response = await _api.post<Map<String, dynamic>>(
        ApiEndpoints.tableOrders(tableId),
        data: body,
      );
      final data = JsonHelpers.unwrapDataMap(response.data);
      return OrderMapper.fromJson(data);
    });
  }

  @override
  Future<List<Order>> getSessionOrders(String sessionId) {
    return guardApiCall(() async {
      final response = await _api.get<Map<String, dynamic>>(
        ApiEndpoints.sessionOrders(sessionId),
      );
      final list = JsonHelpers.unwrapDataList(response.data);
      return list
          .map((e) => OrderMapper.fromJson(JsonHelpers.asMap(e)))
          .toList();
    });
  }

  @override
  Future<List<Order>> getStaffOrders({OrderStatusFilter? filter}) {
    return guardApiCall(() async {
      final query = <String, dynamic>{};
      final statuses = filter?.statuses;
      if (statuses != null && statuses.length == 1) {
        query['status'] = statuses.first.name;
      }
      final response = await _api.get<Map<String, dynamic>>(
        ApiEndpoints.orders,
        queryParameters: query.isEmpty ? null : query,
      );
      final list = JsonHelpers.unwrapDataList(response.data);
      var orders = list
          .map((e) => OrderMapper.fromJson(JsonHelpers.asMap(e)))
          .toList();
      if (statuses != null && statuses.length > 1) {
        orders = orders.where((o) => statuses.contains(o.status)).toList();
      }
      return orders;
    });
  }

  @override
  Future<Order> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  }) {
    return guardApiCall(() async {
      final response = await _api.patch<Map<String, dynamic>>(
        ApiEndpoints.orderStatus(orderId),
        data: {'status': status.name},
      );
      final data = JsonHelpers.unwrapDataMap(response.data);
      return OrderMapper.fromJson(data);
    });
  }
}
