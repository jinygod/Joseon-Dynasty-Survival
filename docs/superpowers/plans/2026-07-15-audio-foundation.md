# Audio Service Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a typed, silent-by-default audio boundary that can accept future music and sound-effect backends without coupling game logic to files or plugins.

**Architecture:** Pure Dart cue and channel types feed a `GameAudioService`, which classifies cues and delegates to an `AudioBackend`. The initial `SilentAudioBackend` succeeds without platform bindings or assets, while the service contains backend failures and emits optional development diagnostics.

**Tech Stack:** Dart 3.12.2, Flutter 3.44.4, `flutter_test`; no audio package and no audio files

## Global Constraints

- Do not add, generate, download, or approve audio files.
- Do not add an audio playback dependency.
- Keep music, sound effects, and UI as the only three channels.
- Do not connect cues to live game events in `AUD-001`; event wiring belongs to `AUD-003` through `AUD-005`.
- Defer concurrency limits, pitch variation, and priority to `AUD-006`.
- Defer volume and vibration persistence to `AUD-007`.
- Audio failures must never escape into gameplay, result handling, saving, or app shutdown.

---

## File Structure

- Create `lib/game/audio/audio_cue.dart`: cue enum, channel enum, and total cue-to-channel mapping.
- Create `lib/game/audio/audio_backend.dart`: backend interface and silent implementation.
- Create `lib/game/audio/game_audio_service.dart`: guarded delegation, diagnostics, and disposal state.
- Create `test/game/audio_cue_test.dart`: total mapping and channel grouping tests.
- Create `test/game/silent_audio_backend_test.dart`: no-op backend contract test.
- Create `test/game/game_audio_service_test.dart`: delegation, lifecycle, failure isolation, and disposal tests.
- Modify `docs/master-development-todo.md`: record `AUD-001` verification and advance the queue without completing later audio milestones.
- Modify `docs/superpowers/plans/2026-07-15-audio-foundation.md`: mark verified execution steps.

---

### Task 1: Typed audio cue catalog

**Files:**
- Create: `lib/game/audio/audio_cue.dart`
- Test: `test/game/audio_cue_test.dart`

**Interfaces:**
- Produces: `AudioChannel`, `AudioCue`, and `AudioCueCatalog.channelFor(AudioCue cue)`.
- Consumes: no platform or Flutter bindings.

- [x] **Step 1: Write failing cue mapping tests**

```dart
test('every audio cue maps to exactly one supported channel', () {
  for (final cue in AudioCue.values) {
    expect(AudioCueCatalog.channelFor(cue), isIn(AudioChannel.values));
  }
});

test('music cues use only the music channel', () {
  const music = {
    AudioCue.menuMusic,
    AudioCue.battleMusic,
    AudioCue.bossMusic,
    AudioCue.victoryMusic,
    AudioCue.defeatMusic,
  };
  expect(
    music.every((cue) => AudioCueCatalog.channelFor(cue) == AudioChannel.music),
    isTrue,
  );
});

test('combat and UI cues use their dedicated channels', () {
  expect(AudioCueCatalog.channelFor(AudioCue.playerHit), AudioChannel.sfx);
  expect(AudioCueCatalog.channelFor(AudioCue.levelUp), AudioChannel.sfx);
  expect(AudioCueCatalog.channelFor(AudioCue.uiConfirm), AudioChannel.ui);
  expect(AudioCueCatalog.channelFor(AudioCue.uiBack), AudioChannel.ui);
});
```

- [x] **Step 2: Run tests and verify RED**

Run: `flutter test test/game/audio_cue_test.dart`

Expected: compilation fails because `audio_cue.dart`, `AudioCue`, `AudioChannel`, and `AudioCueCatalog` do not exist.

- [x] **Step 3: Implement the complete cue and channel mapping**

```dart
enum AudioChannel { music, sfx, ui }

enum AudioCue {
  menuMusic,
  battleMusic,
  bossMusic,
  victoryMusic,
  defeatMusic,
  hwandoAttack,
  bowAttack,
  talismanAttack,
  bombAttack,
  playerHit,
  criticalHit,
  enemyDeath,
  experiencePickup,
  levelUp,
  bossWarning,
  uiConfirm,
  uiBack,
}

abstract final class AudioCueCatalog {
  static AudioChannel channelFor(AudioCue cue) => switch (cue) {
    AudioCue.menuMusic ||
    AudioCue.battleMusic ||
    AudioCue.bossMusic ||
    AudioCue.victoryMusic ||
    AudioCue.defeatMusic => AudioChannel.music,
    AudioCue.uiConfirm || AudioCue.uiBack => AudioChannel.ui,
    _ => AudioChannel.sfx,
  };
}
```

- [x] **Step 4: Run tests and verify GREEN**

Run: `flutter test test/game/audio_cue_test.dart`

Expected: 3 tests pass.

- [x] **Step 5: Commit**

```powershell
git add lib/game/audio/audio_cue.dart test/game/audio_cue_test.dart
git commit -m "feat: define typed game audio cues"
```

### Task 2: Backend contract and silent implementation

**Files:**
- Create: `lib/game/audio/audio_backend.dart`
- Test: `test/game/silent_audio_backend_test.dart`

**Interfaces:**
- Consumes: `AudioCue` and `AudioChannel` from Task 1.
- Produces: `AudioBackend` and `SilentAudioBackend` with `play`, `stopMusic`, `pauseAll`, `resumeAll`, and `dispose`.

- [x] **Step 1: Write the failing silent-backend test**

```dart
test('silent backend accepts every command without platform bindings', () async {
  const backend = SilentAudioBackend();
  await backend.play(AudioCue.playerHit, AudioChannel.sfx);
  await backend.stopMusic();
  await backend.pauseAll();
  await backend.resumeAll();
  await backend.dispose();
});
```

- [x] **Step 2: Run the test and verify RED**

Run: `flutter test test/game/silent_audio_backend_test.dart`

Expected: compilation fails because `AudioBackend` and `SilentAudioBackend` do not exist.

- [x] **Step 3: Implement the minimal backend API**

```dart
abstract interface class AudioBackend {
  Future<void> play(AudioCue cue, AudioChannel channel);
  Future<void> stopMusic();
  Future<void> pauseAll();
  Future<void> resumeAll();
  Future<void> dispose();
}

class SilentAudioBackend implements AudioBackend {
  const SilentAudioBackend();

  @override
  Future<void> play(AudioCue cue, AudioChannel channel) async {}
  @override
  Future<void> stopMusic() async {}
  @override
  Future<void> pauseAll() async {}
  @override
  Future<void> resumeAll() async {}
  @override
  Future<void> dispose() async {}
}
```

- [x] **Step 4: Run the test and verify GREEN**

Run: `flutter test test/game/silent_audio_backend_test.dart`

Expected: 1 test passes without `TestWidgetsFlutterBinding.ensureInitialized()`.

- [x] **Step 5: Commit**

```powershell
git add lib/game/audio/audio_backend.dart test/game/silent_audio_backend_test.dart
git commit -m "feat: add silent audio backend contract"
```

### Task 3: Guarded game audio service

**Files:**
- Create: `lib/game/audio/game_audio_service.dart`
- Test: `test/game/game_audio_service_test.dart`

**Interfaces:**
- Consumes: an `AudioBackend` and optional `void Function(AudioDiagnostic)` reporter.
- Produces: `AudioDiagnostic` and `GameAudioService.play`, `stopMusic`, `pauseAll`, `resumeAll`, and `dispose`.

- [x] **Step 1: Write failing delegation and lifecycle tests with a recording backend**

```dart
test('service forwards a cue with its catalog channel', () async {
  final backend = RecordingAudioBackend();
  final service = GameAudioService(backend: backend);
  await service.play(AudioCue.playerHit);
  expect(backend.commands, ['play:playerHit:sfx']);
});

test('service forwards lifecycle commands in call order', () async {
  final backend = RecordingAudioBackend();
  final service = GameAudioService(backend: backend);
  await service.stopMusic();
  await service.pauseAll();
  await service.resumeAll();
  await service.dispose();
  expect(backend.commands, ['stopMusic', 'pauseAll', 'resumeAll', 'dispose']);
});
```

- [x] **Step 2: Write failing error-isolation and disposal tests**

```dart
test('backend errors become one diagnostic and never escape', () async {
  final diagnostics = <AudioDiagnostic>[];
  final service = GameAudioService(
    backend: ThrowingAudioBackend(),
    reportDiagnostic: diagnostics.add,
  );
  await service.play(AudioCue.bossWarning);
  expect(diagnostics, hasLength(1));
  expect(diagnostics.single.operation, 'play');
  expect(diagnostics.single.cue, AudioCue.bossWarning);
});

test('diagnostic reporter errors never escape', () async {
  final service = GameAudioService(
    backend: ThrowingAudioBackend(),
    reportDiagnostic: (_) => throw StateError('reporter failed'),
  );
  await service.pauseAll();
});

test('dispose is idempotent and suppresses later commands', () async {
  final backend = RecordingAudioBackend();
  final service = GameAudioService(backend: backend);
  await service.dispose();
  await service.dispose();
  await service.play(AudioCue.uiConfirm);
  await service.resumeAll();
  expect(backend.commands, ['dispose']);
});
```

- [x] **Step 3: Run tests and verify RED**

Run: `flutter test test/game/game_audio_service_test.dart`

Expected: compilation fails because `GameAudioService` and `AudioDiagnostic` do not exist.

- [x] **Step 4: Implement guarded delegation and disposal**

```dart
class AudioDiagnostic {
  const AudioDiagnostic({
    required this.operation,
    required this.cue,
    required this.error,
    required this.stackTrace,
  });
  final String operation;
  final AudioCue? cue;
  final Object error;
  final StackTrace stackTrace;
}

class GameAudioService {
  GameAudioService({required AudioBackend backend,
      void Function(AudioDiagnostic)? reportDiagnostic})
      : _backend = backend,
        _reportDiagnostic = reportDiagnostic;

  final AudioBackend _backend;
  final void Function(AudioDiagnostic)? _reportDiagnostic;
  bool _disposed = false;

  Future<void> play(AudioCue cue) {
    if (_disposed) return Future.value();
    return _guard('play', cue,
        () => _backend.play(cue, AudioCueCatalog.channelFor(cue)));
  }

  Future<void> stopMusic() =>
      _disposed ? Future.value() : _guard('stopMusic', null, _backend.stopMusic);
  Future<void> pauseAll() =>
      _disposed ? Future.value() : _guard('pauseAll', null, _backend.pauseAll);
  Future<void> resumeAll() =>
      _disposed ? Future.value() : _guard('resumeAll', null, _backend.resumeAll);

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _guard('dispose', null, _backend.dispose);
  }

  Future<void> _guard(String operation, AudioCue? cue,
      Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stackTrace) {
      try {
        _reportDiagnostic?.call(AudioDiagnostic(
          operation: operation,
          cue: cue,
          error: error,
          stackTrace: stackTrace,
        ));
      } catch (_) {}
    }
  }
}
```

- [x] **Step 5: Run tests and verify GREEN**

Run: `flutter test test/game/game_audio_service_test.dart test/game/audio_cue_test.dart test/game/silent_audio_backend_test.dart`

Expected: 9 new tests pass.

- [x] **Step 6: Commit**

```powershell
git add lib/game/audio/game_audio_service.dart test/game/game_audio_service_test.dart
git commit -m "feat: isolate game audio service failures"
```

### Task 4: Release evidence and milestone tracking

**Files:**
- Modify: `docs/master-development-todo.md`
- Modify: `docs/superpowers/plans/2026-07-15-audio-foundation.md`

**Interfaces:**
- Consumes: fresh format, analysis, full-test, web-build, and Android-debug-build results.
- Produces: checked execution steps and exact `AUD-001` evidence without changing `AUD-002` through `AUD-010`.

- [x] **Step 1: Run the complete release gate**

Run: `powershell -ExecutionPolicy Bypass -File tool/release_check.ps1 -IncludeAndroid`

Expected: formatting unchanged, Dart analysis has zero issues, all 211 tests pass, web build succeeds, Android debug APK build succeeds, and the script exits 0.

- [x] **Step 2: Update the master TODO**

Mark only `AUD-001` complete. Record 17 typed cues, 3 channels, the backend contract, silent backend, guarded service, 9 new tests, 211 total tests, and successful web/Android builds. Set the next independent Codex queue item to `AUD-006`; retain `AUD-002` through `AUD-005` as incomplete because they require sound-source policy or actual audio.

- [x] **Step 3: Check the implementation against the approved design**

Confirm that no audio package, audio file, live game-event wiring, concurrency policy, pitch policy, volume setting, or haptic behavior was added.

- [x] **Step 4: Mark all verified plan steps complete**

Change every completed checkbox in this plan to `[x]` only after Steps 1 through 3 pass.

- [x] **Step 5: Commit release evidence**

```powershell
git add docs/master-development-todo.md docs/superpowers/plans/2026-07-15-audio-foundation.md
git commit -m "docs: complete audio foundation milestone"
```
