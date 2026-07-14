import 'package:flutter/material.dart';

class PauseMenuOverlay extends StatefulWidget {
  const PauseMenuOverlay({
    required this.onResume,
    required this.onRestart,
    required this.onExitToMenu,
    super.key,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onExitToMenu;

  @override
  State<PauseMenuOverlay> createState() => _PauseMenuOverlayState();
}

class _PauseMenuOverlayState extends State<PauseMenuOverlay> {
  bool _showSettings = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xdd101820),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Card(
              color: const Color(0xfff4ead2),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _showSettings ? _buildSettings() : _buildMenu(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenu() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '일시정지',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('pause-resume'),
          onPressed: widget.onResume,
          child: const Text('계속하기'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          key: const Key('pause-restart'),
          onPressed: widget.onRestart,
          child: const Text('다시 시작'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          key: const Key('pause-settings'),
          onPressed: () => setState(() => _showSettings = true),
          child: const Text('설정'),
        ),
        const SizedBox(height: 10),
        TextButton(
          key: const Key('pause-menu'),
          onPressed: widget.onExitToMenu,
          child: const Text('메인 메뉴'),
        ),
      ],
    );
  }

  Widget _buildSettings() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '설정',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 20),
        const Text(
          '정식 설정은 META-004 단계에서 음량과 진동 옵션을 저장하도록 연결됩니다.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        FilledButton.tonal(
          key: const Key('pause-settings-back'),
          onPressed: () => setState(() => _showSettings = false),
          child: const Text('돌아가기'),
        ),
      ],
    );
  }
}
