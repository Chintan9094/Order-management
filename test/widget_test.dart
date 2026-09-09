import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:order_management/app.dart';
import 'package:order_management/core/config/app_config.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Entry screen is staff-only', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              environment: AppEnvironment.development,
              apiBaseUrl: 'https://example.com/api/v1',
              appName: 'Spice Garden',
              enableLogging: false,
              qrDeepLinkScheme: 'restaurant-app',
              qrPublicBaseUrl: 'http://example.com',
              webAppBaseUrl: 'http://example.com:5000',
              enableAppDownload: false,
            ),
          ),
        ],
        child: const OrderManagementApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('SPICE GARDEN'), findsOneWidget);
    expect(find.text('Staff sign in'), findsOneWidget);
    expect(find.text('Enter table code'), findsNothing);
  });
}
