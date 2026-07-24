import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/world/experience_ledger.dart';

void main() {
  test('ownership transfers conserve the exact integer total', () {
    final ledger = ExperienceLedger();
    ledger.add(ExperienceOwner.dropped, 23);
    ledger.transfer(
      from: ExperienceOwner.dropped,
      to: ExperienceOwner.mounted,
      amount: 12,
    );
    ledger.transfer(
      from: ExperienceOwner.dropped,
      to: ExperienceOwner.compressed,
      amount: 11,
    );
    ledger.transfer(
      from: ExperienceOwner.mounted,
      to: ExperienceOwner.magnetized,
      amount: 12,
    );
    ledger.transfer(
      from: ExperienceOwner.magnetized,
      to: ExperienceOwner.granted,
      amount: 12,
    );

    expect(ledger.totalOwnedExperience, 23);
    expect(ledger.valueOf(ExperienceOwner.granted), 12);
    expect(ledger.valueOf(ExperienceOwner.compressed), 11);
  });

  test('invalid ownership transfers fail closed', () {
    final ledger = ExperienceLedger()..add(ExperienceOwner.mounted, 3);

    expect(
      () => ledger.transfer(
        from: ExperienceOwner.mounted,
        to: ExperienceOwner.compressed,
        amount: 4,
      ),
      throwsStateError,
    );
    expect(ledger.totalOwnedExperience, 3);
  });
}
