import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../game/content/augment_definitions.dart';
import '../game/content/character_definitions.dart';
import '../game/content/weapon_definitions.dart';
import '../game/models/run_outcome.dart';
import '../game/models/run_feedback.dart';
import '../game/models/run_result.dart';
import '../game/systems/progression_system.dart';
import '../game/systems/meta_progression_service.dart';

typedef FeedbackSubmitted = Future<void> Function(RunFeedback feedback);
typedef JsonAction = Future<bool> Function();

class RunSummaryScreen extends StatefulWidget {
  const RunSummaryScreen({
    required this.result,
    required this.unlocks,
    required this.onStart,
    required this.onMenu,
    this.settlement,
    this.onFeedbackSubmitted,
    this.onCopyRunJson,
    this.onExportAllJson,
    super.key,
  });

  final RunResult result;
  final ProgressionUnlocks unlocks;
  final VoidCallback onStart;
  final VoidCallback onMenu;
  final RunSettlement? settlement;
  final FeedbackSubmitted? onFeedbackSubmitted;
  final JsonAction? onCopyRunJson;
  final JsonAction? onExportAllJson;

  @override
  State<RunSummaryScreen> createState() => _RunSummaryScreenState();
}

class _RunSummaryScreenState extends State<RunSummaryScreen> {
  final TextEditingController _commentController = TextEditingController();
  int? _funRating;
  int? _difficultyRating;
  bool? _retryIntent;
  bool _savingFeedback = false;
  bool _feedbackSaved = false;
  bool _navigationCommitted = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVictory = widget.result.outcome == RunOutcome.victory;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Text(
                    isVictory ? AppStrings.victory : AppStrings.defeat,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: isVictory ? Colors.amber.shade700 : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.result.bossDefeated
                        ? AppStrings.bossDefeated
                        : AppStrings.bossNotDefeated,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  _StatRow(
                    label: AppStrings.survivalTime,
                    value: _formatTime(),
                  ),
                  _StatRow(
                    label: AppStrings.killCount,
                    value: widget.result.kills.toString(),
                  ),
                  _StatRow(
                    label: AppStrings.reachedLevel,
                    value: widget.result.level.toString(),
                  ),
                  if (widget.settlement case final settlement?) ...[
                    const SizedBox(height: 18),
                    Text('이번 판 보상', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _StatRow(label: '엽전', value: '+${settlement.coinEarned}'),
                    if (settlement.spiritJadeEarned > 0)
                      _StatRow(
                        label: '혼옥',
                        value: '+${settlement.spiritJadeEarned}',
                      ),
                  ],
                  if (_weaponIds().isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      AppStrings.weaponPerformance,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    for (final weaponId in _weaponIds())
                      _StatRow(
                        label: _displayName(weaponId),
                        value: _weaponMetric(weaponId),
                      ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    AppStrings.newUnlocks,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (widget.unlocks.isEmpty)
                    const Text(AppStrings.noNewUnlocks)
                  else ...[
                    _UnlockGroup(
                      label: AppStrings.character,
                      ids: widget.unlocks.characterIds,
                    ),
                    _UnlockGroup(
                      label: AppStrings.weapon,
                      ids: widget.unlocks.weaponIds,
                    ),
                    _UnlockGroup(
                      label: AppStrings.augment,
                      ids: widget.unlocks.augmentIds,
                    ),
                  ],
                  if (widget.onFeedbackSubmitted != null) ...[
                    const SizedBox(height: 24),
                    Text('플레이 피드백', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _ratingSelector(
                      label: '재미',
                      keyPrefix: 'fun-rating',
                      selected: _funRating,
                      onSelected: (value) => setState(() => _funRating = value),
                    ),
                    const SizedBox(height: 10),
                    _ratingSelector(
                      label: '난이도',
                      keyPrefix: 'difficulty-rating',
                      selected: _difficultyRating,
                      onSelected: (value) =>
                          setState(() => _difficultyRating = value),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const SizedBox(width: 72, child: Text('재도전')),
                        ChoiceChip(
                          key: const Key('retry-yes'),
                          label: const Text('예'),
                          selected: _retryIntent == true,
                          onSelected: (_) =>
                              setState(() => _retryIntent = true),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          key: const Key('retry-no'),
                          label: const Text('아니오'),
                          selected: _retryIntent == false,
                          onSelected: (_) =>
                              setState(() => _retryIntent = false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      key: const Key('feedback-comment'),
                      controller: _commentController,
                      maxLength: 200,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: '짧은 의견 (선택)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    FilledButton(
                      key: const Key('feedback-submit'),
                      onPressed: _canSubmitFeedback ? _submitFeedback : null,
                      child: Text(_savingFeedback ? '저장 중...' : '피드백 저장'),
                    ),
                    if (_feedbackSaved)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('피드백 저장 완료'),
                      ),
                  ],
                  if (widget.onCopyRunJson != null ||
                      widget.onExportAllJson != null) ...[
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (widget.onCopyRunJson != null)
                          OutlinedButton.icon(
                            key: const Key('copy-run-json'),
                            onPressed: () => _runJsonAction(
                              widget.onCopyRunJson!,
                              successMessage: '이 판 기록을 복사했습니다.',
                              emptyMessage: '복사할 런 기록이 없습니다.',
                            ),
                            icon: const Icon(Icons.copy),
                            label: const Text(AppStrings.copyRunRecord),
                          ),
                        if (widget.onExportAllJson != null)
                          OutlinedButton.icon(
                            key: const Key('export-all-json'),
                            onPressed: () => _runJsonAction(
                              widget.onExportAllJson!,
                              successMessage: '전체 기록 내보내기를 열었습니다.',
                              emptyMessage: '내보낼 기록이 없습니다.',
                            ),
                            icon: const Icon(Icons.ios_share),
                            label: const Text(AppStrings.exportAllRecords),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton(
                        key: const Key('result-retry'),
                        onPressed: _navigationCommitted
                            ? null
                            : () => _commitNavigation(widget.onStart),
                        child: const Text(AppStrings.retry),
                      ),
                      OutlinedButton(
                        key: const Key('result-menu'),
                        onPressed: _navigationCommitted
                            ? null
                            : () => _commitNavigation(widget.onMenu),
                        child: const Text(AppStrings.mainMenu),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime() {
    final minutes = widget.result.survivalSeconds ~/ 60;
    final seconds = widget.result.survivalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  List<String> _weaponIds() {
    final ids = {
      ...widget.result.weaponLevels.keys,
      ...widget.result.weaponDamageTotals.keys,
      ...widget.result.weaponKillCounts.keys,
    }.toList();
    ids.sort((a, b) => _displayName(a).compareTo(_displayName(b)));
    return ids;
  }

  String _weaponMetric(String weaponId) {
    final level = widget.result.weaponLevels[weaponId] ?? 0;
    final damage = (widget.result.weaponDamageTotals[weaponId] ?? 0).round();
    final kills = widget.result.weaponKillCounts[weaponId] ?? 0;
    return AppStrings.weaponMetric(level: level, damage: damage, kills: kills);
  }

  bool get _canSubmitFeedback =>
      !_savingFeedback &&
      _funRating != null &&
      _difficultyRating != null &&
      _retryIntent != null;

  Widget _ratingSelector({
    required String label,
    required String keyPrefix,
    required int? selected,
    required ValueChanged<int> onSelected,
  }) {
    return Row(
      children: [
        SizedBox(width: 72, child: Text(label)),
        Expanded(
          child: Wrap(
            spacing: 6,
            children: [
              for (var rating = 1; rating <= 5; rating += 1)
                ChoiceChip(
                  key: Key('$keyPrefix-$rating'),
                  label: Text('$rating'),
                  selected: selected == rating,
                  onSelected: (_) => onSelected(rating),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submitFeedback() async {
    final callback = widget.onFeedbackSubmitted;
    if (!_canSubmitFeedback || callback == null) return;
    setState(() => _savingFeedback = true);
    try {
      await callback(
        RunFeedback(
          funRating: _funRating!,
          difficultyRating: _difficultyRating!,
          retryIntent: _retryIntent!,
          comment: _commentController.text,
        ),
      );
      if (!mounted) return;
      setState(() {
        _savingFeedback = false;
        _feedbackSaved = true;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _savingFeedback = false);
      _showMessage('피드백 저장에 실패했습니다.');
    }
  }

  void _commitNavigation(VoidCallback action) {
    if (_navigationCommitted) return;
    setState(() => _navigationCommitted = true);
    action();
  }

  Future<void> _runJsonAction(
    JsonAction action, {
    required String successMessage,
    required String emptyMessage,
  }) async {
    try {
      final succeeded = await action();
      if (!mounted) return;
      _showMessage(succeeded ? successMessage : emptyMessage);
    } on Object {
      if (!mounted) return;
      _showMessage('기록 작업에 실패했습니다.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

String _displayName(String id) {
  const localizedNames = {
    rookieConstable: '신참 포졸',
    exorcistDosa: '퇴마 도사',
    lastStand: '최후의 저항',
  };
  final localizedName = localizedNames[id];
  if (localizedName != null) return localizedName;
  for (final definition in weaponDefinitions) {
    if (definition.id == id) return definition.name;
  }
  for (final definition in augmentDefinitions) {
    if (definition.id == id) return definition.name;
  }
  for (final definition in characterDefinitions) {
    if (definition.id == id) return definition.name;
  }
  return id;
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _UnlockGroup extends StatelessWidget {
  const _UnlockGroup({required this.label, required this.ids});

  final String label;
  final List<String> ids;

  @override
  Widget build(BuildContext context) {
    if (ids.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in ids)
                Chip(
                  label: Text(_displayName(id)),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
