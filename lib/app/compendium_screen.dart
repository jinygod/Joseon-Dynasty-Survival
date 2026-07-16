import 'dart:async';

import 'package:flutter/material.dart';

import '../game/models/compendium_entry.dart';
import '../game/systems/compendium_service.dart';
import '../game/systems/save_system.dart';

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
    return DefaultTabController(
      length: CompendiumSection.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('도감'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '인물'),
              Tab(text: '무기'),
              Tab(text: '증강'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              for (final section in CompendiumSection.values)
                _CompendiumList(
                  entries: _entries
                      .where((entry) => entry.section == section)
                      .toList(),
                ),
            ],
          ),
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
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _CompendiumCard(entry: entries[index]),
    );
  }
}

class _CompendiumCard extends StatelessWidget {
  const _CompendiumCard({required this.entry});

  final CompendiumEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  entry.isUnlocked ? Icons.lock_open : Icons.lock_outline,
                  color: entry.isUnlocked
                      ? colorScheme.primary
                      : colorScheme.outline,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (entry.isNew)
                  const Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text('새 항목'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(entry.detail),
            const SizedBox(height: 8),
            Text(
              entry.isUnlocked
                  ? '해금 완료 · ${entry.unlockCondition}'
                  : entry.unlockCondition,
              style: TextStyle(
                color: entry.isUnlocked
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (!entry.isUnlocked) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: entry.progressFraction),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${entry.currentProgress} / ${entry.targetProgress}',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
