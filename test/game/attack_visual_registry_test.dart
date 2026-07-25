import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/attack_visual_registry.dart';

void main() {
  test('Hwando visual contracts declare layers and timing', () {
    final spec = AttackVisualRegistry.byId('hwando_slash');

    expect(spec.status, AttackVisualStatus.ready);
    expect(
      spec.layers.map((layer) => layer.id),
      orderedEquals(['windup', 'strike', 'recovery']),
    );
    expect(spec.layers.every((layer) => layer.frameSize == 128), isTrue);
    expect(
      spec.layers.every((layer) => layer.assetKey.startsWith('vfx/')),
      isTrue,
    );
  });

  test('all Hwando executor IDs have a visual contract', () {
    const hwandoIds = [
      'hwando_slash',
      'hwando_slash_left',
      'hwando_slash_right',
      'hwando_blade_wave',
      'hwando_master_opener',
      'hwando_master_left',
      'hwando_master_right',
      'hwando_master_circle',
      'hwando_master_finisher',
    ];

    for (final id in hwandoIds) {
      expect(
        AttackVisualRegistry.byId(id).category,
        CombatVisualCategory.hwando,
      );
    }
  });

  test('unknown IDs are explicit in development', () {
    expect(
      () => AttackVisualRegistry.byId('not_registered'),
      throwsA(isA<MissingAttackVisualException>()),
    );
  });

  test('required asset keys are deduplicated', () {
    final assetKeys = AttackVisualRegistry.requiredAssetKeys;

    expect(assetKeys.toSet().length, assetKeys.length);
  });

  test('effect IDs are immutable and resolve through the registry', () {
    final effectIds = AttackVisualRegistry.effectIds;

    expect(effectIds, isNotEmpty);
    expect(
      effectIds.every(
        (effectId) => AttackVisualRegistry.byId(effectId).effectId == effectId,
      ),
      isTrue,
    );
    expect(() => effectIds.add('not_registered'), throwsUnsupportedError);
  });
}
