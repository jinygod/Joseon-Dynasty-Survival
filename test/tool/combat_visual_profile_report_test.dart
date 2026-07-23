import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import '../../tool/combat_visual_profile_report.dart';

void main() {
  test(
    'writes Chrome profile JSON and Markdown from normalized capture',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'chrome-profile-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final input = File('${directory.path}/capture.json')
        ..writeAsStringSync(
          jsonEncode({
            'frameMs': [8, 16, 34, 51],
            'buildMs': [1, 3],
            'rasterMs': [2, 4],
            'imageLoadTimestampsMs': {'player': 9},
            'componentCreateRates': {'enemy': 3},
            'componentRemoveRates': {'enemy': 1},
          }),
        );
      final output = Directory('${directory.path}/out');

      await writeProfileArtifacts(input: input, outputDirectory: output);

      final profileJson =
          jsonDecode(
                File(
                  '${output.path}/chrome-frame-profile.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      expect(profileJson['frameP50Ms'], 16.0);
      expect(profileJson['framesOver33Ms'], 2);
      expect(profileJson['firstImageLoadTimestampsMs']['player'], 9.0);
      expect(
        File('${output.path}/chrome-frame-profile.md').readAsStringSync(),
        contains('Duration unit: milliseconds'),
      );
    },
  );

  test(
    'writes explicit not-measured evidence without inventing profile data',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'chrome-profile-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final output = Directory('${directory.path}/out');

      await writeNotMeasuredEvidence(
        outputDirectory: output,
        reason: 'seed injection unavailable',
      );

      final evidence =
          jsonDecode(
                File(
                  '${output.path}/chrome-frame-profile.not-measured.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      expect(evidence['status'], 'not measured');
      expect(evidence['reason'], 'seed injection unavailable');
      expect(
        File('${output.path}/chrome-frame-profile.json').existsSync(),
        isFalse,
      );
    },
  );
}
