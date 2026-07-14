const moonlitAbandonedOffice = 'moonlit_abandoned_office';

class StageDefinition {
  const StageDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.targetSeconds,
    required this.bossArrivalSeconds,
  });

  final String id;
  final String name;
  final String description;
  final int targetSeconds;
  final int bossArrivalSeconds;
}

const stageDefinitions = <StageDefinition>[
  StageDefinition(
    id: moonlitAbandonedOffice,
    name: '달빛 폐관아',
    description: '역병과 요괴가 뒤엉킨 버려진 관아에서 살아남으세요.',
    targetSeconds: 300,
    bossArrivalSeconds: 270,
  ),
];
