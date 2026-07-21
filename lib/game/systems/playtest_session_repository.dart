import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class PlaytestSessionRepository {
  PlaytestSessionRepository({this.preferences});

  static const _runCountKey = 'playtest_run_count';

  final SharedPreferences? preferences;
  Future<void> _reservationTail = Future<void>.value();

  Future<int> beginRun() async {
    final activePreferences =
        preferences ?? await SharedPreferences.getInstance();
    final ordinal = (activePreferences.getInt(_runCountKey) ?? 0) + 1;
    await activePreferences.setInt(_runCountKey, ordinal);
    return ordinal;
  }

  Future<int> loadRunCount() async {
    final activePreferences =
        preferences ?? await SharedPreferences.getInstance();
    return activePreferences.getInt(_runCountKey) ?? 0;
  }

  Future<bool> cancelRun(int ordinal) async {
    final activePreferences =
        preferences ?? await SharedPreferences.getInstance();
    if (ordinal <= 0 || activePreferences.getInt(_runCountKey) != ordinal) {
      return false;
    }
    if (ordinal == 1) {
      await activePreferences.remove(_runCountKey);
    } else {
      await activePreferences.setInt(_runCountKey, ordinal - 1);
    }
    return true;
  }

  Future<PlaytestRunReservation> reserveRun() async {
    final predecessor = _reservationTail;
    final release = Completer<void>();
    _reservationTail = predecessor.then((_) => release.future);
    await predecessor;
    try {
      final ordinal = await beginRun();
      return PlaytestRunReservation._(
        ordinal: ordinal,
        cancelReservation: () => cancelRun(ordinal),
        release: release,
      );
    } on Object {
      release.complete();
      rethrow;
    }
  }
}

class PlaytestRunReservation {
  PlaytestRunReservation._({
    required this.ordinal,
    required this._cancelReservation,
    required this._release,
  });

  final int ordinal;
  final Future<bool> Function() _cancelReservation;
  final Completer<void> _release;
  bool _finished = false;

  void confirm() {
    if (_finished) return;
    _finished = true;
    _release.complete();
  }

  Future<bool> cancel() async {
    if (_finished) return false;
    _finished = true;
    try {
      return await _cancelReservation();
    } finally {
      _release.complete();
    }
  }
}
