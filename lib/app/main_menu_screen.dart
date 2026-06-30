import 'package:flutter/material.dart';

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
              FilledButton(onPressed: () {}, child: const Text('Start Run')),
            ],
          ),
        ),
      ),
    );
  }
}
