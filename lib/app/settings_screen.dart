import 'dart:async';

import 'package:flutter/material.dart';

import '../game/systems/save_system.dart';
import 'game_settings.dart';
import 'game_settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.controller,
    this.progressStore,
    this.resetProgress,
    super.key,
  });

  final GameSettingsController controller;
  final SaveStore? progressStore;
  final Future<bool> Function()? resetProgress;

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
                    const _SectionTitle('소리'),
                    Text('음악 ${(settings.musicVolume * 100).round()}%'),
                    Slider(
                      key: const Key('music-volume'),
                      value: settings.musicVolume,
                      divisions: 10,
                      onChanged: (value) {
                        unawaited(controller.setMusicVolume(value));
                      },
                    ),
                    Text('효과음 ${(settings.sfxVolume * 100).round()}%'),
                    Slider(
                      key: const Key('sfx-volume'),
                      value: settings.sfxVolume,
                      divisions: 10,
                      onChanged: (value) {
                        unawaited(controller.setSfxVolume(value));
                      },
                    ),
                    SwitchListTile(
                      key: const Key('vibration-enabled'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('진동'),
                      value: settings.vibrationEnabled,
                      onChanged: (value) {
                        unawaited(controller.setVibrationEnabled(value));
                      },
                    ),
                    const _SectionTitle('접근성'),
                    SwitchListTile(
                      key: const Key('screen-shake-enabled'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('화면 흔들림'),
                      value: settings.screenShakeEnabled,
                      onChanged: (value) {
                        unawaited(controller.setScreenShakeEnabled(value));
                      },
                    ),
                    SwitchListTile(
                      key: const Key('damage-numbers-enabled'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('피해 숫자'),
                      value: settings.damageNumbersEnabled,
                      onChanged: (value) {
                        unawaited(controller.setDamageNumbersEnabled(value));
                      },
                    ),
                    const Text('UI 크기'),
                    const SizedBox(height: 8),
                    SegmentedButton<UiScale>(
                      segments: const [
                        ButtonSegment(
                          value: UiScale.small,
                          label: Text('작게', key: Key('ui-scale-small')),
                        ),
                        ButtonSegment(
                          value: UiScale.normal,
                          label: Text('보통', key: Key('ui-scale-normal')),
                        ),
                        ButtonSegment(
                          value: UiScale.large,
                          label: Text('크게', key: Key('ui-scale-large')),
                        ),
                      ],
                      selected: {settings.uiScale},
                      onSelectionChanged: (selection) {
                        unawaited(controller.setUiScale(selection.single));
                      },
                    ),
                    const SizedBox(height: 28),
                    const Divider(),
                    const _SectionTitle('진행 데이터'),
                    const Text('화폐, 해금, 훈련, 기록을 처음 상태로 되돌립니다.'),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const Key('reset-progress'),
                      onPressed: () => unawaited(_confirmReset(context)),
                      icon: const Icon(Icons.delete_forever_outlined),
                      label: const Text('진행 초기화'),
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

  Future<void> _confirmReset(BuildContext context) async {
    final first = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('진행 데이터를 초기화할까요?'),
        content: const Text('설정은 보존되지만 모든 메타 진행은 삭제됩니다.'),
        actions: [
          TextButton(
            key: const Key('reset-first-cancel'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          FilledButton(
            key: const Key('reset-first-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('계속'),
          ),
        ],
      ),
    );
    if (first != true || !context.mounted) return;
    final finalConfirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('정말 초기화할까요?'),
        content: const Text('이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            key: const Key('reset-final-cancel'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          FilledButton(
            key: const Key('reset-final-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('초기화'),
          ),
        ],
      ),
    );
    if (finalConfirmation != true || !context.mounted) return;
    try {
      final reset = resetProgress;
      final succeeded = reset != null
          ? await reset()
          : await _resetStore(progressStore ?? SaveSystem());
      if (context.mounted && succeeded) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('진행 데이터가 초기화되었습니다.')));
      } else if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('진행 데이터를 초기화하지 못했습니다.')));
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('진행 데이터를 초기화하지 못했습니다.')));
      }
    }
  }

  Future<bool> _resetStore(SaveStore store) async {
    await store.save(SaveState.defaults());
    return true;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 12),
    child: Text(label, style: Theme.of(context).textTheme.titleMedium),
  );
}
