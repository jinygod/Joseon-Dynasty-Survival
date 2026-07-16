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
}
