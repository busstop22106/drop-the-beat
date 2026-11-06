import 'dart:async';

import 'package:flutter/material.dart';

import '../engine/game_state.dart';
import '../engine/judgment.dart';
import '../engine/song.dart';
import '../services/audio_engine.dart';
import '../theme/app_theme.dart';
import '../widgets/beat_track.dart';
import '../widgets/crowd_canvas.dart';
import '../widgets/heat_gauge.dart';
import 'result_screen.dart';

/// 공연 화면 — 게임의 핵심.
/// 33ms마다 타이머가 돌면서 곡 위치를 읽고, 지나간 이벤트를 자동 Miss 처리하고,
/// 관객 에너지 자연 감소·환호 감쇠를 적용한다.
/// 탭은 큰 DROP 패드(또는 비트 트랙)를 누르면 판정한다.
class GameScreen extends StatefulWidget {
  const GameScreen({
    required this.song,
    required this.calibrationOffsetMs,
    super.key,
  });

  final SongMetadata song;
  final int calibrationOffsetMs;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameState _state;
  final AudioEngine _audio = AudioEngine();

  Timer? _tickTimer;
  Timer? _countdownTimer;

  /// 현재 곡 위치 (초).
  double _positionSec = 0.0;

  /// 환호 강도 0.0~1.0. 드롭 Perfect 직후 1.0이 되었다가 식는다.
  double _cheer = 0.0;

  /// 마지막 판정 표시용.
  Judgment _lastJudgment = Judgment.none;
  DateTime _lastJudgmentAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// 카운트다운 3·2·1·0(시작).
  int _countdown = 3;
  bool _started = false;
  bool _finished = false;
  DateTime _lastTick = DateTime.now();

  @override
  void initState() {
    super.initState();
    _state = GameState(widget.song);
    _audio.calibrationOffsetMs = widget.calibrationOffsetMs;
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 500), (t) {
      if (!mounted) return;
      setState(() {
        _countdown--;
        if (_countdown <= 0) {
          t.cancel();
          _startGame();
        }
      });
    });
  }

  Future<void> _startGame() async {
    final ok = await _audio.play(widget.song.assetPath);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('오디오 파일이 없어 무음으로 진행해요. '
              'assets/audio/prototype_drop.mp3 파일을 넣어주세요.'),
          duration: Duration(seconds: 4),
        ),
      );
    }
    setState(() => _started = true);
    _lastTick = DateTime.now();
    _tickTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (!mounted || _finished) return;
      final now = DateTime.now();
      final dt = now.difference(_lastTick).inMilliseconds / 1000.0;
      _lastTick = now;
      final pos = _audio.position.inMilliseconds / 1000.0;
      setState(() {
        _positionSec = pos;
        _state.autoMiss(pos);
        _state.decay(dt);
        _cheer = (_cheer - dt * 1.2).clamp(0.0, 1.0);
        if (pos >= widget.song.durationSec) _finish();
      });
    });
  }

  void _onTap() {
    if (!_started || _finished) return;
    final judgment = _state.tap(_positionSec);
    if (judgment == Judgment.none) return;
    setState(() {
      _lastJudgment = judgment;
      _lastJudgmentAt = DateTime.now();
      if (judgment == Judgment.perfect) {
        _cheer = 1.0;
      } else if (judgment == Judgment.good) {
        _cheer = (_cheer + 0.3).clamp(0.0, 1.0);
      }
    });
  }

  Future<void> _finish() async {
    if (_finished) return;
    _finished = true;
    _tickTimer?.cancel();
    await _audio.stop();
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          result: GameResult.fromState(_state),
          song: widget.song,
          calibrationOffsetMs: widget.calibrationOffsetMs,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _tickTimer?.cancel();
    _audio.dispose();
    super.dispose();
  }

  String get _judgmentText => switch (_lastJudgment) {
        Judgment.perfect => 'PERFECT!',
        Judgment.good => 'GOOD',
        Judgment.miss => 'MISS',
        Judgment.none => '',
      };

  Color get _judgmentColor => switch (_lastJudgment) {
        Judgment.perfect => AppTheme.neonPink,
        Judgment.good => AppTheme.neonCyan,
        Judgment.miss => AppTheme.textMuted,
        Judgment.none => Colors.transparent,
      };

  @override
  Widget build(BuildContext context) {
    final showJudgment = _started &&
        _lastJudgment != Judgment.none &&
        DateTime.now().difference(_lastJudgmentAt).inMilliseconds < 450;
    final progress =
        (_positionSec / widget.song.durationSec).clamp(0.0, 1.0);
    final remainSec =
        (widget.song.durationSec - _positionSec).clamp(0.0, double.infinity);
    final remain = remainSec.ceil();
    final remainText =
        '${remain ~/ 60}:${(remain % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // 상단: 점수 · 콤보 · 남은 시간.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('점수',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textMuted)),
                      Text(
                        '${_state.score}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (_state.combo >= 2)
                    Text(
                      '${_state.combo} 콤보',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.neonYellow,
                      ),
                    ),
                  Text(
                    remainText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            // 관객 에너지 게이지.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: HeatGauge(heat: _state.heat),
            ),
            // 비트 트랙 (탭 가능).
            GestureDetector(
              onTapDown: (_) => _onTap(),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  height: 92,
                  child: BeatTrack(
                    song: widget.song,
                    events: _state.events,
                    positionSec: _positionSec,
                  ),
                ),
              ),
            ),
            // 관객석.
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CrowdCanvas(
                      heat: _state.heat,
                      beatPhase: widget.song.beatPhase(_positionSec),
                      cheer: _cheer,
                    ),
                  ),
                  if (showJudgment)
                    Center(
                      child: Text(
                        _judgmentText,
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: _judgmentColor,
                          shadows: const [
                            Shadow(
                                blurRadius: 18,
                                color: Colors.black54,
                                offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                    ),
                  if (!_started)
                    Container(
                      color: Colors.black54,
                      child: Center(
                        child: Text(
                          '$_countdown',
                          style: const TextStyle(
                            fontSize: 96,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // DROP 패드.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: GestureDetector(
                onTapDown: (_) => _onTap(),
                child: Container(
                  height: 108,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [AppTheme.neonPink, AppTheme.neonPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.neonPink.withValues(alpha: 0.45),
                        blurRadius: 24,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'DROP!',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(
                '드롭·비트에 맞춰 탭하세요',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ),
            // 곡 진행 바.
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.surfaceLight,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.neonPink),
              minHeight: 4,
            ),
          ],
        ),
      ),
    );
  }
}
