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
import '../game/systems/tutorial_progress_repository.dart';
import '../game/systems/playtest_session_repository.dart';
import 'account_section.dart';
import 'character_select_screen.dart';
import 'compendium_screen.dart';
import 'game_screen.dart';
import 'lobby_battle_stage.dart';
import 'lobby_controller.dart';
import 'lobby_navigation_dock.dart';
import 'lobby_top_command_bar.dart';
import 'joseon_ui_theme.dart';
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

  Widget _premiumEntry() {
    final purchases = widget.purchaseController;
    if (purchases != null) {
      return AnimatedBuilder(
        animation: purchases,
        builder: (context, _) => ActionChip(
          key: const Key('lobby-premium-shop'),
          visualDensity: VisualDensity.compact,
          label: Text(
            purchases.state.walletStale
                ? '금옥 --'
                : '금옥 ${purchases.state.wallet?.balance ?? 0}',
            style: const TextStyle(fontFamily: JoseonUiTheme.bodyFontFamily),
          ),
          onPressed: _openPremiumShop,
        ),
      );
    }
    if (widget.onPurchaseInitializationRetry != null) {
      return ActionChip(
        key: const Key('lobby-premium-shop-retry'),
        visualDensity: VisualDensity.compact,
        label: const Text(
          '금옥 재시도',
          style: TextStyle(fontFamily: JoseonUiTheme.bodyFontFamily),
        ),
        onPressed: _openPremiumShop,
      );
    }
    return const SizedBox.shrink();
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
          backgroundColor: const Color(0xffd99535),
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xfff3c466), Color(0xffc96c2f)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: KeyedSubtree(
                      key: const Key('lobby-resource-bar'),
                      child: LobbyTopCommandBar(
                        coin: state.wallet.coin,
                        spiritJade: state.wallet.spiritJade,
                        premiumEntry: _premiumEntry(),
                        onSettings: _openSettings,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final battleStage = LobbyBattleStage(
                          characterId: character.id,
                          characterName: character.name,
                          stage: stage,
                          bestSeconds: state.bestSurvivalSeconds,
                          launching: _launching,
                          saving: widget.controller.saving,
                          onDeploy: _deploy,
                        );
                        final usesWideStage = constraints.maxWidth > 600;
                        return SingleChildScrollView(
                          key: const Key('lobby-center-scroll'),
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight - 14,
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 720,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (widget.accountController
                                        case final account?) ...[
                                      AccountSection(
                                        controller: account,
                                        syncLabel: widget
                                            .progressSyncController
                                            ?.status
                                            .label,
                                        onSyncNow: widget.controller.syncNow,
                                        syncListenable:
                                            widget.progressSyncController,
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                    if (usesWideStage)
                                      SizedBox(
                                        height: constraints.maxHeight - 14,
                                        child: battleStage,
                                      )
                                    else
                                      battleStage,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    height: 93,
                    child: KeyedSubtree(
                      key: const Key('lobby-bottom-menu'),
                      child: LobbyNavigationDock(
                        key: const Key('lobby-navigation-dock'),
                        onStagePressed: _openStagePicker,
                        onCharacterPressed: _openCharacterPicker,
                        onCompendiumPressed: _openCompendium,
                        onRecordsPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => RecordsScreen(state: state),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
