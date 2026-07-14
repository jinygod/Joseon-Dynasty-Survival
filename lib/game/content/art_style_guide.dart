class JoseonArtStyle {
  const JoseonArtStyle._();

  static const pickupSize = 16;
  static const swarmSize = 24;
  static const standardSize = 32;
  static const bossSize = 64;
  static const integerScales = <int>[1, 2, 3, 4];
  static const outlinePixels = 1;
  static const bossOutlinePixels = 2;
  static const lightDirection = 'upper_left';

  static const palette = <String, int>{
    'inkNight': 0xff101820,
    'moonSlate': 0xff263849,
    'moonMist': 0xff9fb3c8,
    'hanji': 0xfff4ead2,
    'sealRed': 0xffd1495b,
    'deepSeal': 0xff8f2d38,
    'brass': 0xfff2cc8f,
    'jade': 0xff3fbf7f,
    'spiritCyan': 0xff7bdff2,
    'ember': 0xfff08a5d,
    'danger': 0xffe63946,
  };

  static const silhouettes = <String, SilhouetteRule>{
    'player': SilhouetteRule(
      occupancyMin: 0.55,
      occupancyMax: 0.78,
      readabilityCue: 'upright stance, hat or ritual-tool top break',
    ),
    'swarm': SilhouetteRule(
      occupancyMin: 0.45,
      occupancyMax: 0.68,
      readabilityCue: 'wide low cluster with at least three head bumps',
    ),
    'chaser': SilhouetteRule(
      occupancyMin: 0.55,
      occupancyMax: 0.78,
      readabilityCue: 'forward lean with one asymmetric weapon edge',
    ),
    'tank': SilhouetteRule(
      occupancyMin: 0.68,
      occupancyMax: 0.88,
      readabilityCue: 'wide shoulders and square lower mass',
    ),
    'spirit': SilhouetteRule(
      occupancyMin: 0.50,
      occupancyMax: 0.74,
      readabilityCue: 'narrow upper body with broken floating lower edge',
    ),
    'boss': SilhouetteRule(
      occupancyMin: 0.70,
      occupancyMax: 0.90,
      readabilityCue: 'double-height armor mass and unique command weapon',
    ),
  };

  static bool hasApprovedSizeSuffix(String path) =>
      RegExp(r'_(16|24|32|64)\.png$').hasMatch(path);
}

class SilhouetteRule {
  const SilhouetteRule({
    required this.occupancyMin,
    required this.occupancyMax,
    required this.readabilityCue,
  });

  final double occupancyMin;
  final double occupancyMax;
  final String readabilityCue;
}
