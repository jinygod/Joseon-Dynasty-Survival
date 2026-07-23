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
      await writeNotMeasuredEvidence(
        outputDirectory: output,
        reason: 'same mode may overwrite its own evidence',
      );

      final evidence =
          jsonDecode(
                File(
                  '${output.path}/chrome-frame-profile-not-measured.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      expect(evidence['status'], 'not measured');
      expect(evidence['reason'], 'same mode may overwrite its own evidence');
      expect(
        File('${output.path}/chrome-frame-profile.json').existsSync(),
        isFalse,
      );
    },
  );

  test('fails closed without writes when evidence modes conflict', () async {
    final directory = await Directory.systemTemp.createTemp('chrome-profile-');
    addTearDown(() => directory.delete(recursive: true));
    final output = Directory('${directory.path}/out')..createSync();
    final measured = File('${output.path}/chrome-frame-profile.json')
      ..writeAsStringSync('existing measured evidence');

    await expectLater(
      () =>
          writeNotMeasuredEvidence(outputDirectory: output, reason: 'blocked'),
      throwsStateError,
    );
    expect(
      await runProfileReporter([
        '--not-measured',
        'blocked',
        '--output',
        output.path,
      ], reportError: (_) {}),
      1,
    );

    expect(measured.readAsStringSync(), 'existing measured evidence');
    expect(
      File(
        '${output.path}/chrome-frame-profile-not-measured.json',
      ).existsSync(),
      isFalse,
    );

    final input = File('${directory.path}/capture.json')
      ..writeAsStringSync(jsonEncode(_validCapture));
    final notMeasured = File(
      '${output.path}/chrome-frame-profile-not-measured.json',
    )..writeAsStringSync('existing not measured evidence');
    measured.deleteSync();

    await expectLater(
      () => writeProfileArtifacts(input: input, outputDirectory: output),
      throwsStateError,
    );
    expect(notMeasured.readAsStringSync(), 'existing not measured evidence');
    expect(
      File('${output.path}/chrome-frame-profile.json').existsSync(),
      isFalse,
    );
  });

  test('rejects invalid captures before creating partial output', () async {
    final directory = await Directory.systemTemp.createTemp('chrome-profile-');
    addTearDown(() => directory.delete(recursive: true));
    final input = File('${directory.path}/capture.json')
      ..writeAsStringSync(
        jsonEncode({
          'frameMs': [8, -1],
          'buildMs': 'not a list',
          'rasterMs': [],
          'imageLoadTimestampsMs': {},
          'componentCreateRates': {},
          'componentRemoveRates': {},
        }),
      );
    final output = Directory('${directory.path}/out');

    await expectLater(
      () => writeProfileArtifacts(input: input, outputDirectory: output),
      throwsFormatException,
    );

    expect(output.existsSync(), isFalse);
  });

  test('returns nonzero for invalid CLI arguments and reasons', () async {
    final directory = await Directory.systemTemp.createTemp('chrome-profile-');
    addTearDown(() => directory.delete(recursive: true));

    expect(await runProfileReporter(['--unknown'], reportError: (_) {}), 64);
    expect(
      await runProfileReporter([
        '--input',
        'capture.json',
      ], reportError: (_) {}),
      64,
    );
    expect(
      await runProfileReporter([
        '--input',
        'capture.json',
        '--not-measured',
        'blocked',
        '--output',
        '${directory.path}/out',
      ], reportError: (_) {}),
      64,
    );
    expect(
      await runProfileReporter([
        '--not-measured',
        '   ',
        '--output',
        '${directory.path}/out',
      ], reportError: (_) {}),
      64,
    );
    expect(Directory('${directory.path}/out').existsSync(), isFalse);
  });

  test('rejects missing and malformed capture fields without output', () async {
    final directory = await Directory.systemTemp.createTemp('chrome-profile-');
    addTearDown(() => directory.delete(recursive: true));
    final invalidCaptures = <Map<String, Object>>[
      {
        'frameMs': <num>[],
        'buildMs': <num>[],
        'rasterMs': <num>[],
        'imageLoadTimestampsMs': <String, num>{},
        'componentCreateRates': <String, num>{},
      },
      {
        ..._validCapture,
        'frameMs': ['not-a-number'],
      },
      {
        ..._validCapture,
        'componentCreateRates': {'enemy': 'not-a-number'},
      },
      {..._validCapture, 'componentCreateRates': <Object>[]},
    ];

    for (var index = 0; index < invalidCaptures.length; index += 1) {
      final input = File('${directory.path}/capture-$index.json')
        ..writeAsStringSync(jsonEncode(invalidCaptures[index]));
      final output = Directory('${directory.path}/out-$index');
      await expectLater(
        () => writeProfileArtifacts(input: input, outputDirectory: output),
        throwsFormatException,
      );
      expect(output.existsSync(), isFalse);
    }
  });
}

const _validCapture = <String, Object>{
  'frameMs': <num>[8, 16],
  'buildMs': <num>[1],
  'rasterMs': <num>[2],
  'imageLoadTimestampsMs': <String, num>{},
  'componentCreateRates': <String, num>{},
  'componentRemoveRates': <String, num>{},
};
