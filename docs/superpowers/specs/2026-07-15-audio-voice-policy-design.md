# Audio Voice Policy Design

## Goal

Complete `AUD-006` by giving the existing audio boundary deterministic voice limits, cue importance, and repeated-SFX pitch variation. The policy must work before real audio files or a playback package are selected, and future backends must be replaceable without changing gameplay code.

## Scope

This milestone includes:

- a typed playback request containing cue, channel, priority, and pitch;
- a playback handle that reports completion and supports stopping;
- active-voice tracking in `GameAudioService`;
- per-channel simultaneous voice limits;
- deterministic priority-based rejection and preemption;
- deterministic repeated-SFX pitch variation;
- failure isolation for play, stop, completion, and lifecycle operations;
- pure Dart tests and full release-gate evidence.

This milestone does not add audio files, an audio package, game-event wiring, volume persistence, vibration, or asset licensing decisions.

## Playback Contract

`AudioPlaybackRequest` is the complete command sent to a backend. It contains:

- `AudioCue cue`;
- `AudioChannel channel`;
- `AudioPriority priority`;
- `double pitch`.

`AudioBackend.play` returns an `AudioPlaybackHandle`. The handle exposes a `completed` future and `stop()`. A backend completes `completed` when a sound ends naturally or after it is stopped. This lets the service count actual live voices instead of historical play calls.

The silent backend returns an already-completed handle and remains usable without Flutter bindings or real resources.

## Policy

### Channel limits

- music: 1 voice;
- sound effects: 8 voices;
- UI: 2 voices.

Limits are independent. A busy sound-effect channel cannot block music or UI.

### Priority

Priorities are ordered `low`, `normal`, `high`, and `critical`.

- Critical: `bossWarning`, `levelUp`;
- High: `playerHit`, `criticalHit`;
- Low: `experiencePickup`, `enemyDeath`;
- Normal: music, weapon attacks, and UI cues not listed above.

When a channel has room, the request is admitted. When it is full, the service finds the oldest active voice among the lowest active priority. The incoming request preempts that voice only when its priority is strictly higher. Equal- or lower-priority requests are dropped. This preserves stable important feedback and prevents equal-priority bursts from constantly cutting one another off.

### Pitch variation

Repeated sound effects use the deterministic cycle `0.96`, `0.98`, `1.00`, `1.02`, `1.04`, independently per cue. Music and UI always use `1.00`. A deterministic cycle is testable and avoids introducing random-state coupling into gameplay.

The repeat index advances when a sound-effect request is constructed, including a request later dropped by capacity. This keeps pitch generation independent from backend timing and device performance.

## Service Flow

1. `GameAudioService.play(cue)` asks the policy for channel, priority, and pitch.
2. Admission decisions are serialized so concurrent callers cannot exceed a limit while awaiting a backend.
3. The service removes completed handles before checking capacity.
4. If necessary, it stops the chosen lower-priority victim.
5. It calls the backend with the complete request and records the returned handle.
6. Handle completion removes the active voice without blocking gameplay.
7. Backend and handle failures become diagnostics and never escape to gameplay.

The service remains silent after disposal. Disposal stops accepting requests, clears tracked voices, and delegates backend cleanup once.

## Error Handling

All asynchronous boundaries remain guarded. A failed backend play does not consume a voice slot. A failed preemption stop is diagnosed but the stale victim is removed so one broken handle cannot permanently block its channel. Errors from a completion future and errors from the diagnostic reporter are contained.

## Acceptance Criteria

- Every cue has a total priority mapping and every channel has a positive limit.
- SFX pitch cycles exactly and independently per cue; music and UI remain at pitch 1.0.
- Active handles are removed on completion.
- Channel limits remain independent and cannot be exceeded by concurrent play calls.
- Higher priority preempts the oldest voice at the lowest active priority.
- Equal/lower priority is rejected without calling the backend.
- Silent playback completes without retaining an active voice.
- Existing lifecycle, diagnostic, and disposal guarantees remain intact.
- No audio resource, audio dependency, live event connection, settings persistence, or haptic behavior is added.
- Formatting, analysis, all tests, web build, and Android debug APK build pass.
