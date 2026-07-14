import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import 'main_menu_screen.dart';

class PixelSurvivorApp extends StatelessWidget {
  const PixelSurvivorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff3fbf7f)),
        splashFactory: NoSplash.splashFactory,
        useMaterial3: false,
      ),
      home: const MainMenuScreen(),
    );
  }
}
