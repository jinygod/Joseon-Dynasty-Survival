import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../game/systems/tutorial_progress_repository.dart';
import 'character_select_screen.dart';
import 'game_screen.dart';
import 'stage_select_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({this.tutorialProgressRepository, super.key});

  final TutorialProgressRepository? tutorialProgressRepository;

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  bool _launching = false;

  Future<void> _startRun() async {
    if (_launching) return;
    setState(() => _launching = true);
    final repository =
        widget.tutorialProgressRepository ?? TutorialProgressRepository();
    var showTutorial = true;
    try {
      showTutorial = !await repository.isCompleted();
    } on Object {
      showTutorial = true;
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (selectionContext) => CharacterSelectScreen(
          onStart: (slot) {
            Navigator.of(selectionContext).push(
              MaterialPageRoute<void>(
                builder: (stageContext) => StageSelectScreen(
                  onStart: (stageId) {
                    Navigator.of(stageContext).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => GameScreen(
                          playerSlot: slot,
                          stageId: stageId,
                          showFirstRunTutorial: showTutorial,
                          tutorialProgressRepository: repository,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
    if (mounted) setState(() => _launching = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(AppStrings.appTitle, style: TextStyle(fontSize: 32)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _launching ? null : _startRun,
                child: Text(
                  _launching ? AppStrings.loading : AppStrings.prepareRun,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
