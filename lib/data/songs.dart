import '../engine/song.dart';

/// 프로토타입 곡 1곡. 실제 오디오는 tools/make_track.py로 합성한
/// assets/audio/prototype_drop.mp3 (128 BPM, 67.5초)이다.
/// 곡 구조와 이벤트 시각은 합성 스크립트와 동일한 마디 지도를 쓴다:
///
/// | 구간        | 마디   | 시간(초)      |
/// |-------------|--------|---------------|
/// | 인트로      | 1–4    | 0.0–7.5       |
/// | 빌드업      | 5–12   | 7.5–22.5      |
/// | 드롭 1      | 13–20  | 22.5–37.5     |
/// | 브레이크다운| 21–24  | 37.5–45.0     |
/// | 드롭 2      | 25–32  | 45.0–60.0     |
/// | 아웃트로    | 33–36  | 60.0–67.5     |
///
/// Suno 곡으로 교체할 때는 이 파일에 새 곡 메타데이터를 추가하고
/// events만 새로 마킹하면 된다 (README 참조).

SongMetadata get prototypeSong => SongMetadata(
      id: 'prototype-drop',
      title: 'Midnight Drop',
      artist: 'DROP THE BEAT · 프로토타입',
      bpm: 128,
      assetPath: 'audio/prototype_drop.mp3',
      durationSec: 67.5,
      events: _buildPrototypeEvents(),
      sections: const [
        SongSection(
            label: '인트로', startSec: 0.0, endSec: 7.5, kind: SectionKind.groove),
        SongSection(
            label: '빌드업', startSec: 7.5, endSec: 22.5, kind: SectionKind.buildup),
        SongSection(
            label: '드롭 1', startSec: 22.5, endSec: 37.5, kind: SectionKind.drop),
        SongSection(
            label: '브레이크', startSec: 37.5, endSec: 45.0, kind: SectionKind.groove),
        SongSection(
            label: '드롭 2', startSec: 45.0, endSec: 60.0, kind: SectionKind.drop),
        SongSection(
            label: '아웃트로', startSec: 60.0, endSec: 67.5, kind: SectionKind.groove),
      ],
    );

List<BeatEvent> _buildPrototypeEvents() {
  const beat = 60.0 / 128; // 한 박자 = 0.46875초
  const bar = beat * 4; // 한 마디 = 1.875초
  final events = <BeatEvent>[];

  // 빌드업 (7.5~22.5초): 앞 4마디는 마디 시작만, 뒤 4마디는 매 박자 연타.
  for (var i = 0; i < 4; i++) {
    events.add(BeatEvent(7.5 + i * bar, EventType.build));
  }
  for (var i = 0; i < 16; i++) {
    events.add(BeatEvent(15.0 + i * beat, EventType.build));
  }

  // 드롭 1 (22.5~37.5초): 드롭 + 각 마디 1·3박.
  events.add(BeatEvent(22.5, EventType.drop));
  for (var b = 0; b < 8; b++) {
    final base = 22.5 + b * bar;
    if (b > 0) events.add(BeatEvent(base, EventType.beat));
    events.add(BeatEvent(base + beat * 2, EventType.beat));
  }

  // 브레이크다운 (37.5~45초): 전환 + 마디 시작.
  events.add(BeatEvent(37.5, EventType.transition));
  for (var i = 1; i < 4; i++) {
    events.add(BeatEvent(37.5 + i * bar, EventType.beat));
  }

  // 드롭 2 (45~60초): 드롭 1과 동일 패턴.
  events.add(BeatEvent(45.0, EventType.drop));
  for (var b = 0; b < 8; b++) {
    final base = 45.0 + b * bar;
    if (b > 0) events.add(BeatEvent(base, EventType.beat));
    events.add(BeatEvent(base + beat * 2, EventType.beat));
  }

  events.sort((a, b) => a.timeSec.compareTo(b.timeSec));
  return events;
}
