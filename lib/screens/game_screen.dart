import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../engine/game_state.dart';
import '../engine/judgment.dart';
import '../engine/song.dart';
import '../engine/venue.dart';
import '../services/audio_engine.dart';
import '../theme/app_theme.dart';
import '../widgets/beat_track.dart';
import '../widgets/crowd_canvas.dart';
import '../widgets/deck_controls.dart';
import '../widgets/heat_gauge.dart';
import 'result_screen.dart';

/// 공연 화면 — 게임의 핵심.
/// 타이밍 판정(비트 트랙 + DROP 패드)은 v0.1 그대로 유지하고,
/// 그 위에 제미나이 DJ HYPE의 스테이지·덱·텐션·피버를 얹었다.
/// 33ms마다 타이머가 돌면서 곡 위치·비트 펄스·피버·파티클을 갱신한다.
class GameScreen extends StatefulWidget {
  const GameScreen({
    required this.song,
    required this.venue,
    required this.calibrationOffsetMs,
    super.key,
  });

  final SongMetadata song;
  final Venue venue;
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

  /// 스테이지 애니메이션용 경과 시간 (초).
  double _animSec = 0.0;

  /// 박자 펄스 0.0~1.0. 박자 정각에 1.0이 되었다가 식는다.
  double _beatPulse = 0.0;
  int _lastBeatIndex = -1;

  /// 환호 강도 0.0~1.0. 드롭 Perfect 직후 1.0이 되었다가 식는다.
  double _cheer = 0.0;

  /// 피버(드롭 폭발) 남은 시간 (초).
  double _feverSec = 0.0;

  /// 화염·CO2 연출 남은 시간 (초).
  double _pyroSec = 0.0;
  double _co2Sec = 0.0;

  /// 화면 흔들림 강도.
  double _shake = 0.0;

  /// 컨페티 파티클.
  final List<StageParticle> _particles = [];

  /// 덱 상태.
  double _filterVal = 0.0;
  double _bassVal = 2.0;
  bool _bassKill = false;
  int _loopRollDiv = 0;
  double _jogAngle = 0.0;

  /// 중앙 배너.
  String? _bannerText;
  DateTime _bannerUntil = DateTime.fromMillisecondsSinceEpoch(0);

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
        _animSec += dt;
        _state.autoMiss(pos);
        _state.decay(dt);
        _cheer = (_cheer - dt * 1.2).clamp(0.0, 1.0);
        _beatPulse = (_beatPulse * 0.85).clamp(0.0, 1.0);
        _feverSec = math.max(0.0, _feverSec - dt);
        _pyroSec = math.max(0.0, _pyroSec - dt);
        _co2Sec = math.max(0.0, _co2Sec - dt);
        _shake *= 0.86;
        _updateBeatPulse(pos);
        _updatePassiveTension(dt);
        _updateParticles(dt);
        if (_started) _jogAngle = (_jogAngle + (widget.song.bpm / 60) * 4.4) % 360;
        if (pos >= widget.song.durationSec) _finish();
      });
    });
  }

  void _updateBeatPulse(double pos) {
    final beatIndex = (pos / widget.song.beatSec).floor();
    if (beatIndex != _lastBeatIndex) {
      _lastBeatIndex = beatIndex;
      _beatPulse = 1.0;
    }
  }

  /// 필터·루프 롤·베이스 킬이 켜져 있는 동안 텐션이 차오른다.
  void _updatePassiveTension(double dt) {
    if (_filterVal.abs() > 18) _state.addTension(9.0 * dt);
    if (_loopRollDiv > 0) _state.addTension(15.0 * dt);
    if (_bassKill) _state.addTension(7.0 * dt);
  }

  void _updateParticles(double dt) {
    for (var i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.x += p.vx;
      p.y += p.vy;
      p.vy += 0.0009;
      p.life -= 0.028;
      if (p.life <= 0) _particles.removeAt(i);
    }
  }

  void _spawnDropParticles() {
    final rand = math.Random();
    for (var i = 0; i < 110; i++) {
      _particles.add(StageParticle(
        x: rand.nextDouble(),
        y: 0.42 + (rand.nextDouble() - 0.5) * 0.3,
        vx: (rand.nextDouble() - 0.5) * 0.015,
        vy: -rand.nextDouble() * 0.02 - 0.004,
        color: neonPalette[i % neonPalette.length],
        size: 3 + rand.nextDouble() * 5,
        life: 1.0,
      ));
    }
  }

  void _showBanner(String text) {
    _bannerText = text;
    _bannerUntil = DateTime.now().add(const Duration(milliseconds: 2400));
  }

  /// 타이밍 탭 — v0.1 판정 그대로.
  /// 드롭 이벤트를 맞추면 텐션 보상을 걸고 피버를 터뜨린다.
  void _onTap() {
    if (!_started || _finished) return;
    final result = _state.tapDetailed(_positionSec);
    final judgment = result.judgment;
    if (judgment == Judgment.none) return;
    setState(() {
      _lastJudgment = judgment;
      _lastJudgmentAt = DateTime.now();
      if (judgment == Judgment.perfect) {
        _cheer = 1.0;
      } else if (judgment == Judgment.good) {
        _cheer = (_cheer + 0.3).clamp(0.0, 1.0);
      }
      if (result.event?.isDrop == true) {
        _slamDrop(judgment);
      }
    });
  }

  /// 드롭 보상 + 피버 연출. 텐션 30 이상이면 ULTRA DROP.
  void _slamDrop(Judgment judgment) {
    final reward = _state.applyDropReward(widget.venue.payMultiplier);
    _feverSec = reward.ultra ? 4.0 : 1.5;
    _pyroSec = reward.ultra ? 1.2 : 0.5;
    _co2Sec = reward.ultra ? 1.0 : 0.0;
    _shake = reward.ultra ? 18.0 : 7.0;
    _spawnDropParticles();
    if (reward.ultra) {
      _showBanner('⚡ ULTRA DROP!! +\$${reward.cash} 💰');
    } else {
      _showBanner('💥 DROP! (+\$${reward.cash}) — 텐션을 더 모으면 보상이 커져요!');
    }
  }

  void _onFilterChanged(double value) {
    setState(() {
      _filterVal = value;
      if (value.abs() > 15) _state.addTension(0.45);
    });
  }

  void _onBassChanged(double value) {
    setState(() => _bassVal = value);
  }

  void _onLoopRoll(int div) {
    setState(() {
      if (_loopRollDiv == div) {
        _loopRollDiv = 0;
      } else {
        _loopRollDiv = div;
        _state.addTension(div == 16 ? 25 : div == 8 ? 18 : 12);
      }
    });
  }

  void _onFx(String type) {
    setState(() {
      _state.addTension(18);
      switch (type) {
        case 'riser':
          _showBanner('🌪️ RISER SWEEP! (텐션 +18%)');
        case 'airhorn':
          _state.heat = (_state.heat + 4).clamp(0.0, 100.0);
          _showBanner('📢 BWAH-BWAH-BWAHHH!!');
        case 'pyro':
          _pyroSec = 1.2;
          _shake = 8.0;
          _state.heat = (_state.heat + 5).clamp(0.0, 100.0);
        case 'co2':
          _co2Sec = 1.0;
          _state.heat = (_state.heat + 4).clamp(0.0, 100.0);
      }
    });
  }

  void _onBassKillToggle() {
    setState(() {
      _bassKill = !_bassKill;
      if (_bassKill) _state.addTension(12);
    });
  }

  Future<void> _finish() async {
    if (_finished) return;
    _finished = true;
    _tickTimer?.cancel();
    await _audio.stop();
    if (!mounted) return;
    _state.applyFinishBonus(widget.venue.payMultiplier);
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          result: GameResult.fromState(_state),
          song: widget.song,
          venue: widget.venue,
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
    final showBanner = _bannerText != null &&
        DateTime.now().isBefore(_bannerUntil);
    final section = widget.song.sectionAt(_positionSec);
    final isBuildup = section.kind == SectionKind.buildup;
    final isDropSection = section.kind == SectionKind.drop;
    final progress =
        (_positionSec / widget.song.durationSec).clamp(0.0, 1.0);
    final remainSec =
        (widget.song.durationSec - _positionSec).clamp(0.0, double.infinity);
    final remain = remainSec.ceil();
    final remainText =
        '${remain ~/ 60}:${(remain % 60).toString().padLeft(2, '0')}';
    final theme = Color(widget.venue.themeColorHex);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // 상단: 점수 · 콤보 · 남은 시간 · 이번 공연 수입.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('점수',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.textMuted)),
                      Text(
                        '${_state.score}',
                        style: const TextStyle(
                          fontSize: 22,
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
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.neonYellow,
                      ),
                    ),
                  Text(
                    '💰 \$${_state.cashEarned}  ·  🔥 ${_state.fansEarned}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    remainText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            // 스테이지.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: StageCanvas(
                          venue: widget.venue,
                          isPlaying: _started,
                          timeSec: _animSec,
                          beatPulse: _beatPulse,
                          isBuildup: isBuildup,
                          fever: _feverSec > 0,
                          pyroLevel: _pyroSec > 0 ? 1.0 : 0.0,
                          co2Level: _co2Sec > 0 ? 1.0 : 0.0,
                          shake: _shake,
                          particles: _particles,
                        ),
                      ),
                      // 좌상단: 무대 정보 + 관객 요청.
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: AppTheme.surfaceLight),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: theme,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      widget.venue.badge,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.venue.name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              constraints:
                                  const BoxConstraints(maxWidth: 220),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1B4B)
                                    .withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFF818CF8)
                                        .withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                _crowdRequest(section),
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.white),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 우상단: HYPE·TENSION 게이지.
                      Positioned(
                        top: 8,
                        right: 8,
                        width: 148,
                        child: Column(
                          children: [
                            HypeGauge(value: _state.heat),
                            const SizedBox(height: 6),
                            TensionGauge(value: _state.tension),
                          ],
                        ),
                      ),
                      // 중앙 배너.
                      if (showBanner)
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFD946EF),
                                    Color(0xFFEC4899),
                                    Color(0xFFF59E0B),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.white, width: 1.5),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0xE6FF2A85),
                                    blurRadius: 24,
                                  ),
                                ],
                              ),
                              child: Text(
                                _bannerText!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
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
              ),
            ),
            // 페이즈 코치.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDropSection
                          ? AppTheme.neonPink
                          : isBuildup
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.25)
                              : AppTheme.neonCyan.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDropSection
                            ? AppTheme.neonPink
                            : isBuildup
                                ? const Color(0xFFF59E0B)
                                : AppTheme.neonCyan,
                      ),
                    ),
                    child: Text(
                      isDropSection
                          ? '⚡ THE DROP!'
                          : isBuildup
                              ? '🔥 BUILD-UP'
                              : 'GROOVE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: isDropSection
                            ? Colors.white
                            : isBuildup
                                ? const Color(0xFFFCD34D)
                                : AppTheme.neonCyan,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _coachPrompt(section),
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${widget.song.bpm.toInt()} BPM',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            // 구간 타임라인.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: SizedBox(
                height: 22,
                child: Row(
                  children: widget.song.sections.map((s) {
                    final flex =
                        ((s.endSec - s.startSec) * 100).round();
                    final isCurrent = section == s;
                    final inSection = _positionSec >= s.startSec &&
                        _positionSec < s.endSec;
                    final fill = inSection
                        ? ((_positionSec - s.startSec) /
                                (s.endSec - s.startSec))
                            .clamp(0.0, 1.0)
                        : (_positionSec >= s.endSec ? 1.0 : 0.0);
                    final color = s.kind == SectionKind.drop
                        ? AppTheme.neonPink
                        : s.kind == SectionKind.buildup
                            ? const Color(0xFF818CF8)
                            : AppTheme.surfaceLight;
                    return Expanded(
                      flex: flex,
                      child: Container(
                        margin: const EdgeInsets.only(right: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(4),
                          border: isCurrent
                              ? Border.all(color: Colors.white, width: 1)
                              : null,
                        ),
                        child: Stack(
                          children: [
                            FractionallySizedBox(
                              widthFactor: fill,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            Center(
                              child: Text(
                                s.label,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: isCurrent
                                      ? FontWeight.w900
                                      : FontWeight.w600,
                                  color: isCurrent
                                      ? Colors.white
                                      : AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            // 비트 트랙 (탭 가능) — 타이밍 판정 코어.
            GestureDetector(
              onTapDown: (_) => _onTap(),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                child: SizedBox(
                  height: 84,
                  child: BeatTrack(
                    song: widget.song,
                    events: _state.events,
                    positionSec: _positionSec,
                  ),
                ),
              ),
            ),
            // SLAM THE DROP 패드.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: GestureDetector(
                onTapDown: (_) => _onTap(),
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFDB2777),
                        Color(0xFFC026D3),
                        Color(0xFFF59E0B),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    border: Border.all(
                        color: const Color(0xFFF9A8D4).withValues(alpha: 0.8),
                        width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.neonPink.withValues(alpha: 0.45),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      isDropSection
                          ? '⚡ SLAM THE DROP!'
                          : '⚡ SLAM THE DROP!  ·  텐션 ${_state.tension.round()}%',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // DJ 덱.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DeckKnob(
                        label: '🎛️ FILTER',
                        valueText: _filterVal < -5
                            ? 'LPF ${ _filterVal.round()}%'
                            : _filterVal > 5
                                ? 'HPF +${_filterVal.round()}%'
                                : 'CLEAN (0%)',
                        value: _filterVal,
                        min: -100,
                        max: 100,
                        accent: AppTheme.neonCyan,
                        onChanged: _onFilterChanged,
                      ),
                      DeckKnob(
                        label: '🔊 BASS',
                        valueText:
                            '${_bassVal >= 0 ? '+' : ''}${_bassVal.round()} dB',
                        value: _bassVal,
                        min: -12,
                        max: 12,
                        accent: const Color(0xFFE879F9),
                        onChanged: _onBassChanged,
                      ),
                      JogWheel(
                        angleDeg: _jogAngle,
                        onScratchStart: () =>
                            setState(() => _state.addTension(8)),
                        onScratchMove: (dx) => setState(() {
                          _jogAngle = (_jogAngle + dx * 0.5) % 360;
                          _state.addTension(0.2);
                        }),
                      ),
                      BassKillButton(
                        active: _bassKill,
                        onToggle: _onBassKillToggle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LoopRollRow(
                    activeDiv: _loopRollDiv,
                    onSelect: _onLoopRoll,
                  ),
                  const SizedBox(height: 6),
                  FxRow(onFx: _onFx),
                ],
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

  String _crowdRequest(SongSection section) {
    return switch (section.kind) {
      SectionKind.buildup =>
        '"🙌 소리가 조여진다!! 드랍 준비해 주세요 디제이!!"',
      SectionKind.drop => '"🔥 미쳤다!! 최고의 드랍이에요!!"',
      SectionKind.groove => '"비트가 좋아요! 빌드업에서 필터로 조여주세요!"',
    };
  }

  String _coachPrompt(SongSection section) {
    return switch (section.kind) {
      SectionKind.buildup =>
        '지금 필터 노브를 돌리거나 루프 롤을 눌러 텐션을 모으세요!',
      SectionKind.drop => '지금 바로 SLAM THE DROP을 눌러 에너지를 터뜨리세요!',
      SectionKind.groove => '플로어가 예열 중입니다. 곧 빌드업이 시작돼요.',
    };
  }
}
