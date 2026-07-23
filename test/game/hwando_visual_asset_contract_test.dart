import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/sprite_atlas_contract.dart';

const hwandoVisualAtlasIds = <String>[
  'hwando_slash_trail_128',
  'hwando_slash_impact_128',
  'hwando_blade_wave_trail_128',
  'hwando_blade_wave_impact_128',
  'hwando_master_circle_trail_128',
  'hwando_master_circle_impact_128',
  'hwando_master_finisher_trail_128',
  'hwando_master_finisher_impact_128',
];

void main() {
  test('all Hwando runtime sheets satisfy their PNG contracts', () {
    for (final id in hwandoVisualAtlasIds) {
      final contract = ReplaceableArtCatalog.byId(id);
      final bytes = File(contract.runtimePath).readAsBytesSync();
      expect(contract.validatePngHeader(bytes), isEmpty, reason: id);
    }
  });
}
