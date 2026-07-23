import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'procedure creates one run directory and scopes every artifact to it',
    () {
      final procedure = File(
        'docs/testing/combat-visual-profile-procedure.md',
      ).readAsStringSync();

      expect(
        procedure,
        contains("\$runId = Get-Date -Format 'yyyy-MM-ddTHHmmss-seed3107'"),
      );
      expect(
        procedure,
        contains(
          "\$runDirectory = Join-Path 'build/qa/combat-visual-profile' \$runId",
        ),
      );
      expect(
        procedure,
        contains('New-Item -ItemType Directory -Force -Path \$runDirectory'),
      );
      expect(procedure, contains('Join-Path \$runDirectory'));
      expect(procedure, contains('--output \$runDirectory'));
      expect(procedure, contains('--input \$normalizedCapturePath'));
      for (final pathVariable in [
        r'$environmentPath',
        r'$warmRestartPath',
        r'$coldTracePath',
        r'$observationsPath',
        r'$normalizedCapturePath',
        r'$profileJsonPath',
        r'$profileMarkdownPath',
        r'$notMeasuredPath',
      ]) {
        expect(procedure, contains("$pathVariable = Join-Path \$runDirectory"));
      }
      expect(procedure, isNot(contains('build/qa/combat-visual-profile/')));
    },
  );
}
