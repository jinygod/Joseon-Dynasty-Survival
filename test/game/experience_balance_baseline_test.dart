import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/balance/experience_balance_baseline.dart';

void main() {
  group('ExperienceBalanceSimulator', () {
    test('derives the five-minute experience economy from wave data', () {
      final report = const ExperienceBalanceSimulator().simulate();

      expect(report.durationSeconds, 300);
      expect(report.expectedSpawnedExperience, closeTo(1285.4341, 0.001));
      expect(
        defaultExperienceProfiles.map((profile) => profile.acquisitionRate),
        [0.18, 0.25, 0.30],
      );
      expect(report.profileResults, hasLength(3));
    });

    test('exposes the modeled supply shift beyond the 9 to 12 target band', () {
      final report = const ExperienceBalanceSimulator().simulate();

      expect(report.profileResults.map((result) => result.levelUps), [
        11,
        13,
        15,
      ]);
      expect(report.averageLevelUps, 13);
      expect(report.minimumTargetLevelUps, 9);
      expect(report.maximumTargetLevelUps, 12);
      expect(report.meetsTargetBand, isFalse);
    });

    test('uses the production curve and increasing level costs', () {
      const simulator = ExperienceBalanceSimulator();

      expect(simulator.experienceForLevelUps(0), 0);
      expect(simulator.experienceForLevelUps(8), 144);
      expect(simulator.experienceForLevelUps(12), 264);
      expect([
        for (var level = 1; level <= 12; level += 1)
          simulator.costForLevel(level),
      ], orderedEquals([11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, 33]));
    });

    test('is deterministic and rejects invalid acquisition rates', () {
      const simulator = ExperienceBalanceSimulator();
      expect(simulator.simulate().toJson(), simulator.simulate().toJson());
      expect(
        () => simulator.simulate(
          profiles: const [
            ExperienceAcquisitionProfile(id: 'invalid', acquisitionRate: 1.1),
          ],
        ),
        throwsArgumentError,
      );
    });
  });
}
