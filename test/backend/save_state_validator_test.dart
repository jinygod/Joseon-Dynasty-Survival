import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/backend/progress/save_state_validator.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';

void main() {
  final validator = SaveStateValidator();

  test('accepts the canonical non-paid SaveState payload', () {
    expect(
      () => validator.validateJson(SaveState.defaults().toJson()),
      returnsNormally,
    );
  });

  test('rejects paid royal jade and purchase fields', () {
    final paid = {...SaveState.defaults().toJson(), 'royal_jade': 100};
    final purchase = {
      ...SaveState.defaults().toJson(),
      'purchaseState': 'paid',
    };

    expect(() => validator.validateJson(paid), throwsFormatException);
    expect(() => validator.validateJson(purchase), throwsFormatException);
  });

  test('rejects unknown content IDs before SaveState filtering', () {
    final unknownCharacter = {
      ...SaveState.defaults().toJson(),
      'unlockedCharacterIds': ['rookie_constable', 'unknown_character'],
    };
    final unknownWeapon = {
      ...SaveState.defaults().toJson(),
      'selectedCharacterId': 'unknown_character',
    };

    expect(
      () => validator.validateJson(unknownCharacter),
      throwsFormatException,
    );
    expect(() => validator.validateJson(unknownWeapon), throwsFormatException);
  });

  test('rejects unknown nested keys and out-of-range nested ranks', () {
    final unknownWallet = {
      ...SaveState.defaults().toJson(),
      'wallet': {'coin': 0, 'spiritJade': 0, 'royalJade': 5},
    };
    final unknownTraining = {
      ...SaveState.defaults().toJson(),
      'trainingProgress': {
        ...SaveState.defaults().trainingProgress.toJson(),
        'debug': true,
      },
    };
    final excessiveRank = {
      ...SaveState.defaults().toJson(),
      'trainingProgress': {
        'commonRanks': {'common.max_health': 101},
        'characterRanks': <String, dynamic>{},
        'activeCoreTraitIds': <String, dynamic>{},
      },
    };

    expect(() => validator.validateJson(unknownWallet), throwsFormatException);
    expect(
      () => validator.validateJson(unknownTraining),
      throwsFormatException,
    );
    expect(() => validator.validateJson(excessiveRank), throwsFormatException);
  });

  test('bounds counters and validates dynamic claimed reward IDs', () {
    final excessiveCounter = {
      ...SaveState.defaults().toJson(),
      'totalKills': SaveStateValidator.maxCounter + 1,
    };
    final invalidClaim = {
      ...SaveState.defaults().toJson(),
      'claimedRewardIds': ['contains spaces'],
    };
    final tooLongClaim = {
      ...SaveState.defaults().toJson(),
      'claimedRewardIds': ['x' * (SaveStateValidator.maxDynamicIdLength + 1)],
    };
    final tooManyClaims = {
      ...SaveState.defaults().toJson(),
      'claimedRewardIds': List.generate(
        SaveStateValidator.maxClaimedRewardIds + 1,
        (index) => 'drop-$index',
      ),
    };

    expect(
      () => validator.validateJson(excessiveCounter),
      throwsFormatException,
    );
    expect(() => validator.validateJson(invalidClaim), throwsFormatException);
    expect(() => validator.validateJson(tooLongClaim), throwsFormatException);
    expect(() => validator.validateJson(tooManyClaims), throwsFormatException);
  });
}
