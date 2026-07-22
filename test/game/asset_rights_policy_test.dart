import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/asset_rights_policy.dart';

void main() {
  test(
    'policy exposes only reviewed acquisition routes and lifecycle states',
    () {
      expect(AssetRightsPolicy.acquisitionMethods, {
        'self_made',
        'ai_generated',
        'purchased',
        'commissioned',
        'open_asset',
      });
      expect(AssetRightsPolicy.statuses, {
        'draft',
        'review',
        'approved',
        'blocked',
        'retired',
      });
    },
  );

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

  test(
    'representative enemy atlases remain temporary before mobile review',
    () {
      final lines = File(
        'docs/assets/asset-rights-ledger.csv',
      ).readAsLinesSync();
      final header = lines.first.split(',');
      final assetIdIndex = header.indexOf('asset_id');
      final statusIndex = header.indexOf('status');
      final records = {
        for (final line in lines.skip(1))
          line.split(',')[assetIdIndex]: line.split(',')[statusIndex],
      };

      for (final id in const [
        'balanced_casual_plague_rat_swarm_atlas',
        'balanced_casual_vengeful_spirit_atlas',
        'balanced_casual_sakkat_specter_atlas',
        'balanced_casual_dokkaebi_atlas',
      ]) {
        expect(records[id], 'temporary', reason: id);
      }
    },
  );
}
