import 'package:flutter/material.dart';
import 'main_menu_screen.dart';

class PixelSurvivorApp extends StatelessWidget {
  const PixelSurvivorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Joseon Dynasty Survival',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff3fbf7f)),
        useMaterial3: true,
      ),
      home: const MainMenuScreen(),
    );
  }
}
