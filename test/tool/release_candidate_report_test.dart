import 'package:flutter_test/flutter_test.dart';

import '../../tool/release_candidate_report.dart';

void main() {
  final generatedAt = DateTime.utc(2026, 7, 16, 12);

  test('complete passing evidence produces deterministic READY report', () {
    final evidence = ReleaseCandidateEvidence(
      branch: 'codex/qa-release-candidate',
      commit: '1234567890abcdef1234567890abcdef12345678',
      version: '0.1.0+1',
      generatedAt: generatedAt,
      gates: const {
        'analyze': 'PASS: no issues',
        'tests': 'PASS: 447/447',
        'webBuild': 'PASS: build/web',
        'performance': 'PASS: 18000 frames',
        'goldens': 'PASS: 6/6',
      },
      openP0: 0,
      openP1: 0,
      openP2: 0,
      openP3: 2,
    );

    final report = generateReleaseCandidateReport(evidence);

    expect(report.decision, ReleaseDecision.ready);
    expect(report.blockingReasons, isEmpty);
    expect(report.markdown, contains('# Release Candidate Report — READY'));
    expect(report.markdown, contains('2026-07-16T12:00:00.000Z'));
    expect(report.markdown, contains('447/447'));
  });

  test('failed gate and open critical bugs produce BLOCKED reasons', () {
    final report = generateReleaseCandidateReport(
      ReleaseCandidateEvidence(
        branch: 'release/test',
        commit: 'abcdef1',
        version: '1.2.3+4',
        generatedAt: generatedAt,
        gates: const {
          'analyze': 'PASS: clean',
          'tests': 'FAIL: one failure',
          'webBuild': 'PASS: built',
          'performance': 'PASS: budget',
          'goldens': 'PASS: 6/6',
        },
        openP0: 0,
        openP1: 2,
        openP2: 0,
        openP3: 0,
      ),
    );

    expect(report.decision, ReleaseDecision.blocked);
    expect(report.blockingReasons, contains('tests evidence failed'));
    expect(report.blockingReasons, contains('2 open P1 defects'));
  });

  test('missing or malformed CLI evidence is rejected', () {
    expect(
      () => parseReleaseCandidateArguments(const ['--branch', 'main']),
      throwsFormatException,
    );
    expect(
      () => parseReleaseCandidateArguments(const [
        '--branch',
        'main',
        '--commit',
        'not-a-sha',
        '--version',
        '1.0.0+1',
        '--generated-at',
        '2026-07-16T12:00:00Z',
        '--analyze',
        'PASS: clean',
        '--tests',
        'PASS: all',
        '--web-build',
        'PASS: built',
        '--performance',
        'PASS: budget',
        '--goldens',
        'PASS: six',
        '--open-p0',
        '0',
        '--open-p1',
        '0',
        '--open-p2',
        '0',
        '--open-p3',
        '0',
        '--output',
        'report.md',
      ]),
      throwsFormatException,
    );
  });
}
