# Realtime Audio Mute Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stop every active or queued voice on a channel as soon as its saved volume becomes zero.

**Architecture:** `GameAudioService` remains the owner of active playback handles and serializes settings application with playback admission. `PixelSurvivorApp` forwards `AudioSettingsController` notifications to the service without coupling the audio layer to Flutter notifiers.

**Tech Stack:** Dart 3.12.2, Flutter 3.44.4, flutter_test, flame_audio 2.12.1

## Global Constraints

- Music volume zero affects only `AudioChannel.music`.
- SFX volume zero affects `AudioChannel.sfx` and `AudioChannel.ui`.
- Unmuting never resumes a voice stopped while muted.
- Existing diagnostic isolation and channel limits remain intact.

---

### Task 1: Stop active and queued muted voices

**Files:**
- Modify: `test/game/game_audio_service_test.dart`
- Modify: `lib/game/audio/game_audio_service.dart`

**Interfaces:**
- Consumes: `AudioSettings Function() readSettings`, tracked `_ActiveVoice` handles
- Produces: `Future<void> GameAudioService.applySettings()` and admission-time setting checks

- [ ] **Step 1: Write failing regression tests**

Add tests that start music/SFX/UI handles, set their channel volume to zero, call `applySettings()`, and assert only muted handles receive `stop()`. Add a barrier test that queues `uiBack`, mutes SFX before its admission, then asserts the backend never receives `uiBack`.

```dart
test('applying zero music volume stops active music only', () async {
  var settings = AudioSettings.defaults;
  final backend = RecordingAudioBackend();
  final service = GameAudioService(
    backend: backend,
    readSettings: () => settings,
  );
  await service.play(AudioCue.battleMusic);
  await service.play(AudioCue.playerHit);
  settings = settings.copyWith(musicVolume: 0);
  await service.applySettings();
  expect(backend.handles[0].stopCount, 1);
  expect(backend.handles[1].stopCount, 0);
});
```

- [ ] **Step 2: Run tests and verify RED**

Run: `flutter test test/game/game_audio_service_test.dart`
Expected: compile failure because `GameAudioService.applySettings` does not exist.

- [ ] **Step 3: Implement serialized settings application**

Change playback admission to pass the cue into the queue, read settings again inside the queue, and build the policy request only when the current volume is positive. Implement `applySettings()` by removing and stopping every tracked voice whose current channel volume is zero.

```dart
Future<void> applySettings() {
  if (_disposed) return Future<void>.value();
  return _enqueue(() async {
    final settings = _readSettings();
    final targets = _activeVoices
        .where((voice) => settings.volumeFor(voice.request.channel) <= 0)
        .toList(growable: false);
    for (final voice in targets) {
      _activeVoices.remove(voice);
      await _guard(
        operation: 'stopVoice',
        cue: voice.request.cue,
        action: voice.handle.stop,
      );
    }
  });
}
```

- [ ] **Step 4: Run focused tests and verify GREEN**

Run: `flutter test test/game/game_audio_service_test.dart`
Expected: all service tests pass.

- [ ] **Step 5: Commit**

Run: `git add lib/game/audio/game_audio_service.dart test/game/game_audio_service_test.dart && git commit -m "fix: stop audio immediately when muted"`

### Task 2: Forward settings notifications from the app

**Files:**
- Modify: `lib/app/pixel_survivor_app.dart`
- Modify: `test/game/game_audio_service_test.dart`

**Interfaces:**
- Consumes: `AudioSettingsController.addListener`, `GameAudioService.applySettings`
- Produces: app-lifetime listener `_applyAudioSettings`

- [ ] **Step 1: Extend the service regression test for loaded settings**

Use a mutable settings value and verify that a call corresponding to a controller notification stops an active voice. This service-level test keeps the behavior deterministic without creating real browser audio.

- [ ] **Step 2: Run the focused test and verify RED when the call is absent from the test arrangement**

Run: `flutter test test/game/game_audio_service_test.dart`
Expected: the active handle has `stopCount == 0` before `applySettings()` is added to the arrangement.

- [ ] **Step 3: Wire controller notifications**

Create the service before starting `load()`, register `_applyAudioSettings`, and remove the listener before disposing the service and controller.

```dart
void _applyAudioSettings() {
  unawaited(_audioService.applySettings());
}
```

- [ ] **Step 4: Run audio and app tests**

Run: `flutter test test/game/game_audio_service_test.dart test/game/audio_settings_controller_test.dart test/app/pause_menu_overlay_test.dart`
Expected: all selected tests pass.

- [ ] **Step 5: Commit**

Run: `git add lib/app/pixel_survivor_app.dart test/game/game_audio_service_test.dart && git commit -m "fix: synchronize mute settings with active audio"`
