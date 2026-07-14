import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/asset_rights_policy.dart';

void main() {
  test('policy exposes only reviewed acquisition routes and lifecycle states', () {
    expect(
      AssetRightsPolicy.acquisitionMethods,
      {'self_made', 'ai_generated', 'purchased', 'commissioned', 'open_asset'},
    );
    expect(
      AssetRightsPolicy.statuses,
      {'draft', 'review', 'approved', 'blocked', 'retired'},
    );
  });

  test('versioned rights ledger uses every required policy column', () {
    final header = File(
      'docs/assets/asset-rights-ledger.csv',
    ).readAsLinesSync().first.split(',');

    expect(header, AssetRightsPolicy.ledgerColumns);
  });

  test('only approved records are eligible for release', () {
    for (final status in AssetRightsPolicy.statuses) {
      expect(
        AssetRightsPolicy.canShip(status),
        status == 'approved',
        reason: status,
      );
    }
    expect(AssetRightsPolicy.canShip('unknown'), isFalse);
  });
}
