import 'dart:convert';
import 'dart:io';

import 'package:pixel_survivor/game/performance/chrome_frame_profile.dart';

const _jsonEncoder = JsonEncoder.withIndent('  ');

/// Converts a deliberately normalized capture into checked profile artifacts.
///
/// This tool does not parse Chrome trace events. The trace-to-capture mapping
/// is intentionally an operator-owned step because event names and availability
/// differ by Flutter/web renderer version. Its input schema is:
///
/// ```json
/// {
///   "frameMs": [number], "buildMs": [number], "rasterMs": [number],
///   "imageLoadTimestampsMs": {"name": number},
///   "componentCreateRates": {"name": number},
///   "componentRemoveRates": {"name": number}
/// }
/// ```
Future<void> writeProfileArtifacts({
  required File input,
  required Directory outputDirectory,
}) async {
  final capture = _readCapture(input);
  final profile = ChromeFrameProfile.fromMilliseconds(
    frameDurationsMs: _numberList(_required(capture, 'frameMs'), 'frameMs'),
    buildDurationsMs: _numberList(_required(capture, 'buildMs'), 'buildMs'),
    rasterDurationsMs: _numberList(_required(capture, 'rasterMs'), 'rasterMs'),
    firstImageLoadTimestampsMs: _numberMap(
      _required(capture, 'imageLoadTimestampsMs'),
      'imageLoadTimestampsMs',
    ),
    componentCreateRatesPerSecond: _numberMap(
      _required(capture, 'componentCreateRates'),
      'componentCreateRates',
    ),
    componentRemoveRatesPerSecond: _numberMap(
      _required(capture, 'componentRemoveRates'),
      'componentRemoveRates',
    ),
  );
  await outputDirectory.create(recursive: true);
  await File(
    '${outputDirectory.path}/chrome-frame-profile.json',
  ).writeAsString('${_jsonEncoder.convert(profile.toJson())}\n');
  await File(
    '${outputDirectory.path}/chrome-frame-profile.md',
  ).writeAsString(profile.toMarkdown());
}

Future<void> writeNotMeasuredEvidence({
  required Directory outputDirectory,
  required String reason,
}) async {
  if (reason.trim().isEmpty) {
    throw ArgumentError.value(reason, 'reason', 'must not be empty');
  }
  await outputDirectory.create(recursive: true);
  await File(
    '${outputDirectory.path}/chrome-frame-profile.not-measured.json',
  ).writeAsString(
    '${_jsonEncoder.convert({'status': 'not measured', 'reason': reason, 'scope': 'Chrome profile-mode combat evidence only', 'mobileOrDeviceClaim': false})}\n',
  );
}

Future<void> main(List<String> args) async {
  if (args.length == 4 && args[0] == '--input' && args[2] == '--output') {
    await writeProfileArtifacts(
      input: File(args[1]),
      outputDirectory: Directory(args[3]),
    );
    return;
  }
  if (args.length == 4 &&
      args[0] == '--not-measured' &&
      args[2] == '--output') {
    await writeNotMeasuredEvidence(
      reason: args[1],
      outputDirectory: Directory(args[3]),
    );
    return;
  }
  throw ArgumentError(
    'Usage: dart run tool/combat_visual_profile_report.dart '
    '--input <normalized-capture.json> --output <directory>\n'
    '   or: dart run tool/combat_visual_profile_report.dart '
    '--not-measured <reason> --output <directory>',
  );
}

Map _readCapture(File input) {
  final decoded = jsonDecode(input.readAsStringSync());
  if (decoded is! Map) throw const FormatException('Expected a JSON object.');
  return decoded;
}

Object? _required(Map capture, String key) {
  if (!capture.containsKey(key)) {
    throw FormatException('Missing required capture field: $key');
  }
  return capture[key];
}

List<num> _numberList(Object? value, String name) {
  if (value is! List || value.any((entry) => entry is! num)) {
    throw FormatException('$name must be a JSON number array.');
  }
  return value.cast<num>();
}

Map<String, num> _numberMap(Object? value, String name) {
  if (value is! Map ||
      value.entries.any(
        (entry) => entry.key is! String || entry.value is! num,
      )) {
    throw FormatException(
      '$name must be a JSON object of string keys and numbers.',
    );
  }
  return Map<String, num>.from(value);
}
