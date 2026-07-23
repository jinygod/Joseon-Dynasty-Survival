import 'dart:collection';

/// Immutable Chrome profile-mode frame timing evidence.
///
/// All duration and timestamp values use milliseconds. Invalid durations
/// (negative, NaN, or infinite) are excluded, and their counts are retained so
/// exports cannot present them as valid timing samples. Percentiles use the
/// nearest-rank rule: rank `ceil(percentile * sampleCount)`, one-based.
class ChromeFrameProfile {
  ChromeFrameProfile._({
    required List<double> frameDurationsMs,
    required List<double> buildDurationsMs,
    required List<double> rasterDurationsMs,
    required this.invalidFrameDurationCount,
    required this.invalidBuildDurationCount,
    required this.invalidRasterDurationCount,
    required Map<String, double> firstImageLoadTimestampsMs,
    required Map<String, double> componentCreateRatesPerSecond,
    required Map<String, double> componentRemoveRatesPerSecond,
  }) : frameDurationsMs = List.unmodifiable(frameDurationsMs),
       buildDurationsMs = List.unmodifiable(buildDurationsMs),
       rasterDurationsMs = List.unmodifiable(rasterDurationsMs),
       firstImageLoadTimestampsMs = UnmodifiableMapView(
         Map.of(firstImageLoadTimestampsMs),
       ),
       componentCreateRatesPerSecond = UnmodifiableMapView(
         Map.of(componentCreateRatesPerSecond),
       ),
       componentRemoveRatesPerSecond = UnmodifiableMapView(
         Map.of(componentRemoveRatesPerSecond),
       );

  factory ChromeFrameProfile.fromMilliseconds({
    required Iterable<num> frameDurationsMs,
    Iterable<num> buildDurationsMs = const [],
    Iterable<num> rasterDurationsMs = const [],
    Map<String, num> firstImageLoadTimestampsMs = const {},
    Map<String, num> componentCreateRatesPerSecond = const {},
    Map<String, num> componentRemoveRatesPerSecond = const {},
  }) {
    final frames = _validDurations(frameDurationsMs);
    final builds = _validDurations(buildDurationsMs);
    final rasters = _validDurations(rasterDurationsMs);
    return ChromeFrameProfile._(
      frameDurationsMs: frames.values,
      buildDurationsMs: builds.values,
      rasterDurationsMs: rasters.values,
      invalidFrameDurationCount: frames.invalidCount,
      invalidBuildDurationCount: builds.invalidCount,
      invalidRasterDurationCount: rasters.invalidCount,
      firstImageLoadTimestampsMs: _validNamedValues(firstImageLoadTimestampsMs),
      componentCreateRatesPerSecond: _validNamedValues(
        componentCreateRatesPerSecond,
      ),
      componentRemoveRatesPerSecond: _validNamedValues(
        componentRemoveRatesPerSecond,
      ),
    );
  }

  final List<double> frameDurationsMs;
  final List<double> buildDurationsMs;
  final List<double> rasterDurationsMs;
  final int invalidFrameDurationCount;
  final int invalidBuildDurationCount;
  final int invalidRasterDurationCount;
  final Map<String, double> firstImageLoadTimestampsMs;
  final Map<String, double> componentCreateRatesPerSecond;
  final Map<String, double> componentRemoveRatesPerSecond;

  int get sampleCount => frameDurationsMs.length;
  int get buildSampleCount => buildDurationsMs.length;
  int get rasterSampleCount => rasterDurationsMs.length;
  int get framesOver33Ms =>
      frameDurationsMs.where((value) => value > 33).length;
  int get framesOver50Ms =>
      frameDurationsMs.where((value) => value > 50).length;

  double? get p50Ms => _nearestRank(frameDurationsMs, 0.50);
  double? get p95Ms => _nearestRank(frameDurationsMs, 0.95);
  double? get p99Ms => _nearestRank(frameDurationsMs, 0.99);
  double? get buildP50Ms => _nearestRank(buildDurationsMs, 0.50);
  double? get buildP95Ms => _nearestRank(buildDurationsMs, 0.95);
  double? get buildP99Ms => _nearestRank(buildDurationsMs, 0.99);
  double? get rasterP50Ms => _nearestRank(rasterDurationsMs, 0.50);
  double? get rasterP95Ms => _nearestRank(rasterDurationsMs, 0.95);
  double? get rasterP99Ms => _nearestRank(rasterDurationsMs, 0.99);

  Map<String, Object?> toJson() => {
    'durationUnit': 'milliseconds',
    'rateUnit': 'components-per-second',
    'frameDurationsMs': frameDurationsMs,
    'buildDurationsMs': buildDurationsMs,
    'rasterDurationsMs': rasterDurationsMs,
    'frameSampleCount': sampleCount,
    'buildSampleCount': buildSampleCount,
    'rasterSampleCount': rasterSampleCount,
    'frameP50Ms': p50Ms,
    'frameP95Ms': p95Ms,
    'frameP99Ms': p99Ms,
    'buildP50Ms': buildP50Ms,
    'buildP95Ms': buildP95Ms,
    'buildP99Ms': buildP99Ms,
    'rasterP50Ms': rasterP50Ms,
    'rasterP95Ms': rasterP95Ms,
    'rasterP99Ms': rasterP99Ms,
    'framesOver33Ms': framesOver33Ms,
    'framesOver50Ms': framesOver50Ms,
    'invalidFrameDurationCount': invalidFrameDurationCount,
    'invalidBuildDurationCount': invalidBuildDurationCount,
    'invalidRasterDurationCount': invalidRasterDurationCount,
    'firstImageLoadTimestampsMs': firstImageLoadTimestampsMs,
    'componentCreateRatesPerSecond': componentCreateRatesPerSecond,
    'componentRemoveRatesPerSecond': componentRemoveRatesPerSecond,
  };

  String toMarkdown() =>
      '''# Chrome Frame Profile

- Duration unit: milliseconds (ms)
- Rate unit: components per second
- Frame samples: $sampleCount; p50 / p95 / p99: ${_display(p50Ms)} / ${_display(p95Ms)} / ${_display(p99Ms)} ms
- Build samples: $buildSampleCount; p50 / p95 / p99: ${_display(buildP50Ms)} / ${_display(buildP95Ms)} / ${_display(buildP99Ms)} ms
- Raster samples: $rasterSampleCount; p50 / p95 / p99: ${_display(rasterP50Ms)} / ${_display(rasterP95Ms)} / ${_display(rasterP99Ms)} ms
- Frame durations strictly over 33 ms / 50 ms: $framesOver33Ms / $framesOver50Ms
- Excluded invalid durations (negative, NaN, or infinite): frame $invalidFrameDurationCount, build $invalidBuildDurationCount, raster $invalidRasterDurationCount

Percentiles use nearest-rank on each sorted series independently; `not measured` means that series has no valid samples.
''';
}

_DurationSeries _validDurations(Iterable<num> input) {
  final values = <double>[];
  var invalidCount = 0;
  for (final value in input) {
    final milliseconds = value.toDouble();
    if (!milliseconds.isFinite || milliseconds < 0) {
      invalidCount += 1;
    } else {
      values.add(milliseconds);
    }
  }
  values.sort();
  return _DurationSeries(values, invalidCount);
}

Map<String, double> _validNamedValues(Map<String, num> input) => {
  for (final entry in input.entries)
    if (entry.value.toDouble().isFinite && entry.value >= 0)
      entry.key: entry.value.toDouble(),
};

double? _nearestRank(List<double> sortedValues, double percentile) {
  if (sortedValues.isEmpty) return null;
  final rank = (percentile * sortedValues.length).ceil();
  return sortedValues[rank - 1];
}

String _display(double? value) => value?.toString() ?? 'not measured';

class _DurationSeries {
  const _DurationSeries(this.values, this.invalidCount);

  final List<double> values;
  final int invalidCount;
}
