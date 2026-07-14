import 'package:flutter/material.dart';

import '../game/content/augment_definitions.dart';
import '../game/content/character_definitions.dart';
import '../game/content/weapon_definitions.dart';
import '../game/models/run_outcome.dart';
import '../game/models/run_feedback.dart';
import '../game/models/run_result.dart';
import '../game/systems/progression_system.dart';

typedef FeedbackSubmitted = Future<void> Function(RunFeedback feedback);
typedef JsonAction = Future<bool> Function();

class RunSummaryScreen extends StatefulWidget {
  const RunSummaryScreen({
    required this.result,
    required this.unlocks,
    required this.onStart,
    required this.onMenu,
    this.onFeedbackSubmitted,
    this.onCopyRunJson,
    this.onExportAllJson,
    super.key,
  });

  final RunResult result;
  final ProgressionUnlocks unlocks;
  final VoidCallback onStart;
  final VoidCallback onMenu;
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
                    isVictory ? '승리' : '패배',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: isVictory ? Colors.amber.shade700 : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.result.bossDefeated ? '보스 처치' : '보스 미처치',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  _StatRow(label: '생존 시간', value: _formatTime()),
                  _StatRow(
                    label: '처치 수',
                    value: widget.result.kills.toString(),
                  ),
                  _StatRow(
                    label: '도달 레벨',
                    value: widget.result.level.toString(),
                  ),
                  if (_weaponIds().isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text('무기 성과', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    for (final weaponId in _weaponIds())
                      _StatRow(
                        label: _displayName(weaponId),
                        value: _weaponMetric(weaponId),
                      ),
                  ],
                  const SizedBox(height: 24),
                  Text('새로운 해금', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (widget.unlocks.isEmpty)
                    const Text('이번 판에서 새로 해금된 항목이 없습니다.')
                  else ...[
                    _UnlockGroup(
                      label: '캐릭터',
                      ids: widget.unlocks.characterIds,
                    ),
                    _UnlockGroup(label: '무기', ids: widget.unlocks.weaponIds),
                    _UnlockGroup(label: '증강', ids: widget.unlocks.augmentIds),
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
                              successMessage: '런 JSON을 복사했습니다.',
                              emptyMessage: '복사할 런 기록이 없습니다.',
                            ),
                            icon: const Icon(Icons.copy),
                            label: const Text('이 런 JSON 복사'),
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
                            label: const Text('전체 기록 JSON 내보내기'),
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
                        onPressed: widget.onStart,
                        child: const Text('다시 시작'),
                      ),
                      OutlinedButton(
                        onPressed: widget.onMenu,
                        child: const Text('메인 메뉴'),
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
    return 'Lv $level · 피해 $damage · 처치 $kills';
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
      _showMessage('JSON 작업에 실패했습니다.');
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
