const moonlitAbandonedOffice = 'moonlit_abandoned_office';
const plagueMarket = 'plague_market';

enum StageVisualTheme { moonlit, plague }

class StageDefinition {
  const StageDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.targetSeconds,
    required this.bossArrivalSeconds,
    required this.visualTheme,
    required this.backgroundColorValue,
    required this.riskLabel,
    required this.presentationImageKey,
  });

  final String id;
  final String name;
  final String description;
  final int targetSeconds;
  final int bossArrivalSeconds;
  final StageVisualTheme visualTheme;
  final int backgroundColorValue;
  final String riskLabel;
  final String presentationImageKey;
}

const stageDefinitions = <StageDefinition>[
  StageDefinition(
    id: moonlitAbandonedOffice,
    name: '달빛 폐관아',
    description: '원혼과 요괴가 뒤엉킨 버려진 관아에서 살아남으세요.',
    targetSeconds: 300,
    bossArrivalSeconds: 270,
    presentationImageKey: 'moonlit_abandoned_office_presentation',
    visualTheme: StageVisualTheme.moonlit,
    backgroundColorValue: 0xff1d3344,
    riskLabel: '표준',
  ),
  StageDefinition(
    id: plagueMarket,
    name: '역병 장터',
    description: '독기와 역병 괴물이 가득한 장터에서 거센 물량을 돌파하세요.',
    targetSeconds: 300,
    bossArrivalSeconds: 270,
    presentationImageKey: 'plague_market_presentation',
    visualTheme: StageVisualTheme.plague,
    backgroundColorValue: 0xff3f4930,
    riskLabel: '위험',
  ),
];

StageDefinition stageDefinitionFor(String stageId) =>
    stageDefinitions.firstWhere(
      (stage) => stage.id == stageId,
      orElse: () => stageDefinitions.first,
    );
