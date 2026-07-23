import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/performance/chrome_frame_profile.dart';

void main() {
  test(
    'uses nearest-rank percentiles without combining frame build or raster',
    () {
      final profile = ChromeFrameProfile.fromMilliseconds(
        frameDurationsMs: [51, 8, 34, 16, 17],
        buildDurationsMs: [7, 1, 4, 3],
        rasterDurationsMs: [12, 2, 9, 6],
      );

      expect(profile.sampleCount, 5);
      expect(profile.p50Ms, 17);
      expect(profile.p95Ms, 51);
      expect(profile.p99Ms, 51);
      expect(profile.framesOver33Ms, 2);
      expect(profile.framesOver50Ms, 1);
      expect(profile.buildP50Ms, 3);
      expect(profile.buildP95Ms, 7);
      expect(profile.rasterP50Ms, 6);
      expect(profile.rasterP95Ms, 12);
    },
  );

  test('uses nearest-rank edge cases with unsorted duplicate durations', () {
    final profile = ChromeFrameProfile.fromMilliseconds(
      frameDurationsMs: [4, 1, 1, 2],
    );

    expect(profile.p50Ms, 1);
    expect(profile.p95Ms, 4);
    expect(profile.p99Ms, 4);
  });

  test('keeps copied duration inputs and optional maps immutable', () {
    final frames = <num>[8, 16];
    final imageLoads = <String, num>{'player': 12};
    final creates = <String, num>{'enemy': 5};
    final removes = <String, num>{'enemy': 3};
    final profile = ChromeFrameProfile.fromMilliseconds(
      frameDurationsMs: frames,
      firstImageLoadTimestampsMs: imageLoads,
      componentCreateRatesPerSecond: creates,
      componentRemoveRatesPerSecond: removes,
    );

    frames.add(99);
    imageLoads['player'] = 99;
    creates['enemy'] = 99;
    removes['enemy'] = 99;

    expect(profile.frameDurationsMs, [8.0, 16.0]);
    expect(profile.firstImageLoadTimestampsMs, {'player': 12.0});
    expect(profile.componentCreateRatesPerSecond, {'enemy': 5.0});
    expect(profile.componentRemoveRatesPerSecond, {'enemy': 3.0});
    expect(() => profile.frameDurationsMs.add(4), throwsUnsupportedError);
    expect(
      () => profile.firstImageLoadTimestampsMs['effect'] = 4,
      throwsUnsupportedError,
    );
  });

  test(
    'excludes negative and non-finite durations and leaves empty series null',
    () {
      final profile = ChromeFrameProfile.fromMilliseconds(
        frameDurationsMs: [double.nan, -1, double.infinity],
        buildDurationsMs: [],
        rasterDurationsMs: [-2],
      );

      expect(profile.sampleCount, 0);
      expect(profile.invalidFrameDurationCount, 3);
      expect(profile.p50Ms, isNull);
      expect(profile.buildP50Ms, isNull);
      expect(profile.rasterP50Ms, isNull);
      expect(profile.toJson()['durationUnit'], 'milliseconds');
      expect(profile.toMarkdown(), contains('Excluded invalid durations'));
    },
  );
}
