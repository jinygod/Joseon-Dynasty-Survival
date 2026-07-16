import 'dart:io';

void main() {
  final failures = <String>[];
  final gradle = _read('android/app/build.gradle.kts', failures);
  final gitignore = _read('.gitignore', failures);
  final buildScript = _read('tool/build_android_release.ps1', failures);
  final verifyScript = _read('tool/verify_android_release.ps1', failures);
  final guide = _read('docs/release/android-signing.md', failures);

  _requiresAll(
    gradle,
    [
      'key.properties',
      'ANDROID_KEYSTORE_PATH',
      'ANDROID_KEYSTORE_PASSWORD',
      'ANDROID_KEY_ALIAS',
      'ANDROID_KEY_PASSWORD',
      'GradleException',
      'Release signing configuration is incomplete',
    ],
    'Gradle release signing contract',
    failures,
  );
  _forbids(
    gradle,
    ['signingConfigs.getByName("debug")'],
    'release must not use debug signing',
    failures,
  );
  _requiresAll(
    gitignore,
    [
      '/android/key.properties',
      '/android/build/',
      '/android/.kotlin/',
      '*.jks',
      '*.keystore',
      '/dist/android/',
    ],
    'signing and release outputs must be ignored',
    failures,
  );
  _requiresAll(
    buildScript,
    [
      'build',
      'appbundle',
      '--release',
      '--obfuscate',
      '--split-debug-info',
      'Get-FileHash',
      'SHA256SUMS.txt',
      'Copy-Item',
      'verify_android_release.ps1',
    ],
    'release build script',
    failures,
  );
  _requiresAll(
    verifyScript,
    ['jarsigner', '-verify', '-strict', 'Get-FileHash', 'SHA256'],
    'release verification script',
    failures,
  );
  _requiresAll(
    guide,
    [
      'key.properties',
      'ANDROID_KEYSTORE_PATH',
      'build_android_release.ps1',
      'verify_android_release.ps1',
      'SHA256SUMS.txt',
      'split-debug-info',
      '백업',
      '복구',
    ],
    'Android signing guide',
    failures,
  );

  if (failures.isNotEmpty) {
    stderr.writeln('Android release contract failed:');
    for (final failure in failures) {
      stderr.writeln('- $failure');
    }
    exitCode = 1;
    return;
  }
  stdout.writeln('Android release contract passed.');
}

String _read(String path, List<String> failures) {
  final file = File(path);
  if (!file.existsSync()) {
    failures.add('Missing file: $path');
    return '';
  }
  return file.readAsStringSync();
}

void _requiresAll(
  String source,
  List<String> needles,
  String label,
  List<String> failures,
) {
  for (final needle in needles) {
    if (!source.contains(needle)) {
      failures.add('$label is missing "$needle"');
    }
  }
}

void _forbids(
  String source,
  List<String> needles,
  String label,
  List<String> failures,
) {
  for (final needle in needles) {
    if (source.contains(needle)) {
      failures.add('$label contains forbidden "$needle"');
    }
  }
}
