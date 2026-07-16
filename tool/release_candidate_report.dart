import 'dart:io';

enum ReleaseDecision { ready, blocked }

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
  });

  final String branch;
  final String commit;
  final String version;
  final DateTime generatedAt;
  final Map<String, String> gates;
  final int openP0;
  final int openP1;
  final int openP2;
  final int openP3;
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

class ReleaseCandidateCommand {
  const ReleaseCandidateCommand({
    required this.evidence,
    required this.outputPath,
  });

  final ReleaseCandidateEvidence evidence;
  final String outputPath;
}

const _requiredGates = <String>[
  'analyze',
  'tests',
  'webBuild',
  'performance',
  'goldens',
];

ReleaseCandidateReport generateReleaseCandidateReport(
  ReleaseCandidateEvidence evidence,
) {
  final reasons = <String>[];
  for (final gate in _requiredGates) {
    final value = evidence.gates[gate];
    if (value == null || value.trim().isEmpty) {
      reasons.add('$gate evidence is missing');
    } else if (value.toUpperCase().startsWith('FAIL:')) {
      reasons.add('$gate evidence failed');
    } else if (!value.toUpperCase().startsWith('PASS:')) {
      reasons.add('$gate evidence is malformed');
    }
  }
  if (evidence.openP0 > 0) {
    reasons.add('${evidence.openP0} open P0 defects');
  }
  if (evidence.openP1 > 0) {
    reasons.add('${evidence.openP1} open P1 defects');
  }
  if (evidence.openP2 > 0) {
    reasons.add('${evidence.openP2} open P2 defects require exception records');
  }
  final decision = reasons.isEmpty
      ? ReleaseDecision.ready
      : ReleaseDecision.blocked;
  final markdown = _renderMarkdown(evidence, decision, reasons);
  return ReleaseCandidateReport(
    evidence: evidence,
    decision: decision,
    blockingReasons: List.unmodifiable(reasons),
    markdown: markdown,
  );
}

ReleaseCandidateCommand parseReleaseCandidateArguments(List<String> args) {
  final values = <String, String>{};
  for (var index = 0; index < args.length; index += 2) {
    if (index + 1 >= args.length || !args[index].startsWith('--')) {
      throw const FormatException('Arguments must be --name value pairs.');
    }
    values[args[index].substring(2)] = args[index + 1];
  }
  String required(String name) {
    final value = values[name]?.trim();
    if (value == null || value.isEmpty) {
      throw FormatException('Missing --$name.');
    }
    return value;
  }

  final commit = required('commit');
  if (!RegExp(r'^[0-9a-fA-F]{7,40}$').hasMatch(commit)) {
    throw const FormatException('--commit must be a 7-40 digit Git SHA.');
  }
  final version = required('version');
  if (!RegExp(r'^\d+\.\d+\.\d+\+\d+$').hasMatch(version)) {
    throw const FormatException('--version must use name+build form.');
  }
  DateTime generatedAt;
  try {
    generatedAt = DateTime.parse(required('generated-at')).toUtc();
  } on FormatException {
    throw const FormatException('--generated-at must be ISO-8601.');
  }
  int count(String name) {
    final parsed = int.tryParse(required(name));
    if (parsed == null || parsed < 0) {
      throw FormatException('--$name must be a non-negative integer.');
    }
    return parsed;
  }

  String gate(String name) {
    final value = required(name);
    if (!RegExp(r'^(PASS|FAIL):\s*.+$', caseSensitive: false).hasMatch(value)) {
      throw FormatException('--$name must begin with PASS: or FAIL:.');
    }
    return value;
  }

  return ReleaseCandidateCommand(
    evidence: ReleaseCandidateEvidence(
      branch: required('branch'),
      commit: commit,
      version: version,
      generatedAt: generatedAt,
      gates: {
        'analyze': gate('analyze'),
        'tests': gate('tests'),
        'webBuild': gate('web-build'),
        'performance': gate('performance'),
        'goldens': gate('goldens'),
      },
      openP0: count('open-p0'),
      openP1: count('open-p1'),
      openP2: count('open-p2'),
      openP3: count('open-p3'),
    ),
    outputPath: required('output'),
  );
}

Future<void> main(List<String> args) async {
  try {
    final command = parseReleaseCandidateArguments(args);
    final report = generateReleaseCandidateReport(command.evidence);
    final output = File(command.outputPath);
    await output.parent.create(recursive: true);
    await output.writeAsString(report.markdown);
    stdout.writeln('${report.decision.name.toUpperCase()}: ${output.path}');
    if (report.decision == ReleaseDecision.blocked) exitCode = 2;
  } on FormatException catch (error) {
    stderr.writeln('Invalid release evidence: ${error.message}');
    exitCode = 64;
  }
}

String _renderMarkdown(
  ReleaseCandidateEvidence evidence,
  ReleaseDecision decision,
  List<String> reasons,
) {
  final title = decision.name.toUpperCase();
  final gateRows = _requiredGates
      .map((gate) => '| $gate | ${evidence.gates[gate] ?? 'MISSING'} |')
      .join('\n');
  final reasonLines = reasons.isEmpty
      ? '- None.'
      : reasons.map((reason) => '- $reason').join('\n');
  return '''# Release Candidate Report — $title

- Generated: ${evidence.generatedAt.toUtc().toIso8601String()}
- Branch: `${evidence.branch}`
- Commit: `${evidence.commit}`
- Version: `${evidence.version}`

## Required evidence

| Gate | Evidence |
| --- | --- |
$gateRows

## Open defects

| Severity | Count |
| --- | ---: |
| P0 | ${evidence.openP0} |
| P1 | ${evidence.openP1} |
| P2 | ${evidence.openP2} |
| P3 | ${evidence.openP3} |

## Blocking reasons

$reasonLines
''';
}
