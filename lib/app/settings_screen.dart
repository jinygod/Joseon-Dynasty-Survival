import 'dart:async';

import 'package:flutter/material.dart';

import '../game/audio/audio_settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.controller, super.key});

  final AudioSettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final settings = controller.settings;
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text('음악 ${(settings.musicVolume * 100).round()}%'),
                    Slider(
                      key: const Key('music-volume'),
                      value: settings.musicVolume,
                      divisions: 10,
                      onChanged: (value) {
                        unawaited(controller.setMusicVolume(value));
                      },
                    ),
                    const SizedBox(height: 12),
                    Text('효과음 ${(settings.sfxVolume * 100).round()}%'),
                    Slider(
                      key: const Key('sfx-volume'),
                      value: settings.sfxVolume,
                      divisions: 10,
                      onChanged: (value) {
                        unawaited(controller.setSfxVolume(value));
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      key: const Key('vibration-enabled'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('진동'),
                      subtitle: const Text('피격과 중요한 경고에 진동을 사용합니다.'),
                      value: settings.vibrationEnabled,
                      onChanged: (value) {
                        unawaited(controller.setVibrationEnabled(value));
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
