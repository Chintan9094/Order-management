abstract final class AppConstants {
  static const String clientSessionStorageKey = 'client_session_id';
  static const String staffAccessTokenKey = 'staff_access_token';
  static const String staffRefreshTokenKey = 'staff_refresh_token';
  static const String currencyCode = 'INR';
  static const String currencySymbol = '₹';

  /// Render free tier can take 30–60s to wake from sleep.
  static const Duration defaultConnectTimeout = Duration(seconds: 60);
  static const Duration defaultReceiveTimeout = Duration(seconds: 90);
  static const Duration defaultSendTimeout = Duration(seconds: 60);

  static const Duration staffOrdersPollInterval = Duration(seconds: 8);
  static const Duration customerSessionPollInterval = Duration(seconds: 12);
}
