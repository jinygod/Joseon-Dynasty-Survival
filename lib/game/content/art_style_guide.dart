class JoseonArtStyle {
  const JoseonArtStyle._();

  static const characterHeadRatioMin = 3;
  static const characterHeadRatioMax = 4;
  static const cellShadeStepsMin = 2;
  static const cellShadeStepsMax = 3;
  static const outlineStyle = 'bold_clean';
  static const allowsBulkFinalArt = false;
  static const temporaryActorVisualSizes = <String, double>{
    'player': 108,
    'normalEnemy': 54,
    'eliteEnemy': 81,
    'boss': 126,
  };

  static const characterDesignCues = <String, String>{
    'hwandoSwordsman':
        'Joseon durumagi and jeonbok layers, gat silhouette, hwando at hip',
    'mudang':
        'striped ceremonial sleeves, ritual ribbons, bells and paper talismans',
    'musketeer':
        'Joseon military coat and headcloth with a long matchlock musket',
    'dokkaebiHunter':
        'straw rain cape, rope charms, horn trophies and a practical club',
  };

  static const monsterSilhouetteCues = <String, String>{
    'littleDokkaebi': 'small horned head, broad grin and oversized club',
    'jarGhost': 'round earthenware jar body with a leaking spirit plume',
    'jangseungGhost': 'tall carved village-pole face and splintered arms',
    'sakkatSpecter': 'wide conical hat above a narrow floating robe',
    'fireDokkaebi': 'forked flame crown, compact torso and ember fists',
    'eggGhost': 'smooth egg-shaped body with tiny feet and a cracked face',
    'underworldMinion': 'ledger tag, hooked staff and hunched official robe',
    'tigerDemon': 'low feline shoulders, striped tail and exaggerated claws',
    'plagueGhost': 'swollen sleeves, bent posture and trailing sickly vapor',
    'fallenOfficer': 'broken Joseon command hat, lamellar coat and long blade',
  };

  static const forbiddenDesignCues = <String>[
    'japanese_samurai_armor',
    'chinese_wuxia_robes',
    'copied_commercial_game_assets',
  ];

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

  static bool hasApprovedSizeSuffix(String path) => RegExp(
    r'_(16|24|32|64|128|512|1024|1024x1824|1536x2730)\.png$',
  ).hasMatch(path);
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
