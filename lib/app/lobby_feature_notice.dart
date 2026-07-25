import 'package:flutter/material.dart';

enum LobbyFeature {
  mail,
  mission,
  pass,
  package,
  ranking,
  relic,
  companion,
  crafting,
  challenge,
}

class LobbyFeatureNoticeCopy {
  const LobbyFeatureNoticeCopy({required this.title, required this.body});

  final String title;
  final String body;
}

LobbyFeatureNoticeCopy copyForLobbyFeature(LobbyFeature feature) {
  return switch (feature) {
    LobbyFeature.mail => const LobbyFeatureNoticeCopy(
      title: '전령의 소식',
      body: '전령이 새로운 소식을 모으고 있습니다.',
    ),
    LobbyFeature.mission => const LobbyFeatureNoticeCopy(
      title: '임무서',
      body: '관아에서 오늘의 임무서를 정리하고 있습니다.',
    ),
    LobbyFeature.pass => const LobbyFeatureNoticeCopy(
      title: '승급 준비',
      body: '새 승급 보상이 도착할 때까지 잠시 기다려 주십시오.',
    ),
    LobbyFeature.package => const LobbyFeatureNoticeCopy(
      title: '보급품',
      body: '상단이 새로운 보급품을 들여오고 있습니다.',
    ),
    LobbyFeature.ranking => const LobbyFeatureNoticeCopy(
      title: '무예 명부',
      body: '전국의 무예 기록을 한데 모으고 있습니다.',
    ),
    LobbyFeature.relic => const LobbyFeatureNoticeCopy(
      title: '봉인된 유물',
      body: '감정이 끝난 유물부터 차례로 공개됩니다.',
    ),
    LobbyFeature.companion => const LobbyFeatureNoticeCopy(
      title: '인연',
      body: '함께 싸울 인연을 찾고 있습니다.',
    ),
    LobbyFeature.crafting => const LobbyFeatureNoticeCopy(
      title: '대장간',
      body: '대장간의 화로를 달구고 있습니다.',
    ),
    LobbyFeature.challenge => const LobbyFeatureNoticeCopy(
      title: '봉인된 시련',
      body: '봉인된 시련의 문이 아직 열리지 않았습니다.',
    ),
  };
}

Future<void> showLobbyFeatureNotice(
  BuildContext context,
  LobbyFeature feature,
) {
  final copy = copyForLobbyFeature(feature);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '기능 안내 닫기',
    barrierColor: const Color(0xA6000000),
    transitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (dialogContext, _, __) => _LobbyFeatureNotice(copy: copy),
    transitionBuilder: (dialogContext, animation, _, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          alignment: Alignment.center,
          scale: Tween<double>(begin: 0.96, end: 1).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      );
    },
  );
}

class _LobbyFeatureNotice extends StatelessWidget {
  const _LobbyFeatureNotice({required this.copy});

  final LobbyFeatureNoticeCopy copy;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        container: true,
        label: '${copy.title} 안내',
        child: SizedBox(
          key: const Key('lobby-feature-notice'),
          width: 360,
          height: 248,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ExcludeSemantics(
                child: Image.asset(
                  'assets/images/ui/lobby/frame_feature_notice.png',
                  fit: BoxFit.fill,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(44, 48, 44, 34),
                child: Column(
                  children: [
                    Text(
                      copy.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xff3b2718),
                        fontFamily: 'GowunBatang',
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Text(
                        copy.body,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xff4d3826),
                          fontFamily: 'GowunBatang',
                          fontSize: 16,
                          height: 1.45,
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: '${copy.title} 안내 확인',
                      child: GestureDetector(
                        key: const Key('lobby-feature-notice-confirm'),
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          alignment: Alignment.center,
                          width: 112,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xff3b2718),
                            border: Border.all(color: const Color(0xffc7a65a)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '확인',
                            style: TextStyle(
                              color: Color(0xfffff5d6),
                              fontFamily: 'GowunBatang',
                              fontWeight: FontWeight.w700,
                            ),
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
      ),
    );
  }
}
