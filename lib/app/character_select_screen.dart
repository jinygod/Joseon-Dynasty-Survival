import 'package:flutter/material.dart';

import '../game/content/character_definitions.dart';
import '../game/content/ids.dart';
import '../game/content/weapon_definitions.dart';
import '../game/models/player_slot.dart';
import '../game/systems/save_system.dart';

class CharacterSelectScreen extends StatefulWidget {
  const CharacterSelectScreen({
    required this.onStart,
    this.saveSystem,
    super.key,
  });

  final ValueChanged<PlayerSlot> onStart;
  final SaveSystem? saveSystem;

  @override
  State<CharacterSelectScreen> createState() => _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends State<CharacterSelectScreen> {
  late final Future<SaveState> _saveState;
  String? _selectedCharacterId;

  @override
  void initState() {
    super.initState();
    _saveState = (widget.saveSystem ?? SaveSystem()).load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('캐릭터 선택')),
      body: FutureBuilder<SaveState>(
        future: _saveState,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final unlockedIds = snapshot.data!.unlockedCharacterIds;
          _selectedCharacterId ??= characterDefinitions
              .firstWhere((character) => unlockedIds.contains(character.id))
              .id;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        for (
                          var index = 0;
                          index < characterDefinitions.length;
                          index++
                        ) ...[
                          if (index > 0) const SizedBox(width: 16),
                          Expanded(
                            child: _CharacterCard(
                              definition: characterDefinitions[index],
                              unlocked: unlockedIds.contains(
                                characterDefinitions[index].id,
                              ),
                              selected:
                                  _selectedCharacterId ==
                                  characterDefinitions[index].id,
                              onTap: () {
                                if (!unlockedIds.contains(
                                  characterDefinitions[index].id,
                                )) {
                                  return;
                                }
                                setState(() {
                                  _selectedCharacterId =
                                      characterDefinitions[index].id;
                                });
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    key: const Key('character-start'),
                    onPressed: _selectedCharacterId == null
                        ? null
                        : () => widget.onStart(
                            PlayerSlot(
                              index: 0,
                              characterId: _selectedCharacterId!,
                            ),
                          ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('출진'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({
    required this.definition,
    required this.unlocked,
    required this.selected,
    required this.onTap,
  });

  final CharacterDefinition definition;
  final bool unlocked;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final weapon = weaponDefinitions.firstWhere(
      (candidate) => candidate.id == definition.startingWeaponId,
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      color: selected ? const Color(0xffffefc2) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? const Color(0xff8f2d38) : Colors.transparent,
          width: 3,
        ),
      ),
      child: InkWell(
        key: Key('character-${definition.id}'),
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _iconForCharacter(definition.id),
                    size: 44,
                    color: unlocked
                        ? const Color(0xff8f2d38)
                        : Colors.grey.shade500,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _localizedName(definition.id),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('체력 ${definition.maxHealth.toInt()}'),
                  Text('이동 속도 ${definition.moveSpeed.toInt()}'),
                  Text('공격력 ${(definition.damageMultiplier * 100).round()}%'),
                  Text('시작 무기 ${weapon.name}'),
                  const SizedBox(height: 4),
                  Text(
                    definition.passiveName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    definition.passiveDescription,
                    textAlign: TextAlign.center,
                  ),
                  if (selected)
                    SizedBox(key: Key('character-selected-${definition.id}')),
                ],
              ),
            ),
            if (!unlocked)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.48),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock,
                          key: Key('character-lock-${definition.id}'),
                          size: 40,
                          color: Colors.white,
                        ),
                        const Text(
                          '해금 필요',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _localizedName(String id) {
  return switch (id) {
    rookieConstable => '신참 포졸',
    exorcistDosa => '퇴마 도사',
    mountainHunter => '산길 사냥꾼',
    _ => id,
  };
}

IconData _iconForCharacter(String id) => switch (id) {
  rookieConstable => Icons.shield,
  exorcistDosa => Icons.auto_awesome,
  mountainHunter => Icons.track_changes,
  _ => Icons.person,
};
