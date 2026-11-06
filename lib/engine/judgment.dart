/// 순수 Dart 판정 로직 — Flutter import 없음.
/// 탭 시각과 이벤트 시각의 차이만으로 판정한다.

/// 판정 등급.
enum Judgment {
  perfect,
  good,
  miss,

  /// 탭이 어떤 이벤트의 판정 창에도 들어오지 않음 (헛탭 — 감점 없음).
  none,
}

/// 판정 창 (초). 리듬 게임 기준으로는 관대한 편 — 프로토타입은
/// "맞췄을 때의 희열"을 먼저 느끼게 하는 것이 목적이다.
/// 실기기에서 타이밍이 어긋나 보이면 AudioEngine의 보정값부터 조정할 것.
class JudgmentWindows {
  const JudgmentWindows._();

  /// Perfect 허용 오차 (±60ms).
  static const double perfect = 0.06;

  /// Good 허용 오차 (±120ms).
  static const double good = 0.12;

  /// 이 범위를 벗어난 탭은 헛탭으로 취급한다 (±150ms).
  static const double hit = 0.15;
}

/// 탭 시각([tapSec])과 이벤트 시각([eventSec])의 차이로 판정한다.
Judgment judgeTap(double eventSec, double tapSec) {
  final diff = (tapSec - eventSec).abs();
  if (diff <= JudgmentWindows.perfect) return Judgment.perfect;
  if (diff <= JudgmentWindows.good) return Judgment.good;
  if (diff <= JudgmentWindows.hit) return Judgment.miss;
  return Judgment.none;
}

/// 판정별 점수.
int scoreFor(Judgment judgment, {required int combo}) {
  // 콤보 보너스: 콤보 1당 +2, 최대 +200.
  final bonus = combo * 2 > 200 ? 200 : combo * 2;
  switch (judgment) {
    case Judgment.perfect:
      return 300 + bonus;
    case Judgment.good:
      return 100 + bonus;
    case Judgment.miss:
    case Judgment.none:
      return 0;
  }
}
