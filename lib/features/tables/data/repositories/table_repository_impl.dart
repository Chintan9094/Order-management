import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception_guard.dart';
import '../../../../core/network/json_helpers.dart';
import '../../domain/entities/restaurant_table.dart';
import '../../domain/repositories/table_repository.dart';
import '../mappers/restaurant_table_mapper.dart';

class TableRepositoryImpl implements TableRepository {
  TableRepositoryImpl({
    required ApiClient apiClient,
    required AppConfig config,
  })  : _api = apiClient,
        _config = config;

  final ApiClient _api;
  final AppConfig _config;

  @override
  Future<List<RestaurantTable>> listTables() {
    return guardApiCall(() async {
      final response = await _api.get<Map<String, dynamic>>(
        ApiEndpoints.tables,
      );
      final list = JsonHelpers.unwrapDataList(response.data);
      return list
          .map((e) => RestaurantTableMapper.fromJson(JsonHelpers.asMap(e)))
          .toList();
    });
  }

  @override
  Future<RestaurantTable> createTable({
    required String label,
    int? capacity,
  }) {
    return guardApiCall(() async {
      final response = await _api.post<Map<String, dynamic>>(
        ApiEndpoints.tables,
        data: {
          'label': label,
          'capacity': ?capacity,
        },
      );
      final data = JsonHelpers.unwrapDataMap(response.data);
      return RestaurantTableMapper.fromJson(data);
    });
  }

  @override
  Future<RestaurantTable> updateTable(RestaurantTable table) {
    return guardApiCall(() async {
      final response = await _api.patch<Map<String, dynamic>>(
        ApiEndpoints.table(table.id),
        data: {
          'label': table.label,
          if (table.capacity != null) 'capacity': table.capacity,
          'is_active': table.isActive,
        },
      );
      final data = JsonHelpers.unwrapDataMap(response.data);
      return RestaurantTableMapper.fromJson(data);
    });
  }

  @override
  Future<void> deactivateTable(String tableId) {
    return guardApiCall(() async {
      await _api.delete(ApiEndpoints.table(tableId));
    });
  }

  @override
  Future<TableQrInfo> getTableQr(String tableId) {
    return guardApiCall(() async {
      final response = await _api.get<Map<String, dynamic>>(
        ApiEndpoints.tableQr(tableId),
      );
      final data = JsonHelpers.unwrapDataMap(response.data);
      final publicToken = JsonHelpers.asString(
            JsonHelpers.pick(data, ['publicToken', 'public_token']),
          ) ??
          '';
      final payload = JsonHelpers.asString(
            JsonHelpers.pick(data, ['qrPayload', 'qr_payload']),
          ) ??
          _config.tableQrUrl(publicToken);
      return TableQrInfo(
        tableId: JsonHelpers.id(
          JsonHelpers.pick(data, ['tableId', 'table_id']) ?? tableId,
        ),
        label: JsonHelpers.asString(data['label']) ?? '',
        publicToken: publicToken,
        qrPayload: payload,
      );
    });
  }
}
