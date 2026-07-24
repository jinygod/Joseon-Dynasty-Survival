import 'package:flutter/material.dart';

import '../game/content/asset_catalog.dart';
import '../game/content/stage_definitions.dart';
import 'joseon_buttons.dart';
import 'joseon_scaffold.dart';
import 'joseon_selection_card.dart';
import 'missing_asset_placeholder.dart';

class StageSelectScreen extends StatefulWidget {
  const StageSelectScreen({
    required this.initialStageId,
    required this.onSelected,
    this.unlockedStageIds = const {moonlitAbandonedOffice},
    super.key,
  });
  final String initialStageId;
  final ValueChanged<String> onSelected;
  final Set<String> unlockedStageIds;
  @override
  State<StageSelectScreen> createState() => _StageSelectScreenState();
}

class _StageSelectScreenState extends State<StageSelectScreen> {
  late String _selectedStageId;
  late PageController _pageController;
  @override
  void initState() {
    super.initState();
    final initial = stageDefinitionFor(widget.initialStageId).id;
    _selectedStageId = widget.unlockedStageIds.contains(initial)
        ? initial
        : stageDefinitions
                  .where((stage) => widget.unlockedStageIds.contains(stage.id))
                  .map((stage) => stage.id)
                  .firstOrNull ??
              stageDefinitions.first.id;
    _pageController = PageController(
      initialPage: stageDefinitions.indexWhere(
        (stage) => stage.id == _selectedStageId,
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
    final unlocked = widget.unlockedStageIds.contains(_selectedStageId);
    return Material(
      child: JoseonScaffold(
        topBar: const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '스테이지 선택',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
        ),
        body: PageView.builder(
          controller: _pageController,
          itemCount: stageDefinitions.length,
          onPageChanged: (index) =>
              setState(() => _selectedStageId = stageDefinitions[index].id),
          itemBuilder: (context, index) {
            final stage = stageDefinitions[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: _StageCard(
                stage: stage,
                unlocked: widget.unlockedStageIds.contains(stage.id),
                selected: _selectedStageId == stage.id,
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
                key: const Key('stage-confirm'),
                label: '선택 완료',
                onPressed: unlocked
                    ? () => widget.onSelected(_selectedStageId)
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.stage,
    required this.unlocked,
    required this.selected,
    required this.onTap,
  });
  final StageDefinition stage;
  final bool unlocked;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final imagePath =
        AssetCatalog.stagePresentation[stage.presentationImageKey];
    return JoseonSelectionCard(
      key: Key('stage-${stage.id}'),
      selected: selected,
      locked: !unlocked,
      semanticsLabel: stage.name,
      onTap: onTap,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              key: Key('stage-illustration-slot-${stage.id}'),
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imagePath == null
                    ? MissingAssetPlaceholder(
                        assetKey: stage.presentationImageKey,
                      )
                    : Image.asset(
                        imagePath,
                        key: Key('stage-illustration-${stage.id}'),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => MissingAssetPlaceholder(
                          assetKey: stage.presentationImageKey,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              stage.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              stage.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Text(
              '위험 ${stage.riskLabel}   목표 ${_clock(stage.targetSeconds)}   보스 ${_clock(stage.bossArrivalSeconds)}',
            ),
            if (!unlocked)
              Center(
                child: Icon(Icons.lock, key: Key('stage-lock-${stage.id}')),
              ),
          ],
        ),
      ),
    );
  }
}

String _clock(int totalSeconds) =>
    '${totalSeconds ~/ 60}:${(totalSeconds % 60).toString().padLeft(2, '0')}';
