import 'package:flutter/material.dart';

import 'game_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Joseon Dynasty Survival',
                style: TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const GameScreen()),
                  );
                },
                child: const Text('Start Run'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
