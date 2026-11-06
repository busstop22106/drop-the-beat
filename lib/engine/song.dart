/// 순수 Dart 모델 — Flutter import 없음 (작명별 engine 규칙과 동일).
/// 곡 메타데이터와 비트맵(타이밍 이벤트) 정의.

/// 비트맵 이벤트 종류.
enum EventType {
  /// 드롭 순간 — 가장 큰 판정, 가장 큰 환호.
  drop,

  /// 빌드업 구간 비트 — 연타로 긴장감을 쌓는다.
  build,

  /// 드롭 구간 일반 비트.
  beat,

  /// 구간 전환 (브레이크다운 진입 등).
  transition,
}

/// 하나의 타이밍 이벤트. [timeSec]는 곡 시작 기준 초.
class BeatEvent {
  BeatEvent(this.timeSec, this.type);

  final double timeSec;
  final EventType type;

  /// 판정 완료 여부 (런타임 상태 — GameState가 설정한다).
  bool judged = false;

  /// 판정 완료 여부 (런타임 상태 — 모델 자체는 불변).
  bool get isDrop => type == EventType.drop;
}

/// 곡 메타데이터. 오디오는 assets 오디오 파일 + 이 메타데이터로 구동한다.
/// Suno 곡으로 교체할 때는 파일만 바꾸고 이 메타데이터의 bpm·events만
/// 다시 마킹하면 된다 (README의 'Suno 곡 교체 방법' 참조).
class SongMetadata {
  const SongMetadata({
    required this.id,
    required this.title,
    required this.artist,
    required this.bpm,
    required this.assetPath,
    required this.durationSec,
    required this.events,
  });

  final String id;
  final String title;
  final String artist;

  /// 분당 비트 수. 박자 간격 = 60 / bpm 초.
  final double bpm;

  /// assets 기준 경로. 예: 'audio/prototype_drop.mp3'
  final String assetPath;

  /// 곡 전체 길이 (초).
  final double durationSec;

  /// 시간순 정렬된 타이밍 이벤트 목록.
  final List<BeatEvent> events;

  /// 한 박자 길이 (초).
  double get beatSec => 60.0 / bpm;

  /// 한 마디(4박) 길이 (초).
  double get barSec => beatSec * 4;

  /// 곡 내 위치(초)를 박자 위상으로 변환. 0.0 = 박자 정각, 1.0에 가까울수록 다음 박자.
  double beatPhase(double positionSec) {
    final beats = positionSec / beatSec;
    return beats - beats.floorToDouble();
  }
}
