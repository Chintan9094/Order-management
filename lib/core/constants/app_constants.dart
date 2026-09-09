abstract final class AppConstants {
  static const String clientSessionStorageKey = 'client_session_id';
  static const String staffAccessTokenKey = 'staff_access_token';
  static const String staffRefreshTokenKey = 'staff_refresh_token';
  static const String currencyCode = 'INR';
  static const String currencySymbol = '₹';
  static const Duration defaultConnectTimeout = Duration(seconds: 15);
  static const Duration defaultReceiveTimeout = Duration(seconds: 20);
  static const Duration staffOrdersPollInterval = Duration(seconds: 8);
  static const Duration customerSessionPollInterval = Duration(seconds: 12);
}
