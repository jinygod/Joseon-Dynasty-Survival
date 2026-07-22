import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/augment_definitions.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/models/compendium_entry.dart';
import 'package:pixel_survivor/game/systems/compendium_service.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';

void main() {
  const service = CompendiumService();

  test('catalog contains every character weapon and augment', () {
    final entries = service.entries(SaveState.defaults());

    expect(
      entries.where((item) => item.section == CompendiumSection.character),
      hasLength(characterDefinitions.length),
    );
    expect(
      entries.where((item) => item.section == CompendiumSection.weapon),
      hasLength(weaponDefinitions.length),
    );
    expect(
      entries.where((item) => item.section == CompendiumSection.augment),
      hasLength(augmentDefinitions.length),
    );
  });

  test('starting entries are unlocked with a Korean base condition', () {
    final entries = service.entries(SaveState.defaults());
    final rookie = entries.singleWhere(
      (item) => item.key == 'character:$rookieConstable',
    );
    final sword = entries.singleWhere(
      (item) => item.key == 'weapon:$hwandoSlash',
    );

    expect(rookie.isUnlocked, isTrue);
    expect(rookie.unlockCondition, '기본 해금');
    expect(sword.isUnlocked, isTrue);
    expect(sword.progressFraction, 1);
  });

  test(
    'base weapon stays available while legacy goal metadata is retained',
    () {
      final state = SaveState.defaults().copyWith(totalKills: 120);
      final entries = service.entries(state);
      final bomb = entries.singleWhere(
        (item) => item.key == 'weapon:$thunderCrashBomb',
      );

      expect(bomb.isUnlocked, isTrue);
      expect(bomb.unlockCondition, '누적 적 300명 처치');
      expect(bomb.currentProgress, 120);
      expect(bomb.targetProgress, 300);
    expect(bomb.progressFraction, 1);
    },
  );

  test('unseen keys include only unlocked entries not viewed before', () {
    final state = SaveState.defaults().copyWith(
      seenCompendiumEntryIds: {'character:$rookieConstable'},
    );

    final unseen = service.unseenUnlockedKeys(state);

    expect(unseen, isNot(contains('character:$rookieConstable')));
    expect(unseen, contains('weapon:$hwandoSlash'));
    expect(unseen, contains('weapon:$thunderCrashBomb'));
  });
}
