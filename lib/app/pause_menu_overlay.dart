import 'dart:async';

import 'package:flutter/material.dart';

import '../game/audio/audio_settings_controller.dart';
import 'joseon_buttons.dart';
import 'joseon_panel.dart';

class PauseMenuOverlay extends StatefulWidget {
  const PauseMenuOverlay({
    required this.onResume,
    required this.onRestart,
    required this.onExitToMenu,
    required this.settingsController,
    super.key,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onExitToMenu;
  final AudioSettingsController settingsController;

  @override
  State<PauseMenuOverlay> createState() => _PauseMenuOverlayState();
}

class _PauseMenuOverlayState extends State<PauseMenuOverlay> {
  bool _showSettings = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xdd101820),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: JoseonPanel(
              padding: const EdgeInsets.all(24),
              child: _showSettings ? _buildSettings() : _buildMenu(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenu() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '일시 정지',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 24),
        KeyedSubtree(
          key: const Key('pause-resume'),
          child: JoseonPrimaryButton(label: '계속하기', onPressed: widget.onResume),
        ),
        const SizedBox(height: 10),
        KeyedSubtree(
          key: const Key('pause-restart'),
          child: JoseonSecondaryButton(label: '다시 시작', onPressed: widget.onRestart),
        ),
        const SizedBox(height: 10),
        KeyedSubtree(
          key: const Key('pause-settings'),
          child: JoseonSecondaryButton(
            label: '설정',
            onPressed: () => setState(() => _showSettings = true),
          ),
        ),
        const SizedBox(height: 10),
        KeyedSubtree(
          key: const Key('pause-menu'),
          child: JoseonSecondaryButton(label: '메인 메뉴', onPressed: widget.onExitToMenu),
        ),
      ],
    );
  }

  Widget _buildSettings() {
    return ListenableBuilder(
      listenable: widget.settingsController,
      builder: (context, _) {
        final settings = widget.settingsController.settings;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '설정',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text('음악 ${(settings.musicVolume * 100).round()}%'),
            Slider(
              key: const Key('audio-music-volume'),
              value: settings.musicVolume,
              divisions: 10,
              onChanged: (value) {
                unawaited(widget.settingsController.setMusicVolume(value));
              },
            ),
            Text('효과음 ${(settings.sfxVolume * 100).round()}%'),
            Slider(
              key: const Key('audio-sfx-volume'),
              value: settings.sfxVolume,
              divisions: 10,
              onChanged: (value) {
                unawaited(widget.settingsController.setSfxVolume(value));
              },
            ),
            Material(
              color: Colors.transparent,
              child: SwitchListTile(
              key: const Key('audio-vibration'),
              contentPadding: EdgeInsets.zero,
              title: const Text('진동'),
              value: settings.vibrationEnabled,
              onChanged: (value) {
                unawaited(widget.settingsController.setVibrationEnabled(value));
              },
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              key: const Key('pause-settings-back'),
              onPressed: () => setState(() => _showSettings = false),
              child: const Text('돌아가기'),
            ),
          ],
        );
      },
    );
  }
}
