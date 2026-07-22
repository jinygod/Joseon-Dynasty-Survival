import 'dart:async';

import 'package:flutter/material.dart';

import '../backend/account/account_controller.dart';
import '../backend/economy/purchase_controller.dart';
import '../backend/progress/progress_sync_controller.dart';
import '../game/audio/audio_cue.dart';
import '../game/audio/audio_settings_controller.dart';
import '../game/audio/game_audio_service.dart';
import '../game/content/asset_catalog.dart';
import '../game/content/character_definitions.dart';
import '../game/content/stage_definitions.dart';
import '../game/models/player_slot.dart';
import '../game/systems/tutorial_progress_repository.dart';
import '../game/systems/playtest_session_repository.dart';
import '../l10n/app_strings.dart';
import 'character_select_screen.dart';
import 'account_section.dart';
import 'compendium_screen.dart';
import 'game_screen.dart';
import 'lobby_controller.dart';
import 'premium_shop_screen.dart';
import 'records_screen.dart';
import 'settings_screen.dart';
import 'stage_select_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({
    required this.controller,
    required this.audioSettingsController,
    this.tutorialProgressRepository,
    this.audioService,
    this.accountController,
    this.progressSyncController,
    this.purchaseController,
    this.onPurchaseInitializationRetry,
    this.playtestSessionRepository,
    super.key,
  });

  final LobbyController controller;
  final AudioSettingsController audioSettingsController;
  final TutorialProgressRepository? tutorialProgressRepository;
  final GameAudioService? audioService;
  final AccountController? accountController;
  final ProgressSyncController? progressSyncController;
  final PurchaseController? purchaseController;
  final VoidCallback? onPurchaseInitializationRetry;
  final PlaytestSessionRepository? playtestSessionRepository;

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> with WidgetsBindingObserver {
  bool _launching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.controller.syncNow());
      final purchases = widget.purchaseController;
      if (purchases != null) {
        unawaited(purchases.onResume());
      } else {
        widget.onPurchaseInitializationRetry?.call();
      }
    }
  }

  Future<void> _openPremiumShop() async {
    final purchases = widget.purchaseController;
    if (purchases == null) {
      widget.onPurchaseInitializationRetry?.call();
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PremiumShopScreen(
          controller: purchases,
          onAccountLinkRequired: widget.accountController?.connectGoogle,
        ),
      ),
    );
    await purchases.onResume();
  }

  Future<void> _openCharacterPicker() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (pickerContext) => CharacterSelectScreen(
          initialCharacterId: widget.controller.state.selectedCharacterId,
          unlockedCharacterIds: widget.controller.state.unlockedCharacterIds,
          onSelected: (characterId) {
            unawaited(_saveCharacter(pickerContext, characterId));
          },
        ),
      ),
    );
  }

  Future<void> _saveCharacter(
    BuildContext pickerContext,
    String characterId,
  ) async {
    await widget.controller.selectCharacter(characterId);
    if (pickerContext.mounted) Navigator.of(pickerContext).pop();
  }

  Future<void> _openStagePicker() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (pickerContext) => StageSelectScreen(
          initialStageId: widget.controller.state.selectedStageId,
          unlockedStageIds: widget.controller.state.unlockedStageIds,
          onSelected: (stageId) {
            unawaited(_saveStage(pickerContext, stageId));
          },
        ),
      ),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(
          controller: widget.audioSettingsController,
          resetProgress: widget.controller.resetProgress,
          accountController: widget.accountController,
          progressSyncController: widget.progressSyncController,
        ),
      ),
    );
  }

  Future<void> _openCompendium() async {
    final state = widget.controller.state;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CompendiumScreen(
          state: state,
          onEntriesViewed: widget.controller.markCompendiumEntriesSeen,
        ),
      ),
    );
  }

  Future<void> _saveStage(BuildContext pickerContext, String stageId) async {
    await widget.controller.selectStage(stageId);
    if (pickerContext.mounted) Navigator.of(pickerContext).pop();
  }

  Future<void> _deploy() async {
    if (_launching || widget.controller.loading || widget.controller.saving) {
      return;
    }
    setState(() => _launching = true);
    final audio = widget.audioService;
    if (audio != null) unawaited(audio.play(AudioCue.uiConfirm));

    final tutorial =
        widget.tutorialProgressRepository ?? TutorialProgressRepository();
    var showTutorial = true;
    try {
      showTutorial = !await tutorial.isCompleted();
    } on Object {
      showTutorial = true;
    }
    if (!mounted) return;
    final state = widget.controller.state;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          playerSlot: PlayerSlot(
            index: 0,
            characterId: state.selectedCharacterId,
          ),
          stageId: state.selectedStageId,
          showFirstRunTutorial: showTutorial,
          tutorialProgressRepository: tutorial,
          audioService: widget.audioService,
          audioSettingsController: widget.audioSettingsController,
          playtestSessionRepository: widget.playtestSessionRepository,
          syncProgress: widget.controller.syncNow,
        ),
      ),
    );
    if (!mounted) return;
    await widget.controller.syncNow();
    if (mounted) setState(() => _launching = false);
  }

  void _showRecoveryNotice(String notice) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(notice)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final notice = widget.controller.takeRecoveryNotice();
        if (notice != null) _showRecoveryNotice(notice);
        if (widget.controller.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final state = widget.controller.state;
        final character = characterDefinitions.firstWhere(
          (item) => item.id == state.selectedCharacterId,
        );
        final stage = stageDefinitions.firstWhere(
          (item) => item.id == state.selectedStageId,
        );
        return Scaffold(
          backgroundColor: const Color(0xffffa52f),
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xffffcf62), Color(0xffff982f)],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 600;
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 12 : 18,
                      10,
                      compact ? 12 : 18,
                      14,
                    ),
                    child: Column(
                      children: [
                        if (widget.accountController case final account?) ...[
                          AccountSection(
                            controller: account,
                            syncLabel:
                                widget.progressSyncController?.status.label,
                            onSyncNow: widget.controller.syncNow,
                            syncListenable: widget.progressSyncController,
                          ),
                          const SizedBox(height: 8),
                        ],
                        KeyedSubtree(
                          key: const Key('lobby-resource-bar'),
                          child: _LobbyHeader(
                            coin: state.wallet.coin,
                            spiritJade: state.wallet.spiritJade,
                            purchaseController: widget.purchaseController,
                            purchaseInitializationFailed:
                                widget.onPurchaseInitializationRetry != null,
                            onPremiumShop: _openPremiumShop,
                            onSettings: _openSettings,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: compact
                              ? SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        height: 430,
                                        child: _GovernmentOfficeScene(
                                          characterId: character.id,
                                          characterName: character.name,
                                          stage: stage,
                                          bestSeconds:
                                              state.bestSurvivalSeconds,
                                          launching: _launching,
                                          saving: widget.controller.saving,
                                          onDeploy: _deploy,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      KeyedSubtree(
                                        key: const Key('lobby-bottom-menu'),
                                        child: Wrap(
                                          alignment: WrapAlignment.center,
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            _LobbyMenuButton(
                                              buttonKey: const Key(
                                                'lobby-stage',
                                              ),
                                              icon: Icons.map_outlined,
                                              label: '지도',
                                              compact: true,
                                              onPressed: _openStagePicker,
                                            ),
                                            _LobbyMenuButton(
                                              buttonKey: const Key(
                                                'lobby-character',
                                              ),
                                              icon: Icons.person_outline,
                                              label: '인물',
                                              compact: true,
                                              onPressed: _openCharacterPicker,
                                            ),
                                            _LobbyMenuButton(
                                              buttonKey: const Key(
                                                'lobby-compendium',
                                              ),
                                              icon: Icons.menu_book_outlined,
                                              label: '도감',
                                              compact: true,
                                              onPressed: _openCompendium,
                                            ),
                                            _LobbyMenuButton(
                                              buttonKey: const Key(
                                                'lobby-records',
                                              ),
                                              icon: Icons.emoji_events_outlined,
                                              label: '기록',
                                              compact: true,
                                              onPressed: () =>
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute<void>(
                                                      builder: (_) =>
                                                          RecordsScreen(
                                                            state: state,
                                                          ),
                                                    ),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _LobbyMenuButton(
                                      buttonKey: const Key('lobby-stage'),
                                      icon: Icons.map_outlined,
                                      label: '지도',
                                      onPressed: _openStagePicker,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _GovernmentOfficeScene(
                                        characterId: character.id,
                                        characterName: character.name,
                                        stage: stage,
                                        bestSeconds: state.bestSurvivalSeconds,
                                        launching: _launching,
                                        saving: widget.controller.saving,
                                        onDeploy: _deploy,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      width: 116,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          _LobbyMenuButton(
                                            buttonKey: const Key(
                                              'lobby-character',
                                            ),
                                            icon: Icons.person_outline,
                                            label: '인물',
                                            onPressed: _openCharacterPicker,
                                          ),
                                          const SizedBox(height: 12),
                                          _LobbyMenuButton(
                                            buttonKey: const Key(
                                              'lobby-compendium',
                                            ),
                                            icon: Icons.menu_book_outlined,
                                            label: '도감',
                                            onPressed: _openCompendium,
                                          ),
                                          const SizedBox(height: 12),
                                          _LobbyMenuButton(
                                            buttonKey: const Key(
                                              'lobby-records',
                                            ),
                                            icon: Icons.emoji_events_outlined,
                                            label: '기록',
                                            onPressed: () =>
                                                Navigator.of(context).push(
                                                  MaterialPageRoute<void>(
                                                    builder: (_) =>
                                                        RecordsScreen(
                                                          state: state,
                                                        ),
                                                  ),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LobbyHeader extends StatelessWidget {
  const _LobbyHeader({
    required this.coin,
    required this.spiritJade,
    required this.purchaseController,
    required this.purchaseInitializationFailed,
    required this.onPremiumShop,
    required this.onSettings,
  });

  final int coin;
  final int spiritJade;
  final PurchaseController? purchaseController;
  final bool purchaseInitializationFailed;
  final VoidCallback onPremiumShop;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final resourceItems = <Widget>[
      const Text('수련 단계 0'),
      _ResourceBadge(icon: Icons.paid_outlined, label: '엽전 $coin'),
      _ResourceBadge(icon: Icons.diamond_outlined, label: '혼옥 $spiritJade'),
      if (purchaseController case final purchases?)
        AnimatedBuilder(
          animation: purchases,
          builder: (context, _) => ActionChip(
            key: const Key('lobby-premium-shop'),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            labelPadding: const EdgeInsets.symmetric(horizontal: 2),
            label: Text(
              purchases.state.walletStale
                  ? '금옥 --'
                  : '금옥 ${purchases.state.wallet?.balance ?? 0}',
            ),
            onPressed: onPremiumShop,
          ),
        )
      else if (purchaseInitializationFailed)
        ActionChip(
          key: const Key('lobby-premium-shop-retry'),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          labelPadding: const EdgeInsets.symmetric(horizontal: 2),
          label: const Text('금옥 재시도'),
          onPressed: onPremiumShop,
        ),
    ];
    final settingsButton = IconButton.filledTonal(
      key: const Key('lobby-settings'),
      tooltip: '설정',
      onPressed: onSettings,
      icon: const Icon(Icons.settings_outlined),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      AppStrings.appTitle,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  settingsButton,
                ],
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: resourceItems),
            ],
          );
        }

        return Row(
          children: [
            const Text(
              AppStrings.appTitle,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 16),
            resourceItems.first,
            const Spacer(),
            for (final item in resourceItems.skip(1)) ...[
              item,
              const SizedBox(width: 8),
            ],
            settingsButton,
          ],
        );
      },
    );
  }
}

class _ResourceBadge extends StatelessWidget {
  const _ResourceBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xfffff7e4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xff9a7a45)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xff8f2d38)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _LobbyMenuButton extends StatelessWidget {
  const _LobbyMenuButton({
    required this.buttonKey,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.compact = false,
  });

  final Key buttonKey;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? 80 : 116,
      height: compact ? 64 : 88,
      child: FilledButton.tonal(
        key: buttonKey,
        onPressed: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: compact ? 23 : 30),
            SizedBox(height: compact ? 2 : 6),
            Text(label, style: TextStyle(fontSize: compact ? 12 : 14)),
          ],
        ),
      ),
    );
  }
}

class _GovernmentOfficeScene extends StatelessWidget {
  const _GovernmentOfficeScene({
    required this.characterId,
    required this.characterName,
    required this.stage,
    required this.bestSeconds,
    required this.launching,
    required this.saving,
    required this.onDeploy,
  });

  final String characterId;
  final String characterName;
  final StageDefinition stage;
  final int bestSeconds;
  final bool launching;
  final bool saving;
  final VoidCallback onDeploy;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('lobby-stage-hero'),
      clipBehavior: Clip.antiAlias,
      color: const Color(0xff243b32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xffcaa85e), width: 3),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xff356653), Color(0xff183b36)],
              ),
            ),
          ),
          const CustomPaint(painter: _OfficeStagePainter()),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xff102b2b).withValues(alpha: .8),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    '오늘의 출진',
                    style: TextStyle(
                      color: Color(0xffffd166),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  stage.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '최고 기록 ${_clock(bestSeconds)}',
                  style: const TextStyle(color: Color(0xffffe6a7)),
                ),
                const Spacer(),
                _LobbyCharacterArt(characterId: characterId),
                Text(
                  characterName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 210,
                  child: FilledButton.icon(
                    key: const Key('lobby-deploy'),
                    onPressed: launching || saving ? null : onDeploy,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xffffc928),
                      foregroundColor: const Color(0xff281807),
                      side: const BorderSide(
                        color: Color(0xff281807),
                        width: 2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    icon: const Icon(Icons.local_fire_department),
                    label: Text(launching ? '출진 준비 중' : '출진'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LobbyCharacterArt extends StatelessWidget {
  const _LobbyCharacterArt({required this.characterId});

  final String characterId;

  @override
  Widget build(BuildContext context) {
    final path =
        AssetCatalog.characters[characterId] ??
        AssetCatalog.characters[rookieConstable]!;
    final usesAtlas = path.endsWith('_128.png');
    return SizedBox.square(
      key: const Key('lobby-character-art'),
      dimension: 132,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0x3348d7a1),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x99000000),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: usesAtlas
            ? ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: 528,
                  maxWidth: 528,
                  minHeight: 528,
                  maxHeight: 528,
                  child: Image.asset(
                    path,
                    width: 528,
                    height: 528,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset(
                  path,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),
              ),
      ),
    );
  }
}

class _OfficeStagePainter extends CustomPainter {
  const _OfficeStagePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final roof = Paint()..color = const Color(0xff8f2d38);
    final timber = Paint()..color = const Color(0xff4d2b20);
    final paper = Paint()..color = const Color(0x55fff1b8);
    final roofPath = Path()
      ..moveTo(size.width * .08, size.height * .25)
      ..lineTo(size.width * .5, size.height * .08)
      ..lineTo(size.width * .92, size.height * .25)
      ..lineTo(size.width * .86, size.height * .29)
      ..lineTo(size.width * .14, size.height * .29)
      ..close();
    canvas.drawPath(roofPath, roof);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * .18,
        size.height * .27,
        size.width * .64,
        size.height * .42,
      ),
      paper,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * .18,
        size.height * .27,
        size.width * .035,
        size.height * .48,
      ),
      timber,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * .785,
        size.height * .27,
        size.width * .035,
        size.height * .48,
      ),
      timber,
    );
  }

  @override
  bool shouldRepaint(covariant _OfficeStagePainter oldDelegate) => false;
}

String _clock(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
