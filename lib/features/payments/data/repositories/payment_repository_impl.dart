import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception_guard.dart';
import '../../../../core/network/json_helpers.dart';
import '../../../customer_session/data/mappers/dining_session_mapper.dart';
import '../../../customer_session/domain/entities/dining_session.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';
import '../mappers/payment_mapper.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  @override
  Future<Payment> markPaid(String paymentId) {
    return guardApiCall(() async {
      final response = await _api.post<Map<String, dynamic>>(
        ApiEndpoints.markPaid(paymentId),
      );
      final data = JsonHelpers.unwrapDataMap(response.data);
      return PaymentMapper.fromJson(data);
    });
  }

  @override
  Future<DiningSession> closeSession(String sessionId) {
    return guardApiCall(() async {
      final response = await _api.post<Map<String, dynamic>>(
        ApiEndpoints.closeSession(sessionId),
      );
      final data = JsonHelpers.unwrapDataMap(response.data);
      return DiningSessionMapper.fromJson(data);
    });
  }
}
