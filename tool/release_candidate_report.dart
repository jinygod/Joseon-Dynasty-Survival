import 'dart:convert';
import 'dart:io';

enum ReleaseDecision { ready, blocked }

const requiredReleaseGates = <String>[
  'analyze',
  'tests',
  'webBuild',
  'fiveMinuteProfile',
  'goldens',
];

class GateEvidence {
  const GateEvidence({
    required this.command,
    required this.exitCode,
    required this.completedAt,
    required this.artifactPath,
    required this.artifactHash,
    required this.artifactModifiedAt,
    required this.verified,
    this.verificationFailure,
  });

  final String command;
  final int exitCode;
  final DateTime completedAt;
  final String artifactPath;
  final String artifactHash;
  final DateTime artifactModifiedAt;
  final bool verified;
  final String? verificationFailure;
}

class DefectRecord {
  const DefectRecord({
    required this.owner,
    this.approvedBy,
    this.expiresAt,
    this.milestone,
  });

  final String owner;
  final String? approvedBy;
  final DateTime? expiresAt;
  final String? milestone;
}

class ReleaseCandidateEvidence {
  const ReleaseCandidateEvidence({
    required this.branch,
    required this.commit,
    required this.version,
    required this.generatedAt,
    required this.gates,
    required this.openP0,
    required this.openP1,
    required this.openP2,
    required this.openP3,
    required this.p2Exceptions,
    required this.p3Records,
    required this.repositoryIdentityVerified,
    this.repositoryIdentityFailure,
  });

  final String branch;
  final String commit;
  final String version;
  final DateTime generatedAt;
  final Map<String, GateEvidence> gates;
  final int openP0;
  final int openP1;
  final int openP2;
  final int openP3;
  final List<DefectRecord> p2Exceptions;
  final List<DefectRecord> p3Records;
  final bool repositoryIdentityVerified;
  final String? repositoryIdentityFailure;
}

class ReleaseCandidateReport {
  const ReleaseCandidateReport({
    required this.evidence,
    required this.decision,
    required this.blockingReasons,
    required this.markdown,
  });

  final ReleaseCandidateEvidence evidence;
  final ReleaseDecision decision;
  final List<String> blockingReasons;
  final String markdown;
}

ReleaseCandidateReport generateReleaseCandidateReport(
  ReleaseCandidateEvidence evidence,
) {
  final reasons = <String>[];
  if (!evidence.repositoryIdentityVerified) {
    reasons.add(
      evidence.repositoryIdentityFailure ?? 'repository identity is invalid',
    );
  }
  for (final gate in requiredReleaseGates) {
    final value = evidence.gates[gate];
    if (value == null) {
      reasons.add('$gate evidence is missing');
    } else if (value.exitCode != 0) {
      reasons.add('$gate command exited ${value.exitCode}');
    } else if (!value.verified) {
      reasons.add(
        '$gate evidence is invalid: '
        '${value.verificationFailure ?? 'verification failed'}',
      );
    }
  }
  if (evidence.openP0 > 0) reasons.add('${evidence.openP0} open P0 defects');
  if (evidence.openP1 > 0) reasons.add('${evidence.openP1} open P1 defects');
  if (evidence.p2Exceptions.length != evidence.openP2) {
    reasons.add('every open P2 requires one exception record');
  }
  for (final record in evidence.p2Exceptions) {
    if (record.owner.trim().isEmpty ||
        (record.approvedBy?.trim().isEmpty ?? true) ||
        record.expiresAt == null ||
        !record.expiresAt!.isAfter(evidence.generatedAt)) {
      reasons.add('P2 exception requires owner, approval, and future expiry');
      break;
    }
  }
  if (evidence.p3Records.length != evidence.openP3 ||
      evidence.p3Records.any(
        (record) =>
            record.owner.trim().isEmpty ||
            (record.milestone?.trim().isEmpty ?? true),
      )) {
    reasons.add('every open P3 requires owner and milestone');
  }
  final decision = reasons.isEmpty
      ? ReleaseDecision.ready
      : ReleaseDecision.blocked;
  return ReleaseCandidateReport(
    evidence: evidence,
    decision: decision,
    blockingReasons: List.unmodifiable(reasons),
    markdown: _renderMarkdown(evidence, decision, reasons),
  );
}

Future<ReleaseCandidateEvidence> loadAndVerifyEvidence(
  String manifestPath, {
  DateTime? now,
}) async {
  final manifestFile = File(manifestPath);
  final json = jsonDecode(await manifestFile.readAsString()) as Map;
  final generatedAt = DateTime.parse(json['generatedAt'] as String).toUtc();
  final expectedBranch = json['branch'] as String;
  final expectedCommit = json['commit'] as String;
  final expectedVersion = json['version'] as String;
  final failures = <String>[];
  final currentBranch = await _git(['branch', '--show-current']);
  final currentHead = await _git(['rev-parse', 'HEAD']);
  final objectCheck = await Process.run('git', [
    'cat-file',
    '-e',
    '$expectedCommit^{commit}',
  ]);
  final pubspecVersion = RegExp(
    r'^version:\s*(\S+)\s*$',
    multiLine: true,
  ).firstMatch(await File('pubspec.yaml').readAsString())?.group(1);
  if (currentBranch != expectedBranch) failures.add('branch does not match');
  if (currentHead != expectedCommit) failures.add('HEAD does not match');
  if (objectCheck.exitCode != 0) failures.add('commit object does not exist');
  if (pubspecVersion != expectedVersion) failures.add('version does not match');
  final clock = (now ?? DateTime.now()).toUtc();
  if (generatedAt.isAfter(clock.add(const Duration(minutes: 1))) ||
      clock.difference(generatedAt) > const Duration(hours: 1)) {
    failures.add('manifest generated-at is stale or in the future');
  }

  final gates = <String, GateEvidence>{};
  for (final entry in (json['gates'] as Map).entries) {
    final raw = entry.value as Map;
    final path = raw['artifactPath'] as String;
    final file = File(path);
    var verified = true;
    String? failure;
    final completedAt = DateTime.parse(raw['completedAt'] as String).toUtc();
    final recordedMtime = DateTime.parse(
      raw['artifactModifiedAt'] as String,
    ).toUtc();
    if (!file.existsSync()) {
      verified = false;
      failure = 'artifact is missing';
    } else {
      final actualHash = await _git(['hash-object', path]);
      final actualMtime = file.lastModifiedSync().toUtc();
      if (actualHash != raw['artifactHash']) {
        verified = false;
        failure = 'artifact hash changed';
      } else if (actualMtime.difference(recordedMtime).abs() >
          const Duration(seconds: 2)) {
        verified = false;
        failure = 'artifact mtime changed';
      } else if (completedAt.isAfter(generatedAt) ||
          generatedAt.difference(completedAt) > const Duration(hours: 1)) {
        verified = false;
        failure = 'artifact evidence is stale';
      }
    }
    gates[entry.key as String] = GateEvidence(
      command: raw['command'] as String,
      exitCode: raw['exitCode'] as int,
      completedAt: completedAt,
      artifactPath: path,
      artifactHash: raw['artifactHash'] as String,
      artifactModifiedAt: recordedMtime,
      verified: verified,
      verificationFailure: failure,
    );
  }

  DefectRecord defect(Map value) => DefectRecord(
    owner: value['owner'] as String? ?? '',
    approvedBy: value['approvedBy'] as String?,
    expiresAt: value['expiresAt'] == null
        ? null
        : DateTime.parse(value['expiresAt'] as String).toUtc(),
    milestone: value['milestone'] as String?,
  );
  final defects = json['defects'] as Map;
  return ReleaseCandidateEvidence(
    branch: expectedBranch,
    commit: expectedCommit,
    version: expectedVersion,
    generatedAt: generatedAt,
    gates: gates,
    openP0: defects['openP0'] as int,
    openP1: defects['openP1'] as int,
    openP2: defects['openP2'] as int,
    openP3: defects['openP3'] as int,
    p2Exceptions: [
      for (final value in defects['p2Exceptions'] as List) defect(value as Map),
    ],
    p3Records: [
      for (final value in defects['p3Records'] as List) defect(value as Map),
    ],
    repositoryIdentityVerified: failures.isEmpty,
    repositoryIdentityFailure: failures.join('; '),
  );
}

Future<void> main(List<String> args) async {
  try {
    if (args.length != 4 || args[0] != '--evidence' || args[2] != '--output') {
      throw const FormatException(
        'Usage: --evidence <manifest.json> --output <report.md>',
      );
    }
    final evidence = await loadAndVerifyEvidence(args[1]);
    final report = generateReleaseCandidateReport(evidence);
    final output = File(args[3]);
    await output.parent.create(recursive: true);
    await output.writeAsString(report.markdown);
    stdout.writeln('${report.decision.name.toUpperCase()}: ${output.path}');
    if (report.decision == ReleaseDecision.blocked) exitCode = 2;
  } on Object catch (error) {
    stderr.writeln('Invalid release evidence: $error');
    exitCode = 64;
  }
}

Future<String> _git(List<String> arguments) async {
  final result = await Process.run('git', arguments);
  if (result.exitCode != 0) {
    throw StateError('git ${arguments.join(' ')} failed: ${result.stderr}');
  }
  return (result.stdout as String).trim();
}

String _renderMarkdown(
  ReleaseCandidateEvidence evidence,
  ReleaseDecision decision,
  List<String> reasons,
) {
  final gateRows = requiredReleaseGates
      .map((gate) {
        final value = evidence.gates[gate];
        final status = value == null
            ? 'MISSING'
            : value.exitCode == 0 && value.verified
            ? 'PASS'
            : 'FAIL';
        return '| $gate | $status | ${value?.command ?? '-'} | '
            '${value?.artifactPath ?? '-'} |';
      })
      .join('\n');
  final reasonLines = reasons.isEmpty
      ? '- None.'
      : reasons.map((reason) => '- $reason').join('\n');
  return '''# Release Candidate Report — ${decision.name.toUpperCase()}

- Generated: ${evidence.generatedAt.toIso8601String()}
- Branch: `${evidence.branch}`
- Commit: `${evidence.commit}`
- Version: `${evidence.version}`

## Required evidence

| Gate | Status | Command | Artifact |
| --- | --- | --- | --- |
$gateRows

## Open defects

| Severity | Count | Required record |
| --- | ---: | --- |
| P0 | ${evidence.openP0} | Must be zero |
| P1 | ${evidence.openP1} | Must be zero |
| P2 | ${evidence.openP2} | Owner, approval, future expiry |
| P3 | ${evidence.openP3} | Owner, milestone |

## Blocking reasons

$reasonLines
''';
}
