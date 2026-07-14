abstract final class AppStrings {
  static const appTitle = '조선 왕조 서바이벌';
  static const prepareRun = '출진 준비';
  static const loading = '불러오는 중...';
  static const levelUp = '레벨 업';

  static const hudTime = '시간';
  static const hudHealth = '체력';
  static const hudLevel = '레벨';
  static const hudExperience = '경험치';
  static const hudEnemies = '적';
  static const hudKills = '처치';
  static const genericBoss = '보스';

  static const victory = '승리';
  static const defeat = '패배';
  static const bossDefeated = '보스 처치';
  static const bossNotDefeated = '보스 미처치';
  static const survivalTime = '생존 시간';
  static const killCount = '처치 수';
  static const reachedLevel = '도달 레벨';
  static const weaponPerformance = '무기 성과';
  static const newUnlocks = '새로운 해금';
  static const noNewUnlocks = '이번 판에서 새로 해금된 항목이 없습니다.';
  static const character = '캐릭터';
  static const weapon = '무기';
  static const augment = '증강';
  static const copyRunRecord = '이 판 기록 복사';
  static const exportAllRecords = '전체 기록 내보내기';
  static const retry = '다시 시작';
  static const mainMenu = '메인 메뉴';

  static String levelRange({required int current, required int next}) =>
      '레벨 $current → $next';

  static String weaponMetric({
    required int level,
    required int damage,
    required int kills,
  }) => '레벨 $level · 피해 $damage · 처치 $kills';
}
