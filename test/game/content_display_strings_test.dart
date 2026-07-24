import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/stage_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';

void main() {
  test('player-facing content keeps canonical Korean copy', () {
    expect(characterDefinitions.map((item) => item.name), [
      '신참 포졸',
      '퇴마 도사',
      '산길 사냥꾼',
    ]);
    expect(
      characterDefinitions.map(
        (item) =>
            (name: item.passiveName, description: item.passiveDescription),
      ),
      [
        (name: '순라의 끈기', description: '접촉 피해 -12%'),
        (name: '퇴마 서법', description: '마법 무기 피해 +15%'),
        (name: '매의 눈', description: '치명타 확률 +10%p'),
      ],
    );
    expect(weaponDefinitions.map((item) => item.name), [
      '환도 베기',
      '각궁 사격',
      '부적 투척',
      '벽력진천뢰',
      '장승 결계',
      '신기전 일제사격',
      '서리 호리병',
      '풍뢰 부채',
      '조총·화포',
      '무당 방울',
      '도깨비 쇠사슬',
      '매 부름',
    ]);
    expect(stageDefinitions.map((item) => item.name), ['달빛 폐관아', '역병 장터']);
    expect(stageDefinitions.map((item) => item.description), [
      '원혼과 요괴가 뒤엉킨 버려진 관아에서 살아남으세요.',
      '독기와 역병 괴물이 가득한 장터에서 거센 물량을 돌파하세요.',
    ]);
    expect(stageDefinitions.map((item) => item.riskLabel), ['표준', '위험']);
  });
}
