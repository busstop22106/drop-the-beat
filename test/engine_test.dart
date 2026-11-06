import 'package:drop_the_beat/engine/career.dart';
import 'package:drop_the_beat/engine/game_state.dart';
import 'package:drop_the_beat/engine/judgment.dart';
import 'package:drop_the_beat/engine/song.dart';
import 'package:drop_the_beat/engine/venue.dart';
import 'package:drop_the_beat/data/songs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('judgeTap', () {
    test('정각 탭은 Perfect', () {
      expect(judgeTap(10.0, 10.0), Judgment.perfect);
    });

    test('60ms 안쪽은 Perfect, 120ms 안쪽은 Good', () {
      expect(judgeTap(10.0, 10.059), Judgment.perfect);
      expect(judgeTap(10.0, 10.061), Judgment.good);
      expect(judgeTap(10.0, 10.119), Judgment.good);
    });

    test('120ms 밖 150ms 안쪽은 Miss, 그 밖은 none', () {
      expect(judgeTap(10.0, 10.13), Judgment.miss);
      expect(judgeTap(10.0, 10.16), Judgment.none);
    });
  });

  group('scoreFor', () {
    test('Perfect 300점 + 콤보 보너스', () {
      expect(scoreFor(Judgment.perfect, combo: 0), 300);
      expect(scoreFor(Judgment.perfect, combo: 10), 320);
    });

    test('콤보 보너스 상한 200', () {
      expect(scoreFor(Judgment.perfect, combo: 500), 500);
    });
  });

  group('GameState', () {
    test('프로토타입 곡 이벤트 56개', () {
      expect(prototypeSong.events.length, 56);
    });

    test('탭 판정 → 점수·콤보·에너지 반영', () {
      final state = GameState(prototypeSong);
      final first = state.events.first;
      final judgment = state.tap(first.timeSec);
      expect(judgment, Judgment.perfect);
      expect(state.perfectCount, 1);
      expect(state.combo, 1);
      expect(state.score, greaterThan(0));
      expect(state.heat, greaterThan(50.0));
    });

    test('기한 지난 이벤트는 자동 Miss', () {
      final state = GameState(prototypeSong);
      final missed = state.autoMiss(30.0);
      // 30초까지의 이벤트: 빌드업 20개 + 드롭 1개 + 드롭1 비트 15개 중 일부.
      expect(missed, greaterThan(20));
      expect(state.combo, 0);
      expect(state.heat, lessThan(50.0));
    });

    test('전부 Perfect면 3개 별', () {
      final state = GameState(prototypeSong);
      for (final e in state.events) {
        state.tap(e.timeSec);
      }
      expect(state.accuracy, 1.0);
      expect(state.stars, 3);
    });

    test('에너지 감소 — decay는 0 아래로 안 내려간다', () {
      final state = GameState(prototypeSong);
      state.decay(1000.0);
      expect(state.heat, 0.0);
    });

    test('텐션은 0~100으로 클램프되고 decay로 감소한다', () {
      final state = GameState(prototypeSong);
      state.addTension(150);
      expect(state.tension, 100.0);
      state.decay(1000.0);
      expect(state.tension, 0.0);
    });

    test('텐션 30 이상 드롭은 ULTRA, 미만은 소액 보상', () {
      final state = GameState(prototypeSong);
      state.addTension(50);
      final ultra = state.applyDropReward(1);
      expect(ultra.ultra, true);
      expect(ultra.cash, 155); // (80 + 50*1.5) * 1
      expect(ultra.fans, 27); // (12 + 50*0.3) * 1
      expect(state.ultraDrops, 1);
      expect(state.tension, 0.0);

      final weak = state.applyDropReward(2);
      expect(weak.ultra, false);
      expect(weak.cash, 50); // 25 * 2
      expect(weak.fans, 4); // 2 * 2
    });

    test('종료 보너스는 별 개수와 무대 배율을 따른다', () {
      final state = GameState(prototypeSong);
      for (final e in state.events) {
        state.tap(e.timeSec);
      }
      final bonus = state.applyFinishBonus(2);
      expect(state.stars, 3);
      expect(bonus.cash, 200); // 100 * 2
      expect(bonus.fans, 40); // 20 * 2
    });

    test('tapDetailed는 드롭 이벤트를 함께 반환한다', () {
      final state = GameState(prototypeSong);
      final result = state.tapDetailed(22.5);
      expect(result.judgment, Judgment.perfect);
      expect(result.event?.isDrop, true);
    });
  });

  group('Song sections', () {
    test('구간 6개, 위치별 구간 판정', () {
      expect(prototypeSong.sections.length, 6);
      expect(prototypeSong.sectionAt(0.0).label, '인트로');
      expect(prototypeSong.sectionAt(10.0).kind, SectionKind.buildup);
      expect(prototypeSong.sectionAt(30.0).kind, SectionKind.drop);
      expect(prototypeSong.sectionAt(40.0).label, '브레이크');
      expect(prototypeSong.sectionAt(67.4).label, '아웃트로');
    });
  });

  group('Venues', () {
    test('무대 4개, 배율은 1·2·4·10', () {
      expect(venues.length, 4);
      expect(venues.map((v) => v.payMultiplier).toList(), [1, 2, 4, 10]);
      expect(venues.first.crowdCount, 28);
      expect(venues.last.crowdCount, 550);
    });
  });

  group('Career', () {
    test('초기 개런티 450·팬덤 120, 보상 누적', () {
      final career = Career();
      expect(career.cash, 450);
      expect(career.fans, 120);
      career.addReward(cash: 155, fans: 27);
      expect(career.cash, 605);
      expect(career.fans, 147);
    });
  });
}
