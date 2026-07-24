import 'dart:async';

import 'package:flutter/material.dart';

import '../game/content/asset_catalog.dart';
import '../game/models/compendium_entry.dart';
import '../game/systems/compendium_service.dart';
import '../game/systems/save_system.dart';
import 'accessible_status_badge.dart';
import 'joseon_codex_card.dart';
import 'joseon_tab_bar.dart';
import 'missing_asset_placeholder.dart';

typedef CompendiumViewedCallback = Future<void> Function(Set<String> keys);

class CompendiumScreen extends StatefulWidget {
  const CompendiumScreen({
    required this.state,
    this.onEntriesViewed,
    this.service = const CompendiumService(),
    super.key,
  });

  final SaveState state;
  final CompendiumViewedCallback? onEntriesViewed;
  final CompendiumService service;

  @override
  State<CompendiumScreen> createState() => _CompendiumScreenState();
}

class _CompendiumScreenState extends State<CompendiumScreen> {
  late final List<CompendiumEntry> _entries;
  var _selectedSection = 0;

  @override
  void initState() {
    super.initState();
    _entries = widget.service.entries(widget.state);
    final unseen = widget.service.unseenUnlockedKeys(widget.state);
    if (unseen.isNotEmpty && widget.onEntriesViewed != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(widget.onEntriesViewed!(unseen));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final section = CompendiumSection.values[_selectedSection];
    return Scaffold(
      appBar: AppBar(title: const Text('도감')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: JoseonTabBar(
                labels: const ['캐릭터', '무기', '증강'],
                selectedIndex: _selectedSection,
                onChanged: (index) => setState(() => _selectedSection = index),
              ),
            ),
            Expanded(
              child: _CompendiumList(
                entries: _entries
                    .where((entry) => entry.section == section)
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompendiumList extends StatelessWidget {
  const _CompendiumList({required this.entries});

  final List<CompendiumEntry> entries;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).textScaleFactor;
    final useTwoColumns =
        MediaQuery.sizeOf(context).width >= 375 && textScale <= 1.3;
    return GridView.builder(
      key: const Key('compendium-grid'),
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: useTwoColumns ? 2 : 1,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: useTwoColumns ? 260 : 180 * textScale,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) => _CompendiumCard(entry: entries[index]),
    );
  }
}

class _CompendiumCard extends StatelessWidget {
  const _CompendiumCard({required this.entry});

  final CompendiumEntry entry;

  @override
  Widget build(BuildContext context) {
    final card = JoseonCodexCard(
      title: entry.isUnlocked ? entry.name : '미확인 항목',
      description: _description,
      locked: !entry.isUnlocked,
      leading: entry.isUnlocked
          ? _UnlockedArtwork(entry: entry)
          : const _LockedSilhouette(),
      trailing: entry.isUnlocked
          ? null
          : const AccessibleStatusBadge(
              icon: Icons.lock_outline,
              label: '잠김',
              semanticsLabel: '잠긴 항목',
            ),
    );
    return entry.isUnlocked && entry.isNew
        ? Semantics(label: '새 항목', child: card)
        : card;
  }

  String get _description {
    if (!entry.isUnlocked) {
      return '${entry.unlockCondition}\n'
          '${entry.currentProgress} / ${entry.targetProgress}';
    }
    final progress = entry.isUnlocked
        ? ''
        : '\n${entry.currentProgress} / ${entry.targetProgress}';
    return '${entry.detail}\n\n해금 조건\n${entry.unlockCondition}$progress';
  }
}

class _LockedSilhouette extends StatelessWidget {
  const _LockedSilhouette();

  @override
  Widget build(BuildContext context) => const SizedBox(
    key: Key('locked-silhouette'),
    width: 44,
    height: 64,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Color(0xff312b25),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: Icon(Icons.lock, color: Color(0xffffd66b)),
    ),
  );
}

class _UnlockedArtwork extends StatelessWidget {
  const _UnlockedArtwork({required this.entry});

  final CompendiumEntry entry;

  @override
  Widget build(BuildContext context) {
    final assetPath = switch (entry.section) {
      CompendiumSection.character => AssetCatalog.characterPortraits[entry.id],
      CompendiumSection.weapon => AssetCatalog.weapons[entry.id],
      CompendiumSection.augment => AssetCatalog.augments[entry.id],
    };
    if (assetPath == null) {
      return SizedBox(
        width: 44,
        height: 64,
        child: MissingAssetPlaceholder(assetKey: entry.id),
      );
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: 44,
          height: 64,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              assetPath,
              key: const Key('unlocked-original-image'),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  MissingAssetPlaceholder(assetKey: assetPath),
            ),
          ),
        ),
        if (entry.isNew)
          Positioned(
            top: -7,
            right: -13,
            child: Semantics(
              label: '새 항목',
              child: Text(
                'NEW',
                key: Key('new-entry'),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
              ),
            ),
          ),
      ],
    );
  }
}
