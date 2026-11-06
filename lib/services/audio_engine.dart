import 'package:audioplayers/audioplayers.dart';

/// 오디오 재생 + 곡 위치 시계.
/// 리듬 게임의 판정은 이 시계를 기준으로 한다.
///
/// 동작 방식: 재생 시작과 동시에 Stopwatch를 돌리고, audioplayers의
/// onPositionChanged가 들어올 때마다 실제 오디오 위치로 시계를 다시 맞춘다.
/// 이렇게 하면 위치 스트림의 갱신 간격(약 200ms) 사이에서도
/// 부드럽고 단조 증가하는 위치를 얻을 수 있다.
///
/// 실기기에서 소리와 화면 타이밍이 어긋나 보이면
/// [calibrationOffsetMs]를 조정한다 (홈 화면 슬라이더).
class AudioEngine {
  AudioEngine() {
    _player.onPositionChanged.listen((p) {
      _anchorPosition = p;
      _anchorElapsed = _clock.elapsed;
    });
  }

  final AudioPlayer _player = AudioPlayer();
  final Stopwatch _clock = Stopwatch();

  Duration _anchorPosition = Duration.zero;
  Duration _anchorElapsed = Duration.zero;

  /// 타이밍 보정값 (밀리초).
  /// 양수면 판정 시각이 늦춰진다 = 소리가 화면보다 늦게 들릴 때 +방향.
  int calibrationOffsetMs = 0;

  bool get isPlaying => _clock.isRunning;

  /// 현재 곡 위치. 재생 중이 아니면 마지막으로 동기화된 위치.
  Duration get position {
    if (!_clock.isRunning) return _anchorPosition;
    final elapsed = _clock.elapsed - _anchorElapsed;
    var pos = _anchorPosition + elapsed;
    pos += Duration(milliseconds: calibrationOffsetMs);
    return pos.isNegative ? Duration.zero : pos;
  }

  /// 재생 시작. 성공하면 true.
  /// 오디오 파일이 없으면(assets에 MP3를 안 넣었으면) false를 반환하고
  /// 게임은 무음으로도 진행할 수 있다.
  Future<bool> play(String assetPath) async {
    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.stop);
      _anchorPosition = Duration.zero;
      _anchorElapsed = Duration.zero;
      _clock.reset();
      await _player.play(AssetSource(assetPath));
      _clock.start();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stop() async {
    _clock.stop();
    await _player.stop();
  }

  void dispose() {
    _clock.stop();
    _player.dispose();
  }
}
