import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mobile preview contains both casual presentation and combat VFX', () {
    const requiredPaths = <String>[
      'assets/images/player/exorcist_dosa_128.png',
      'assets/images/monsters/plague_rat_swarm_128.png',
      'lib/app/lobby_battle_stage.dart',
      'lib/app/lobby_screen.dart',
      'lib/app/lobby_primary_navigation.dart',
      'lib/app/virtual_joystick.dart',
      'assets/images/vfx/hwando_slash_trail_128.png',
      'assets/images/vfx/enemy/radial_telegraph_128.png',
      'assets/images/tiles/moonlit_office_tiles_128.png',
      'lib/game/content/attack_visual_registry.dart',
      'lib/game/components/hwando_vfx_component.dart',
    ];

    for (final path in requiredPaths) {
      expect(File(path).existsSync(), isTrue, reason: 'Missing $path');
    }

    expect(
      File('lib/app/virtual_joystick.dart').readAsStringSync(),
      contains("Key('virtual-joystick')"),
    );
    final lobbyScreen = File('lib/app/lobby_screen.dart').readAsStringSync();
    expect(lobbyScreen, contains('LobbyScene('));
    expect(lobbyScreen, contains('LobbyPrimaryNavigation('));
  });
}
