import 'package:flutter/material.dart';

import '../game/content/asset_catalog.dart';
import '../game/content/character_definitions.dart';
import '../game/content/ids.dart';
import '../game/content/weapon_definitions.dart';
import 'character_stat_presenter.dart';
import 'joseon_buttons.dart';
import 'joseon_scaffold.dart';
import 'joseon_selection_card.dart';
import 'missing_asset_placeholder.dart';

class CharacterSelectScreen extends StatefulWidget {
  const CharacterSelectScreen({
    required this.initialCharacterId,
    required this.unlockedCharacterIds,
    required this.onSelected,
    super.key,
  });
  final String initialCharacterId;
  final Set<String> unlockedCharacterIds;
  final ValueChanged<String> onSelected;
  @override
  State<CharacterSelectScreen> createState() => _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends State<CharacterSelectScreen> {
  late String _selectedCharacterId;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _selectedCharacterId =
        widget.unlockedCharacterIds.contains(widget.initialCharacterId)
        ? widget.initialCharacterId
        : widget.unlockedCharacterIds.first;
    _pageController = PageController(
      initialPage: characterDefinitions.indexWhere(
        (character) => character.id == _selectedCharacterId,
      ),
      viewportFraction: .88,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = widget.unlockedCharacterIds.contains(_selectedCharacterId);
    return Material(
      child: JoseonScaffold(
        topBar: const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '캐릭터 선택',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
        ),
        body: PageView.builder(
          controller: _pageController,
          itemCount: characterDefinitions.length,
          onPageChanged: (index) => setState(
            () => _selectedCharacterId = characterDefinitions[index].id,
          ),
          itemBuilder: (context, index) {
            final character = characterDefinitions[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: _CharacterCard(
                definition: character,
                unlocked: widget.unlockedCharacterIds.contains(character.id),
                selected: _selectedCharacterId == character.id,
                onTap: () => _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                ),
              ),
            );
          },
        ),
        bottomBar: SizedBox(
          height: 72,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SizedBox(
              height: 52,
              width: double.infinity,
              child: JoseonPrimaryButton(
                key: const Key('character-confirm'),
                label: '선택 완료',
                onPressed: unlocked
                    ? () => widget.onSelected(_selectedCharacterId)
                    : null,
              ),
            ),
          ),
        ),
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
      (weapon) => weapon.id == definition.startingWeaponId,
    );
    final stats = characterDisplayStats(definition);
    final assetPath = AssetCatalog.characters[definition.id];
    return JoseonSelectionCard(
      key: Key('character-${definition.id}'),
      selected: selected,
      locked: !unlocked,
      semanticsLabel: definition.name,
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: (constraints.maxHeight * .36).clamp(160.0, 220.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: assetPath == null
                    ? MissingAssetPlaceholder(assetKey: definition.id)
                    : Image.asset(
                        assetPath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            MissingAssetPlaceholder(assetKey: definition.id),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              definition.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              '${definition.passiveName} · ${definition.passiveDescription}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Text(
              '체력 ${stats.health}   공격 ${stats.attack}   이동 속도 ${stats.moveSpeed}',
            ),
            const SizedBox(height: 6),
            Text(
              '시작 무기 ${weapon.name}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (selected) const Text('선택됨'),
            if (selected)
              SizedBox(key: Key('character-selected-${definition.id}')),
            if (!unlocked)
              Center(
                child: Icon(
                  Icons.lock,
                  key: Key('character-lock-${definition.id}'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
