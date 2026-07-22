import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/base_content_policy.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/stage_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/models/meta_progress.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';

void main() {
  test('base policy exposes every base character weapon and stage', () {
    expect(
      BaseContentPolicy.characterIds,
      characterDefinitions.map((item) => item.id).toSet(),
    );
    expect(
      BaseContentPolicy.weaponIds,
      weaponDefinitions.map((item) => item.id).toSet(),
    );
    expect(
      BaseContentPolicy.stageIds,
      stageDefinitions.map((item) => item.id).toSet(),
    );
  });

  test('fresh save opens every base item', () {
    final state = SaveState.defaults();

    expect(state.unlockedCharacterIds, BaseContentPolicy.characterIds);
    expect(state.unlockedWeaponIds, BaseContentPolicy.weaponIds);
    expect(state.unlockedStageIds, BaseContentPolicy.stageIds);
    expect(state.unlockedWeaponCount, BaseContentPolicy.weaponIds.length);
  });

  test('current save gains base access without losing progress', () {
    final state = SaveState.fromJson({
      'schemaVersion': SaveState.currentSchemaVersion,
      'unlockedCharacterIds': [rookieConstable],
      'unlockedWeaponIds': [hwandoSlash],
      'unlockedAugmentIds': <String>[],
      'unlockedStageIds': [moonlitAbandonedOffice],
      'completedGoalIds': ['survive_3_minutes'],
      'claimedRewardIds': ['survive_3_minutes'],
      'wallet': {'coin': 77, 'spiritJade': 4},
      'selectedCharacterId': rookieConstable,
      'selectedStageId': moonlitAbandonedOffice,
      'totalKills': 303,
      'unlockedWeaponCount': 1,
    });

    expect(state.unlockedCharacterIds, BaseContentPolicy.characterIds);
    expect(state.unlockedWeaponIds, BaseContentPolicy.weaponIds);
    expect(state.unlockedStageIds, BaseContentPolicy.stageIds);
    expect(state.unlockedWeaponCount, 1);
    expect(state.wallet, const Wallet(coin: 77, spiritJade: 4));
    expect(state.completedGoalIds, contains('survive_3_minutes'));
    expect(state.claimedRewardIds, contains('survive_3_minutes'));
    expect(state.totalKills, 303);
  });
}
