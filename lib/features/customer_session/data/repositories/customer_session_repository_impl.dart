import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception_guard.dart';
import '../../../../core/network/auth_token_store.dart';
import '../../../../core/network/json_helpers.dart';
import '../../../orders/data/mappers/order_mapper.dart';
import '../../../payments/data/mappers/payment_mapper.dart';
import '../../../tables/data/mappers/restaurant_mapper.dart';
import '../../../tables/data/mappers/restaurant_table_mapper.dart';
import '../../domain/repositories/customer_session_repository.dart';
import '../mappers/dining_session_mapper.dart';

class CustomerSessionRepositoryImpl implements CustomerSessionRepository {
  CustomerSessionRepositoryImpl({
    required ApiClient apiClient,
    required AuthTokenStore tokenStore,
  })  : _api = apiClient,
        _tokenStore = tokenStore;

  final ApiClient _api;
  final AuthTokenStore _tokenStore;

  @override
  Future<TableResolveResult> resolveTable({
    required String tablePublicToken,
  }) {
    return guardApiCall(() async {
      final response = await _api.post<Map<String, dynamic>>(
        ApiEndpoints.resolveTable,
        data: {'token': tablePublicToken.trim()},
      );
      final data = JsonHelpers.unwrapDataMap(response.data);
      final sessionToken =
          JsonHelpers.asString(data['sessionToken']) ??
          JsonHelpers.asString(data['session_token']) ??
          '';
      if (sessionToken.isEmpty) {
        throw StateError('Resolve response missing sessionToken');
      }
      await _tokenStore.saveCustomerSessionToken(sessionToken);

      final paymentRaw = data['payment'];
      return TableResolveResult(
        restaurant: RestaurantMapper.fromJson(
          JsonHelpers.asMap(data['restaurant']),
        ),
        table: RestaurantTableMapper.fromJson(
          JsonHelpers.asMap(data['table']),
        ),
        session: DiningSessionMapper.fromJson(
          JsonHelpers.asMap(data['session']),
        ),
        sessionToken: sessionToken,
        payment: paymentRaw == null
            ? null
            : PaymentMapper.fromJson(JsonHelpers.asMap(paymentRaw)),
      );
    });
  }

  @override
  Future<DiningSessionDetail> getSession(String sessionId) {
    return guardApiCall(() async {
      final response = await _api.get<Map<String, dynamic>>(
        ApiEndpoints.session(sessionId),
      );
      final data = JsonHelpers.unwrapDataMap(response.data);
      final orders = <dynamic>[];
      if (data['orders'] is List) {
        orders.addAll(data['orders'] as List);
      }
      final paymentRaw = data['payment'];
      final tableRaw = data['table'];
      return DiningSessionDetail(
        session: DiningSessionMapper.fromJson(data),
        orders: orders
            .map((o) => OrderMapper.fromJson(JsonHelpers.asMap(o)))
            .toList(),
        payment: paymentRaw == null
            ? null
            : PaymentMapper.fromJson(JsonHelpers.asMap(paymentRaw)),
        table: tableRaw == null
            ? null
            : RestaurantTableMapper.fromJson(JsonHelpers.asMap(tableRaw)),
      );
    });
  }
}
