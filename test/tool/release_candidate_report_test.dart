import 'package:flutter_test/flutter_test.dart';

import '../../tool/release_candidate_report.dart';

void main() {
  final generatedAt = DateTime.utc(2026, 7, 16, 12);

  GateEvidence gate({
    int exitCode = 0,
    bool verified = true,
    String? failure,
  }) => GateEvidence(
    command: 'fixed gate command',
    exitCode: exitCode,
    completedAt: generatedAt.subtract(const Duration(minutes: 1)),
    artifactPath: 'build/qa/gate.log',
    artifactHash: 'a1b2c3',
    artifactModifiedAt: generatedAt.subtract(const Duration(minutes: 1)),
    verified: verified,
    verificationFailure: failure,
  );

  ReleaseCandidateEvidence evidence({
    Map<String, GateEvidence>? gates,
    int openP2 = 0,
    int openP3 = 0,
    List<DefectRecord> p2 = const [],
    List<DefectRecord> p3 = const [],
    bool identityVerified = true,
    String? identityFailure,
    DateTime? generatedAtOverride,
  }) => ReleaseCandidateEvidence(
    branch: 'codex/qa-release-candidate',
    commit: '1234567890abcdef1234567890abcdef12345678',
    version: '0.1.0+1',
    generatedAt: generatedAtOverride ?? generatedAt,
    gates: gates ?? {for (final name in requiredReleaseGates) name: gate()},
    openP0: 0,
    openP1: 0,
    openP2: openP2,
    openP3: openP3,
    p2Exceptions: p2,
    p3Records: p3,
    repositoryIdentityVerified: identityVerified,
    repositoryIdentityFailure: identityFailure,
  );

  test('verified command evidence and complete defect records are READY', () {
    final report = generateReleaseCandidateReport(
      evidence(
        openP2: 1,
        openP3: 1,
        p2: [
          DefectRecord(
            owner: 'qa-owner',
            approvedBy: 'release-owner',
            expiresAt: generatedAt.add(const Duration(days: 7)),
            verifiedWorkaround:
                'QA verified that reopening the records tab refreshes totals.',
            userOperationalRisk:
                'Users may briefly see stale totals; operations receives no bad data.',
          ),
        ],
        p3: const [DefectRecord(owner: 'ui-owner', milestone: '0.1.1')],
      ),
      now: generatedAt.add(const Duration(days: 1)),
    );

    expect(report.decision, ReleaseDecision.ready);
    expect(report.blockingReasons, isEmpty);
    expect(report.markdown, contains('Report — READY'));
    expect(report.markdown, contains('fiveMinuteProfile'));
    expect(report.markdown, contains('QA-verified workaround'));
    expect(report.markdown, contains('2026-07-17T12:00:00.000Z'));
  });

  test('arbitrary success cannot override nonzero command exit', () {
    final gates = {for (final name in requiredReleaseGates) name: gate()};
    gates['tests'] = gate(exitCode: 1);

    final report = generateReleaseCandidateReport(evidence(gates: gates));

    expect(report.decision, ReleaseDecision.blocked);
    expect(report.blockingReasons, contains('tests command exited 1'));
  });

  test('changed hash or mtime verification cannot produce false READY', () {
    final gates = {for (final name in requiredReleaseGates) name: gate()};
    gates['goldens'] = gate(verified: false, failure: 'artifact hash changed');

    final report = generateReleaseCandidateReport(evidence(gates: gates));

    expect(report.decision, ReleaseDecision.blocked);
    expect(
      report.blockingReasons,
      contains('goldens evidence is invalid: artifact hash changed'),
    );
  });

  test('wrong HEAD, branch, object, or version cannot produce false READY', () {
    final report = generateReleaseCandidateReport(
      evidence(
        identityVerified: false,
        identityFailure: 'HEAD does not match; version does not match',
      ),
    );

    expect(report.decision, ReleaseDecision.blocked);
    expect(report.blockingReasons.single, contains('HEAD does not match'));
  });

  test('missing actual five-minute profile evidence blocks release', () {
    final gates = {for (final name in requiredReleaseGates) name: gate()}
      ..remove('fiveMinuteProfile');

    final report = generateReleaseCandidateReport(evidence(gates: gates));

    expect(report.decision, ReleaseDecision.blocked);
    expect(
      report.blockingReasons,
      contains('fiveMinuteProfile evidence is missing'),
    );
  });

  test('P2 expiry and P3 ownership policy prevent false READY', () {
    final report = generateReleaseCandidateReport(
      evidence(
        openP2: 1,
        openP3: 1,
        p2: [
          DefectRecord(
            owner: 'qa',
            approvedBy: 'release',
            expiresAt: generatedAt,
          ),
        ],
        p3: const [DefectRecord(owner: '', milestone: '')],
      ),
    );

    expect(report.decision, ReleaseDecision.blocked);
    expect(
      report.blockingReasons,
      contains('P2 exception requires owner, approval, and future expiry'),
    );
    expect(
      report.blockingReasons,
      contains('every open P3 requires owner and milestone'),
    );
  });

  test('P2 without verified workaround and risk cannot produce READY', () {
    final report = generateReleaseCandidateReport(
      evidence(
        openP2: 1,
        p2: [
          DefectRecord(
            owner: 'qa-owner',
            approvedBy: 'release-owner',
            expiresAt: generatedAt.add(const Duration(days: 7)),
          ),
        ],
      ),
      now: generatedAt.add(const Duration(days: 1)),
    );

    expect(report.decision, ReleaseDecision.blocked);
    expect(
      report.blockingReasons,
      contains('P2 exception requires a concrete QA-verified workaround'),
    );
    expect(
      report.blockingReasons,
      contains(
        'P2 exception requires a concrete user/operational risk statement',
      ),
    );
  });

  test('P2 expiry after old evidence but before report time is blocked', () {
    final oldGeneratedAt = DateTime.utc(2020, 1, 1);
    final report = generateReleaseCandidateReport(
      evidence(
        generatedAtOverride: oldGeneratedAt,
        openP2: 1,
        p2: [
          DefectRecord(
            owner: 'qa-owner',
            approvedBy: 'release-owner',
            expiresAt: oldGeneratedAt.add(const Duration(days: 1)),
            verifiedWorkaround:
                'QA verified that reopening the records tab refreshes totals.',
            userOperationalRisk:
                'Users may briefly see stale totals; operations receives no bad data.',
          ),
        ],
      ),
      now: oldGeneratedAt.add(const Duration(days: 2)),
    );

    expect(report.decision, ReleaseDecision.blocked);
    expect(
      report.blockingReasons,
      contains(
        'P2 exception expiry must be after evidence generation and report time',
      ),
    );
  });

  test('placeholder workaround and risk are not concrete P2 evidence', () {
    final report = generateReleaseCandidateReport(
      evidence(
        openP2: 1,
        p2: [
          DefectRecord(
            owner: 'qa-owner',
            approvedBy: 'release-owner',
            expiresAt: generatedAt.add(const Duration(days: 7)),
            verifiedWorkaround: 'TBD',
            userOperationalRisk: 'low risk',
          ),
        ],
      ),
      now: generatedAt.add(const Duration(days: 1)),
    );

    expect(report.decision, ReleaseDecision.blocked);
    expect(
      report.blockingReasons,
      contains('P2 exception requires a concrete QA-verified workaround'),
    );
    expect(
      report.blockingReasons,
      contains(
        'P2 exception requires a concrete user/operational risk statement',
      ),
    );
  });
}
