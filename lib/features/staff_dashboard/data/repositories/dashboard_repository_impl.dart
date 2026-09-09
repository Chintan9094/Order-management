import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception_guard.dart';
import '../../../../core/network/json_helpers.dart';
import '../../../orders/data/mappers/order_mapper.dart';
import '../../../tables/data/mappers/restaurant_table_mapper.dart';
import '../../domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  @override
  Future<DashboardData> getDashboard() {
    return guardApiCall(() async {
      final response = await _api.get<Map<String, dynamic>>(
        ApiEndpoints.dashboard,
      );
      final data = JsonHelpers.unwrapDataMap(response.data);
      final statsMap = JsonHelpers.asMap(data['stats'] ?? const {});
      final tablesRaw = data['tables'];
      final ordersRaw = data['recentOrders'] ?? data['recent_orders'];

      final tableList = tablesRaw is List ? tablesRaw : const [];
      final orderList = ordersRaw is List ? ordersRaw : const [];

      return DashboardData(
        stats: DashboardStats(
          openSessions: JsonHelpers.asInt(
            JsonHelpers.pick(statsMap, ['openSessions', 'open_sessions']),
          ),
          activeOrders: JsonHelpers.asInt(
            JsonHelpers.pick(statsMap, ['activeOrders', 'active_orders']),
          ),
          unpaidSessions: JsonHelpers.asInt(
            JsonHelpers.pick(statsMap, ['unpaidSessions', 'unpaid_sessions']),
          ),
          tables: JsonHelpers.asInt(statsMap['tables']),
        ),
        tables: tableList
            .map((e) => RestaurantTableMapper.fromJson(JsonHelpers.asMap(e)))
            .toList(),
        recentOrders: orderList
            .map((e) => OrderMapper.fromJson(JsonHelpers.asMap(e)))
            .toList(),
      );
    });
  }
}
