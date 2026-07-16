import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release policy defines severity, blocking, and unblock contracts', () {
    final policy = File(
      'docs/testing/release-blocking-policy.md',
    ).readAsStringSync();

    for (final severity in ['P0', 'P1', 'P2', 'P3']) {
      expect(policy, contains('## $severity'));
    }
    expect(policy, contains('Open P0: BLOCK'));
    expect(policy, contains('Open P1: BLOCK'));
    expect(policy, contains('Missing required evidence: BLOCK'));
    expect(policy, contains('Failed required evidence: BLOCK'));
    for (final field in ['owner', 'target date', 'workaround', 'release owner']) {
      expect(policy.toLowerCase(), contains(field));
    }
    for (final p2Field in [
      'qa-verified workaround',
      'user and operational risk',
      'evaluation time',
    ]) {
      expect(policy.toLowerCase(), contains(p2Field));
    }
    for (final evidence in [
      'regression test',
      'reproduction',
      'full release gate',
      'reviewer',
    ]) {
      expect(policy.toLowerCase(), contains(evidence));
    }
  });
}
