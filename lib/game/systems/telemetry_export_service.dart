import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/run_telemetry.dart';
import 'telemetry_repository.dart';

typedef TelemetryLoader = Future<List<RunTelemetry>> Function();
typedef ClipboardWriter = Future<void> Function(String value);
typedef JsonFileSharer =
    Future<void> Function(String fileName, String mimeType, List<int> bytes);

class TelemetryExportService {
  TelemetryExportService({
    TelemetryLoader? load,
    ClipboardWriter? writeClipboard,
    JsonFileSharer? shareJsonFile,
  }) : _load = load ?? TelemetryRepository().load,
       _writeClipboard = writeClipboard ?? _defaultClipboardWriter,
       _shareJsonFile = shareJsonFile ?? _defaultJsonFileSharer;

  static const _encoder = JsonEncoder.withIndent('  ');

  final TelemetryLoader _load;
  final ClipboardWriter _writeClipboard;
  final JsonFileSharer _shareJsonFile;

  Future<bool> copyRun(String runId) async {
    final history = await _load();
    RunTelemetry? selected;
    for (final run in history) {
      if (run.runId == runId) {
        selected = run;
        break;
      }
    }
    if (selected == null) return false;

    await _writeClipboard(_encoder.convert(selected.toJson()));
    return true;
  }

  Future<bool> exportAll() async {
    final history = await _load();
    if (history.isEmpty) return false;

    final json = _encoder.convert(history.map((run) => run.toJson()).toList());
    await _shareJsonFile(
      'run-telemetry.json',
      'application/json',
      utf8.encode(json),
    );
    return true;
  }

  static Future<void> _defaultClipboardWriter(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
  }

  static Future<void> _defaultJsonFileSharer(
    String fileName,
    String mimeType,
    List<int> bytes,
  ) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(Uint8List.fromList(bytes), mimeType: mimeType)],
        fileNameOverrides: [fileName],
      ),
    );
  }
}
