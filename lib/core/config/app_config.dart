import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppEnvironment { development, staging, production }

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.appName,
    required this.enableLogging,
    required this.qrDeepLinkScheme,
    required this.qrPublicBaseUrl,
    required this.webAppBaseUrl,
    required this.enableAppDownload,
  });

  final AppEnvironment environment;
  final String apiBaseUrl;
  final String appName;
  final bool enableLogging;
  final String qrDeepLinkScheme;
  final String qrPublicBaseUrl;
  final String webAppBaseUrl;
  final bool enableAppDownload;

  bool get isDevelopment => environment == AppEnvironment.development;
  bool get isProduction => environment == AppEnvironment.production;

  /// Camera-friendly QR content (opens landing page in browser).
  String tableQrUrl(String publicToken) {
    final base = qrPublicBaseUrl.replaceAll(RegExp(r'/$'), '');
    return '$base/t/$publicToken';
  }

  String tableAppDeepLink(String publicToken) =>
      '$qrDeepLinkScheme://t/$publicToken';

  factory AppConfig.fromDotEnv({required String flavor}) {
    final envName = dotenv.get('APP_ENV', fallback: flavor);
    return AppConfig(
      environment: _parseEnvironment(envName),
      apiBaseUrl: dotenv.get(
        'API_BASE_URL',
        fallback: 'https://api.dev.example.com/api/v1',
      ),
      appName: dotenv.get('APP_NAME', fallback: 'Order Management'),
      enableLogging: dotenv.get('ENABLE_LOGGING', fallback: 'true') == 'true',
      qrDeepLinkScheme: dotenv.get(
        'QR_DEEP_LINK_SCHEME',
        fallback: 'restaurant-app',
      ),
      qrPublicBaseUrl: dotenv.get(
        'QR_PUBLIC_BASE_URL',
        fallback: 'http://192.168.1.10:8000',
      ),
      webAppBaseUrl: dotenv.get(
        'WEB_APP_BASE_URL',
        fallback: 'http://192.168.1.10:5000',
      ),
      enableAppDownload:
          dotenv.get('ENABLE_APP_DOWNLOAD', fallback: 'false') == 'true',
    );
  }

  static AppEnvironment _parseEnvironment(String value) {
    switch (value) {
      case 'production':
        return AppEnvironment.production;
      case 'staging':
        return AppEnvironment.staging;
      default:
        return AppEnvironment.development;
    }
  }
}

/// Overridden in [bootstrap] after dotenv load.
final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError('appConfigProvider must be overridden in bootstrap');
});
