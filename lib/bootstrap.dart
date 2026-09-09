/// Application bootstrap: env, bindings, then run.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/config/env.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'development');
  await dotenv.load(fileName: Env.fileNameForFlavor(flavor));

  final config = AppConfig.fromDotEnv(flavor: flavor);

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
      ],
      child: const OrderManagementApp(),
    ),
  );
}
