import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_visual_theme.dart';

void main() {
  test('all twelve base weapons have authored readable visual themes', () {
    final ids = weaponDefinitions.map((weapon) => weapon.id).toSet();

    expect(weaponVisualThemes.keys.toSet(), ids);
    expect(
      weaponVisualThemes.values.map((theme) => theme.primary).toSet(),
      hasLength(12),
    );
    expect(
      weaponVisualThemes.values.every(
        (theme) => theme.masterScale > 1 && theme.trailWidth >= 2,
      ),
      isTrue,
    );
  });
}
