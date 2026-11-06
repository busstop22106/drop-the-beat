import 'package:drop_the_beat/engine/game_state.dart';
import 'package:drop_the_beat/engine/judgment.dart';
import 'package:drop_the_beat/engine/song.dart';
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
  });
}
