import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/audio/audio_asset_catalog.dart';
import 'package:pixel_survivor/game/audio/audio_cue.dart';

void main() {
  test('catalog maps every cue to a bundled replaceable audio file', () {
    expect(AudioAssetCatalog.assets.keys.toSet(), AudioCue.values.toSet());

    for (final entry in AudioAssetCatalog.assets.entries) {
      expect(entry.value.path, startsWith('audio/'));
      expect(entry.value.path, isNot(contains('..')));
      expect(
        File('assets/${entry.value.path}').existsSync(),
        isTrue,
        reason: '${entry.key.name} is missing ${entry.value.path}',
      );
    }
  });

  test('only looping music cues are marked as loops', () {
    const looping = {
      AudioCue.menuMusic,
      AudioCue.battleMusic,
      AudioCue.bossMusic,
    };

    for (final cue in AudioCue.values) {
      expect(
        AudioAssetCatalog.forCue(cue).loop,
        looping.contains(cue),
        reason: cue.name,
      );
    }
  });
}
