import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception_guard.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/auth_token_store.dart';
import '../../../../core/network/json_helpers.dart';
import '../../domain/entities/staff_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../mappers/staff_user_mapper.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required ApiClient apiClient,
    required AuthTokenStore tokenStore,
  })  : _api = apiClient,
        _tokenStore = tokenStore;

  final ApiClient _api;
  final AuthTokenStore _tokenStore;

  @override
  Future<StaffAuthSession> login({
    required String email,
    required String password,
  }) {
    return guardApiCall(() async {
      final response = await _api.post<Map<String, dynamic>>(
        ApiEndpoints.staffLogin,
        data: {
          'email': email.trim(),
          'password': password,
          'device_name': 'flutter-staff',
        },
      );
      final data = JsonHelpers.unwrapDataMap(response.data);
      final token = JsonHelpers.asString(data['token']) ?? '';
      if (token.isEmpty) {
        throw StateError('Login response missing token');
      }
      final userJson = JsonHelpers.asMap(data['user']);
      final user = StaffUserMapper.fromJson(userJson);
      await _tokenStore.saveStaffAccessToken(token);
      return StaffAuthSession(accessToken: token, user: user);
    });
  }

  @override
  Future<void> logout() {
    return guardApiCall(() async {
      try {
        await _api.post(ApiEndpoints.staffLogout);
      } finally {
        await _tokenStore.clearStaffTokens();
      }
    });
  }

  @override
  Future<StaffUser?> currentUser() {
    return guardApiCall(() async {
      final token = await _tokenStore.readStaffAccessToken();
      if (token == null || token.isEmpty) return null;
      final response = await _api.get<Map<String, dynamic>>(
        ApiEndpoints.staffMe,
      );
      final data = JsonHelpers.unwrapDataMap(response.data);
      return StaffUserMapper.fromJson(data);
    });
  }
}
