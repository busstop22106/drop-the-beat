import 'dart:math' as math;

import 'judgment.dart';
import 'song.dart';

/// 순수 Dart 게임 상태 — Flutter import 없음.
/// 관객 에너지(Heat)·콤보·점수·판정 집계를 담당한다.
/// UI는 이 상태를 읽어서 그리기만 한다.

class GameState {
  GameState(this.song)
      : _events =
            song.events.map((e) => BeatEvent(e.timeSec, e.type)).toList();

  final SongMetadata song;

  /// 관객 에너지 0~100. 50에서 시작한다.
  double heat = 50.0;

  /// 빌드업 응축도(텐션) 0~100. 필터·루프 롤·FX로 쌓고 드롭에서 소모한다.
  double tension = 0.0;

  /// 이번 공연에서 번 개런티·팬덤 (무대 배율 적용 후).
  int cashEarned = 0;
  int fansEarned = 0;

  /// 텐션을 충분히 모은 채 성공한 드롭 횟수.
  int ultraDrops = 0;

  int combo = 0;
  int maxCombo = 0;
  int score = 0;

  int perfectCount = 0;
  int goodCount = 0;
  int missCount = 0;

  /// 판정된 이벤트 수.
  int get judgedCount => perfectCount + goodCount + missCount;

  /// 전체 이벤트 수.
  int get totalEvents => _events.length;

  /// 판정 상태를 포함한 이벤트 목록 (읽기 전용).
  List<BeatEvent> get events => List.unmodifiable(_events);

  /// 정확도 0.0~1.0 (Perfect 1.0, Good 0.5로 계산).
  double get accuracy {
    if (totalEvents == 0) return 1.0;
    return (perfectCount + goodCount * 0.5) / totalEvents;
  }

  /// 별 1~3개. 0.95 이상 3개, 0.80 이상 2개.
  int get stars => accuracy >= 0.95 ? 3 : (accuracy >= 0.80 ? 2 : 1);

  /// 아직 판정되지 않은 이벤트 목록 (시간순).
  final List<BeatEvent> _events;

  /// 곡 위치([positionSec]) 기준으로 판정 기한이 지난 이벤트를 자동 Miss 처리한다.
  /// 기한 = 이벤트 시각 + Good 창(0.12초) + 여유(0.03초).
  /// 반환값: 이번 호출에서 새로 Miss 처리된 이벤트 수.
  int autoMiss(double positionSec) {
    var missed = 0;
    for (final event in _events) {
      if (event.judged) continue;
      if (positionSec > event.timeSec + JudgmentWindows.good + 0.03) {
        _markJudged(event, Judgment.miss);
        missed++;
      }
    }
    return missed;
  }

  /// 탭 시각([tapSec])에 가장 가까운 미판정 이벤트를 찾아 판정한다.
  /// 판정 창 밖이면 [Judgment.none]을 반환하고 아무것도 바꾸지 않는다.
  Judgment tap(double tapSec) => tapDetailed(tapSec).judgment;

  /// [tap]과 같지만 판정된 이벤트도 함께 반환한다.
  /// 드롭 이벤트인지 확인해 보상·피버를 걸 때 쓴다.
  ({Judgment judgment, BeatEvent? event}) tapDetailed(double tapSec) {
    BeatEvent? nearest;
    var nearestDiff = double.infinity;
    for (final event in _events) {
      if (event.judged) continue;
      final diff = (tapSec - event.timeSec).abs();
      if (diff < nearestDiff) {
        nearestDiff = diff;
        nearest = event;
      }
    }
    if (nearest == null) return (judgment: Judgment.none, event: null);
    final judgment = judgeTap(nearest.timeSec, tapSec);
    if (judgment == Judgment.none) {
      return (judgment: Judgment.none, event: null);
    }
    _markJudged(nearest, judgment);
    return (judgment: judgment, event: nearest);
  }

  /// 시간 경과에 따른 에너지 자연 감소. [dtSec]는 경과 초.
  /// 이벤트가 없을 때도 관객은 서서히 식는다.
  void decay(double dtSec) {
    heat = math.max(0.0, heat - 2.0 * dtSec);
    tension = math.max(0.0, tension - 2.0 * dtSec);
  }

  /// 텐션을 쌓는다. 0~100으로 클램프.
  void addTension(double amount) {
    tension = (tension + amount).clamp(0.0, 100.0);
  }

  /// 드롭 탭의 보상. [multiplier]는 무대 개런티 배율.
  /// 텐션 30 이상이면 ULTRA DROP: 텐션 비례 보너스 + 카운트.
  /// 텐션이 낮으면 소액 보상만. 어느 쪽이든 텐션은 소모된다.
  ({int cash, int fans, bool ultra}) applyDropReward(int multiplier) {
    final ultra = tension >= 30.0;
    final cash = ultra
        ? ((80 + tension * 1.5) * multiplier).round()
        : 25 * multiplier;
    final fans = ultra
        ? ((12 + tension * 0.3) * multiplier).round()
        : 2 * multiplier;
    cashEarned += cash;
    fansEarned += fans;
    if (ultra) ultraDrops++;
    tension = 0.0;
    return (cash: cash, fans: fans, ultra: ultra);
  }

  /// 곡 종료 보너스. 별 개수에 따라 무대 배율을 곱해 지급한다.
  ({int cash, int fans}) applyFinishBonus(int multiplier) {
    final cash = switch (stars) {
      3 => 100 * multiplier,
      2 => 50 * multiplier,
      _ => 20 * multiplier,
    };
    final fans = switch (stars) {
      3 => 20 * multiplier,
      2 => 10 * multiplier,
      _ => 5 * multiplier,
    };
    cashEarned += cash;
    fansEarned += fans;
    return (cash: cash, fans: fans);
  }

  void _markJudged(BeatEvent event, Judgment judgment) {
    event.judged = true;
    switch (judgment) {
      case Judgment.perfect:
        perfectCount++;
        combo++;
        score += scoreFor(judgment, combo: combo);
        // 드롭 Perfect는 두 배로 뜨겁다.
        heat = math.min(100.0, heat + (event.isDrop ? 8.0 : 4.0));
      case Judgment.good:
        goodCount++;
        combo++;
        score += scoreFor(judgment, combo: combo);
        heat = math.min(100.0, heat + (event.isDrop ? 4.0 : 2.0));
      case Judgment.miss:
        missCount++;
        combo = 0;
        heat = math.max(0.0, heat - (event.isDrop ? 12.0 : 6.0));
      case Judgment.none:
        break;
    }
    if (combo > maxCombo) maxCombo = combo;
  }
}

/// 결과 화면에 넘길 집계 결과.
class GameResult {
  const GameResult({
    required this.score,
    required this.maxCombo,
    required this.perfectCount,
    required this.goodCount,
    required this.missCount,
    required this.accuracy,
    required this.stars,
    required this.cashEarned,
    required this.fansEarned,
    required this.ultraDrops,
  });

  factory GameResult.fromState(GameState state) => GameResult(
        score: state.score,
        maxCombo: state.maxCombo,
        perfectCount: state.perfectCount,
        goodCount: state.goodCount,
        missCount: state.missCount,
        accuracy: state.accuracy,
        stars: state.stars,
        cashEarned: state.cashEarned,
        fansEarned: state.fansEarned,
        ultraDrops: state.ultraDrops,
      );

  final int score;
  final int maxCombo;
  final int perfectCount;
  final int goodCount;
  final int missCount;
  final double accuracy;
  final int stars;
  final int cashEarned;
  final int fansEarned;
  final int ultraDrops;
}
