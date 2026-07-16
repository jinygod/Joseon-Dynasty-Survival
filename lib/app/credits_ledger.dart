import 'package:flutter/services.dart';

typedef CreditsLedgerLoader = Future<CreditsLedger> Function();

class CreditEntry {
  const CreditEntry({
    required this.runtimePath,
    required this.creator,
    required this.sourceUrl,
    required this.license,
    required this.status,
  });

  final String runtimePath;
  final String creator;
  final String sourceUrl;
  final String license;
  final String status;
}

class CreditsLedger {
  const CreditsLedger({required this.assets, required this.audio});

  final List<CreditEntry> assets;
  final List<CreditEntry> audio;

  static Future<CreditsLedger> loadBundled() => fromAssetBundle(rootBundle);

  static Future<CreditsLedger> fromAssetBundle(AssetBundle bundle) async {
    final csv = await Future.wait([
      bundle.loadString('docs/assets/asset-rights-ledger.csv'),
      bundle.loadString('docs/assets/audio-rights-ledger.csv'),
    ]);
    return CreditsLedger.fromCsv(assetCsv: csv[0], audioCsv: csv[1]);
  }

  factory CreditsLedger.fromCsv({
    required String assetCsv,
    required String audioCsv,
  }) => CreditsLedger(
    assets: _parse(
      assetCsv,
      path: 'runtime_path',
      creator: 'creator_or_vendor',
      source: 'source_url',
      license: 'terms_or_license_name',
      status: 'status',
    ),
    audio: _parse(
      audioCsv,
      path: 'local_path',
      creator: 'creator',
      source: 'source_url',
      license: 'license',
      status: 'status',
    ),
  );

  static List<CreditEntry> _parse(
    String csv, {
    required String path,
    required String creator,
    required String source,
    required String license,
    required String status,
  }) {
    final lines = csv
        .split(RegExp(r'\r?\n'))
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.length < 2) return const [];
    final headers = _fields(lines.first);
    final indexes = [
      path,
      creator,
      source,
      license,
      status,
    ].map(headers.indexOf).toList();
    if (indexes.any((index) => index < 0)) return const [];
    final result = <CreditEntry>[];
    for (final line in lines.skip(1)) {
      final fields = _fields(line);
      if (indexes.any((index) => index >= fields.length)) continue;
      result.add(
        CreditEntry(
          runtimePath: fields[indexes[0]],
          creator: fields[indexes[1]],
          sourceUrl: fields[indexes[2]],
          license: fields[indexes[3]],
          status: fields[indexes[4]],
        ),
      );
    }
    return List.unmodifiable(result);
  }

  static List<String> _fields(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    var quoted = false;
    for (var index = 0; index < line.length; index += 1) {
      final char = line[index];
      if (char == '"') {
        if (quoted && index + 1 < line.length && line[index + 1] == '"') {
          buffer.write('"');
          index += 1;
        } else {
          quoted = !quoted;
        }
      } else if (char == ',' && !quoted) {
        result.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    result.add(buffer.toString().trim());
    return result;
  }
}
