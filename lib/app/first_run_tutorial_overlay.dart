import 'package:flutter/material.dart';

class FirstRunTutorialOverlay extends StatefulWidget {
  const FirstRunTutorialOverlay({required this.onCompleted, super.key});

  final VoidCallback onCompleted;

  @override
  State<FirstRunTutorialOverlay> createState() =>
      _FirstRunTutorialOverlayState();
}

class _FirstRunTutorialOverlayState extends State<FirstRunTutorialOverlay> {
  static const _steps = [
    (
      icon: Icons.sports_esports,
      title: '이동',
      description: '왼쪽 가상 스틱을 밀어 포위망을 빠져나가세요.',
    ),
    (
      icon: Icons.auto_awesome,
      title: '자동 공격',
      description: '무기는 자동으로 공격합니다. 이동과 적과의 거리 유지에 집중하세요.',
    ),
    (
      icon: Icons.diamond,
      title: '경험치',
      description: '쓰러진 적이 남긴 경험치 보석을 가까이 가서 획득하세요.',
    ),
    (
      icon: Icons.upgrade,
      title: '레벨업',
      description: '경험치가 차면 게임이 멈춥니다. 무기나 능력 하나를 선택하세요.',
    ),
    (
      icon: Icons.warning_amber_rounded,
      title: '보스 경고',
      description: '5분을 버티면 보스가 등장합니다. 화면 위 체력 막대를 확인하세요.',
    ),
  ];

  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final step = _steps[_page];
    final isLast = _page == _steps.length - 1;
    return Material(
      color: const Color(0xe6101820),
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  color: const Color(0xfff4ead2),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 22, 28, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_page + 1} / ${_steps.length}',
                          style: const TextStyle(
                            color: Color(0xff526576),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Icon(
                          step.icon,
                          size: 52,
                          color: const Color(0xff8f2d38),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          step.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, height: 1.4),
                        ),
                        const SizedBox(height: 22),
                        FilledButton(
                          key: Key(
                            isLast ? 'tutorial-finish' : 'tutorial-next',
                          ),
                          onPressed: isLast
                              ? widget.onCompleted
                              : () => setState(() => _page += 1),
                          child: Text(isLast ? '게임 시작' : '다음'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 12,
              child: TextButton(
                key: const Key('tutorial-skip'),
                onPressed: widget.onCompleted,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('건너뛰기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
