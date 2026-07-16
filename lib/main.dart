import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/pixel_survivor_app.dart';
import 'backend/backend_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  final config = BackendConfig.fromEnvironment();
  if (config.enabled) {
    await Supabase.initialize(
      url: config.url,
      publishableKey: config.publishableKey,
    );
  }
  runApp(PixelSurvivorApp(backendConfig: config));
}
