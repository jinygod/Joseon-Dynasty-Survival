import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/backend/economy/premium_wallet.dart';
import 'package:pixel_survivor/backend/progress/cloud_progress_repository.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';

void main() {
  test('paid wallet cannot be represented as a negative balance', () {
    expect(
      () => PremiumWallet(balance: -1, debt: 0, version: 0),
      throwsArgumentError,
    );
  });

  test('cloud snapshot carries the server revision and SaveState', () {
    final snapshot = CloudProgressSnapshot(
      revision: 7,
      save: SaveState.defaults(),
    );

    expect(snapshot.revision, 7);
    expect(snapshot.save.schemaVersion, SaveState.currentSchemaVersion);
  });
}
