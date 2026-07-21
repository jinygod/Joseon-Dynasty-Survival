import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/systems/playtest_session_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('second begun run is reported as repeat play', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = PlaytestSessionRepository(preferences: preferences);

    expect(await repository.beginRun(), 1);
    expect(await repository.beginRun(), 2);
  });

  test('only the latest matching reservation can be cancelled', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = PlaytestSessionRepository(preferences: preferences);

    final first = await repository.beginRun();
    final second = await repository.beginRun();

    expect(await repository.cancelRun(first), isFalse);
    expect(await repository.loadRunCount(), 2);
    expect(await repository.cancelRun(second), isTrue);
    expect(await repository.loadRunCount(), 1);
  });

  test('a later reservation waits and reuses a cancelled ordinal', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = PlaytestSessionRepository(preferences: preferences);

    final first = await repository.reserveRun();
    var secondCompleted = false;
    final secondFuture = repository.reserveRun().then((reservation) {
      secondCompleted = true;
      return reservation;
    });
    await Future<void>.delayed(Duration.zero);
    expect(secondCompleted, isFalse);

    await first.cancel();
    final second = await secondFuture;
    expect(second.ordinal, 1);
    second.confirm();
    expect(await repository.loadRunCount(), 1);
  });
}
