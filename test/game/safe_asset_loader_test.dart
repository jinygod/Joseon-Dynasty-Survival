import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/safe_asset_loader.dart';

void main() {
  test('safe loader returns a successfully loaded value', () async {
    final value = await SafeAssetLoader.load<int>(
      load: () async => 7,
      library: 'test assets',
      assetKey: 'images/test.png',
    );

    expect(value, 7);
  });

  test('safe loader returns null silently in release-like mode', () async {
    final details = <FlutterErrorDetails>[];
    final value = await SafeAssetLoader.load<int>(
      load: () async => throw StateError('missing'),
      library: 'test assets',
      assetKey: 'images/missing.png',
      reportErrors: false,
      reportError: details.add,
    );

    expect(value, isNull);
    expect(details, isEmpty);
  });

  test('safe loader reports one explicit development diagnostic', () async {
    final details = <FlutterErrorDetails>[];
    final value = await SafeAssetLoader.load<int>(
      load: () async => throw StateError('broken'),
      library: 'test assets',
      assetKey: 'images/broken.png',
      reportErrors: true,
      reportError: details.add,
    );

    expect(value, isNull);
    expect(details, hasLength(1));
    expect(details.single.library, 'test assets');
    expect(details.single.context.toString(), contains('images/broken.png'));
  });
}
