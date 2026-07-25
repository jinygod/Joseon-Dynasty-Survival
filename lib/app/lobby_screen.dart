import 'dart:async';

import 'package:flutter/material.dart';

import '../backend/account/account_controller.dart';
import '../backend/economy/purchase_controller.dart';
import '../backend/progress/progress_sync_controller.dart';
import '../game/audio/audio_cue.dart';
import '../game/audio/audio_settings_controller.dart';
import '../game/audio/game_audio_service.dart';
import '../game/content/character_definitions.dart';
import '../game/content/stage_definitions.dart';
import '../game/models/player_slot.dart';
import '../game/systems/playtest_session_repository.dart';
import '../game/systems/tutorial_progress_repository.dart';
import 'character_select_screen.dart';
import 'compendium_screen.dart';
import 'game_screen.dart';
import 'lobby_battle_stage.dart';
import 'lobby_controller.dart';
import 'lobby_feature_notice.dart';
import 'lobby_primary_navigation.dart';
import 'lobby_quick_actions.dart';
import 'lobby_scene.dart';
import 'lobby_side_menu.dart';
import 'lobby_status_bar.dart';
import 'premium_shop_screen.dart';
import 'records_screen.dart';
import 'settings_screen.dart';
import 'stage_select_screen.dart';
import 'training_screen.dart';

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
          onSelected: (characterId) =>
              unawaited(_saveCharacter(pickerContext, characterId)),
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
          onSelected: (stageId) =>
              unawaited(_saveStage(pickerContext, stageId)),
        ),
      ),
    );
  }

  Future<void> _saveStage(BuildContext pickerContext, String stageId) async {
    await widget.controller.selectStage(stageId);
    if (pickerContext.mounted) Navigator.of(pickerContext).pop();
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ScaffoldMessenger(
          child: SettingsScreen(
            controller: widget.audioSettingsController,
            resetProgress: widget.controller.resetProgress,
            accountController: widget.accountController,
            progressSyncController: widget.progressSyncController,
          ),
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

  Future<void> _openTraining() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            TrainingScreen(progress: widget.controller.state.trainingProgress),
      ),
    );
  }

  Future<void> _deploy() async {
    if (_launching || widget.controller.loading || widget.controller.saving)
      return;
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
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(notice)));
    });
  }

  Widget _premiumEntry() {
    final purchases = widget.purchaseController;
    final retry = widget.onPurchaseInitializationRetry;
    if (purchases == null && retry == null) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: purchases ?? widget.controller,
      builder: (context, _) => Semantics(
        button: true,
        label: purchases == null ? '상점 다시 시도' : '상점',
        child: GestureDetector(
          key: Key(
            purchases == null
                ? 'lobby-premium-shop-retry'
                : 'lobby-premium-shop',
          ),
          behavior: HitTestBehavior.opaque,
          onTap: _openPremiumShop,
          child: Center(
            child: Text(
              purchases == null
                  ? '금옥 재시도'
                  : purchases.state.walletStale
                  ? '금옥 --'
                  : '금옥 ${purchases.state.wallet?.balance ?? 0}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openRecords() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => RecordsScreen(state: widget.controller.state),
    ),
  );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final notice = widget.controller.takeRecoveryNotice();
      if (notice != null) _showRecoveryNotice(notice);
      if (widget.controller.loading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final state = widget.controller.state;
      final character = characterDefinitions.firstWhere(
        (item) => item.id == state.selectedCharacterId,
      );
      final stage = stageDefinitions.firstWhere(
        (item) => item.id == state.selectedStageId,
      );
      return Scaffold(
        backgroundColor: const Color(0xff071527),
        body: SafeArea(
          child: MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.noScaling),
            child: LobbyScene(
              characterId: character.id,
              foreground: LayoutBuilder(
                builder: (context, constraints) {
                  final compactRails = constraints.maxWidth <= 640;
                  final ultraWide =
                      constraints.maxWidth >= constraints.maxHeight * 2;
                  final account = widget.accountController;
                  final railTop = account == null ? 70.0 : 112.0;
                  return MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.noScaling),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned(
                          top: 8,
                          left: 12,
                          right: 12,
                          child: KeyedSubtree(
                            key: const Key('lobby-status-bar'),
                            child: LobbyStatusBar(
                              coin: state.wallet.coin,
                              spiritJade: state.wallet.spiritJade,
                              trainingRank: '훈련',
                              premiumEntry: _premiumEntry(),
                              onSettings: _openSettings,
                            ),
                          ),
                        ),
                        if (account != null)
                          Positioned(
                            top: 66,
                            right: 82,
                            width: 210,
                            height: 40,
                            child: ListenableBuilder(
                              listenable: account,
                              builder: (context, _) => Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      account.session.isPermanent
                                          ? account.session.email!
                                          : '손님 계정',
                                      key: const Key('account-summary'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  if (account.session.isPermanent)
                                    GestureDetector(
                                      key: const Key('sync-now'),
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => unawaited(
                                        widget.controller.syncNow(),
                                      ),
                                      child: const SizedBox(
                                        width: 48,
                                        height: 40,
                                        child: Center(child: Text('동기화')),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        if (compactRails)
                          Positioned(
                            top: railTop,
                            left: 0,
                            right: 0,
                            height: 76,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: LobbySideMenu(
                                    axis: Axis.horizontal,
                                    actions: [
                                      _noticeAction(
                                        'mail',
                                        '우편',
                                        'mail',
                                        LobbyFeature.mail,
                                      ),
                                      _noticeAction(
                                        'mission',
                                        '임무',
                                        'mission',
                                        LobbyFeature.mission,
                                      ),
                                      _noticeAction(
                                        'pass',
                                        '패스',
                                        'pass',
                                        LobbyFeature.pass,
                                      ),
                                      _noticeAction(
                                        'package',
                                        '보관함',
                                        'package',
                                        LobbyFeature.package,
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: LobbySideMenu(
                                    axis: Axis.horizontal,
                                    actions: [
                                      LobbyMenuAction(
                                        id: 'compendium',
                                        label: '도감',
                                        iconAsset:
                                            'assets/images/ui/lobby/icon_compendium.png',
                                        onPressed: _openCompendium,
                                      ),
                                      LobbyMenuAction(
                                        id: 'records',
                                        label: '기록',
                                        iconAsset:
                                            'assets/images/ui/lobby/icon_records.png',
                                        onPressed: _openRecords,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (!compactRails) ...[
                          Positioned(
                            top: railTop,
                            bottom: 150,
                            left: 4,
                            width: 70,
                            child: LobbySideMenu(
                              axis: Axis.vertical,
                              actions: [
                                _noticeAction(
                                  'mail',
                                  '우편',
                                  'mail',
                                  LobbyFeature.mail,
                                ),
                                _noticeAction(
                                  'mission',
                                  '임무',
                                  'mission',
                                  LobbyFeature.mission,
                                ),
                                _noticeAction(
                                  'pass',
                                  '패스',
                                  'pass',
                                  LobbyFeature.pass,
                                ),
                                _noticeAction(
                                  'package',
                                  '보관함',
                                  'package',
                                  LobbyFeature.package,
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: railTop,
                            bottom: 150,
                            right: 4,
                            width: 70,
                            child: LobbySideMenu(
                              axis: Axis.vertical,
                              actions: [
                                LobbyMenuAction(
                                  id: 'compendium',
                                  label: '도감',
                                  iconAsset:
                                      'assets/images/ui/lobby/icon_compendium.png',
                                  onPressed: _openCompendium,
                                ),
                                LobbyMenuAction(
                                  id: 'records',
                                  label: '기록',
                                  iconAsset:
                                      'assets/images/ui/lobby/icon_records.png',
                                  onPressed: _openRecords,
                                ),
                              ],
                            ),
                          ),
                        ],
                        Positioned(
                          left: ultraWide ? null : 52,
                          right: ultraWide ? 86 : 52,
                          bottom: ultraWide ? 132 : 150,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SizedBox(
                              width: ultraWide ? 340 : 526,
                              child: MediaQuery(
                                data: MediaQuery.of(
                                  context,
                                ).copyWith(textScaler: TextScaler.noScaling),
                                child: LobbyBattleStage(
                                  characterId: character.id,
                                  characterName: character.name,
                                  stage: stage,
                                  bestSeconds: state.bestSurvivalSeconds,
                                  launching: _launching,
                                  saving: widget.controller.saving,
                                  shortLandscape: ultraWide,
                                  onDeploy: _deploy,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: ultraWide ? null : 100,
                          right: ultraWide ? 118 : null,
                          bottom: ultraWide ? 202 : 174,
                          width: ultraWide ? 276 : 280,
                          height: ultraWide ? 78 : 80,
                          child: Listener(
                            key: const Key('lobby-stage'),
                            behavior: HitTestBehavior.opaque,
                            onPointerUp: (_) => unawaited(_openStagePicker()),
                            child: const SizedBox.expand(),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 82,
                          height: 68,
                          child: Center(
                            child: LobbyQuickActions(
                              onGrowth: _openTraining,
                              onWeapon: () =>
                                  _showFeature(LobbyFeature.ranking),
                              onRelic: () => _showFeature(LobbyFeature.relic),
                              onCompanion: () =>
                                  _showFeature(LobbyFeature.companion),
                              onCrafting: () =>
                                  _showFeature(LobbyFeature.crafting),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 82,
                          child: Center(
                            child: LobbyPrimaryNavigation(
                              onLobby: () {},
                              onCharacter: _openCharacterPicker,
                              onCombat: _deploy,
                              onChallenge: () =>
                                  _showFeature(LobbyFeature.challenge),
                              onShop: _openPremiumShop,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    },
  );

  LobbyMenuAction _noticeAction(
    String id,
    String label,
    String icon,
    LobbyFeature feature,
  ) => LobbyMenuAction(
    id: id,
    label: label,
    iconAsset: 'assets/images/ui/lobby/icon_$icon.png',
    onPressed: () => _showFeature(feature),
  );

  void _showFeature(LobbyFeature feature) {
    unawaited(showLobbyFeatureNotice(context, feature));
  }
}
