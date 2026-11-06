import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../engine/venue.dart';

/// 스테이지 렌더러 — 제미나이 DJ HYPE의 2D/3D 벡터 스테이지를
/// Flutter CustomPainter로 옮긴 것.
/// 하늘 그라디언트 → 원근 바닥 그리드 → 무대별 건축물 → 서브우퍼 →
/// LED 월 → 레이저 → 화염/CO2 → DJ 부스·실루엣 → 관객 → 파티클 순으로 그린다.
/// 부모(GameScreen)가 33ms 타이머로 setState를 돌려 프레임을 갱신한다.

const List<Color> neonPalette = [
  Color(0xFF00F0FF),
  Color(0xFFFF2A85),
  Color(0xFFFFE600),
  Color(0xFFA855F7),
  Color(0xFF34D399),
  Color(0xFFFB7185),
];

/// 드롭 때 터지는 컨페티 파티클. 부모가 소유하고 타이머로 갱신한다.
class StageParticle {
  StageParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.life,
  });

  double x, y, vx, vy, size, life;
  final Color color;
}

class _CrowdAgent {
  _CrowdAgent({
    required this.xNorm,
    required this.depthNorm,
    required this.color,
    required this.phase,
    required this.hasGlowstick,
    required this.hasTotem,
    required this.emoji,
  });

  final double xNorm;
  final double depthNorm;
  final Color color;
  final double phase;
  final bool hasGlowstick;
  final bool hasTotem;
  final String emoji;
}

class StageCanvas extends StatefulWidget {
  const StageCanvas({
    super.key,
    required this.venue,
    required this.isPlaying,
    required this.timeSec,
    required this.beatPulse,
    required this.isBuildup,
    required this.fever,
    required this.pyroLevel,
    required this.co2Level,
    required this.shake,
    required this.particles,
  });

  final Venue venue;
  final bool isPlaying;
  final double timeSec;
  final double beatPulse;
  final bool isBuildup;
  final bool fever;
  final double pyroLevel;
  final double co2Level;
  final double shake;
  final List<StageParticle> particles;

  @override
  State<StageCanvas> createState() => _StageCanvasState();
}

class _StageCanvasState extends State<StageCanvas> {
  late List<_CrowdAgent> _agents;

  @override
  void initState() {
    super.initState();
    _agents = _buildAgents(widget.venue);
  }

  @override
  void didUpdateWidget(covariant StageCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.venue.id != widget.venue.id) {
      _agents = _buildAgents(widget.venue);
    }
  }

  List<_CrowdAgent> _buildAgents(Venue venue) {
    final rand = math.Random(venue.id * 7919 + 13);
    const emojis = ['🔥', '🙌', '⚡', '❤️', '👑'];
    final count = math.min(venue.crowdCount, 140);
    final perRow = (count / venue.rows).ceil();
    final agents = <_CrowdAgent>[];
    for (var r = 0; r < venue.rows; r++) {
      final depthNorm = venue.rows <= 1 ? 0.0 : r / (venue.rows - 1);
      for (var i = 0; i < perRow; i++) {
        final xNorm = (i + 0.5 + (rand.nextDouble() - 0.5) * 0.65) / perRow;
        agents.add(_CrowdAgent(
          xNorm: xNorm.clamp(0.03, 0.97),
          depthNorm: depthNorm,
          color: neonPalette[(r + i) % neonPalette.length],
          phase: rand.nextDouble() * math.pi * 2,
          hasGlowstick: rand.nextDouble() > 0.3,
          hasTotem: venue.id == 3 && r > 1 && r < 5 && i % 19 == 0,
          emoji: emojis[(r + i) % emojis.length],
        ));
      }
    }
    return agents;
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StagePainter(
        venue: widget.venue,
        isPlaying: widget.isPlaying,
        timeSec: widget.timeSec,
        beatPulse: widget.beatPulse,
        isBuildup: widget.isBuildup,
        fever: widget.fever,
        pyroLevel: widget.pyroLevel,
        co2Level: widget.co2Level,
        shake: widget.shake,
        particles: widget.particles,
        agents: _agents,
      ),
    );
  }
}

class _StagePainter extends CustomPainter {
  _StagePainter({
    required this.venue,
    required this.isPlaying,
    required this.timeSec,
    required this.beatPulse,
    required this.isBuildup,
    required this.fever,
    required this.pyroLevel,
    required this.co2Level,
    required this.shake,
    required this.particles,
    required this.agents,
  });

  final Venue venue;
  final bool isPlaying;
  final double timeSec;
  final double beatPulse;
  final bool isBuildup;
  final bool fever;
  final double pyroLevel;
  final double co2Level;
  final double shake;
  final List<StageParticle> particles;
  final List<_CrowdAgent> agents;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final horizonY = h * 0.46;
    final theme = Color(venue.themeColorHex);

    canvas.save();
    if (shake > 0.5) {
      canvas.translate(
        math.sin(timeSec * 127.1) * shake,
        math.cos(timeSec * 311.7) * shake,
      );
    }

    _drawSky(canvas, w, h, horizonY, theme);
    _drawFloorGrid(canvas, w, h, horizonY);
    _drawArchitecture(canvas, w, h, horizonY, theme);
    if (venue.id >= 1) _drawSubwoofers(canvas, w, horizonY);
    _drawLedWall(canvas, w, horizonY);
    if (venue.id >= 1 || fever) _drawLasers(canvas, w, h, horizonY);
    if (pyroLevel > 0) _drawPyro(canvas, w, horizonY);
    if (co2Level > 0) _drawCo2(canvas, w, h, horizonY);
    _drawDj(canvas, w, horizonY, theme);
    _drawCrowd(canvas, w, h, horizonY, theme);
    _drawParticles(canvas, w, h);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StagePainter oldDelegate) => true;

  void _drawSky(Canvas canvas, double w, double h, double horizonY, Color theme) {
    final sky = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        fever ? const Color(0xFF3B0764) : Color(venue.bgTopHex),
        Color(venue.bgBottomHex),
        const Color(0xFF020205),
      ],
      stops: const [0.0, 0.55, 1.0],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..shader = sky.createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // 박자에 반응하는 중앙 백라이트 글로우.
    final coreRadius = w * (0.28 + beatPulse * 0.14);
    final glow = RadialGradient(
      colors: [
        (fever
                ? const Color(0xFFFF2A85)
                : isBuildup
                    ? const Color(0xFF00F0FF)
                    : theme)
            .withValues(alpha: 0.45),
        Colors.transparent,
      ],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = glow.createShader(
          Rect.fromCircle(
            center: Offset(w * 0.5, horizonY * 0.75),
            radius: coreRadius,
          ),
        ),
    );
  }

  void _drawFloorGrid(Canvas canvas, double w, double h, double horizonY) {
    final paint = Paint()
      ..color = (fever
              ? const Color(0xFFFF2A85)
              : isBuildup
                  ? const Color(0xFF00F0FF)
                  : const Color(0xFF94A3B8))
          .withValues(alpha: fever || isBuildup ? 0.38 : 0.15)
      ..strokeWidth = 1.5;
    for (var i = -9; i <= 9; i++) {
      canvas.drawLine(
        Offset(w * 0.5 + i * (w * 0.028), horizonY),
        Offset(w * 0.5 + i * (w * 0.13), h),
        paint,
      );
    }
    for (var r = 1; r <= 6; r++) {
      final ry = horizonY + math.pow(r / 6, 1.75) * (h - horizonY);
      canvas.drawLine(Offset(0, ry), Offset(w, ry), paint);
    }
  }

  void _drawArchitecture(
      Canvas canvas, double w, double h, double horizonY, Color theme) {
    switch (venue.id) {
      case 0:
        // 지하 술집: 벽돌 벽 + 따뜻한 펜던트 스포트라이트.
        final brick = Paint()
          ..color = const Color(0xFF78350F).withValues(alpha: 0.28)
          ..strokeWidth = 1;
        var by = 20.0;
        while (by < horizonY) {
          final offset = (by % 36 == 0) ? 0.0 : 20.0;
          var bx = offset;
          while (bx < w) {
            canvas.drawRect(Rect.fromLTWH(bx, by, 38, 16), brick);
            bx += 40;
          }
          by += 18;
        }
        for (var idx = 0; idx < 3; idx++) {
          final xp = [0.25, 0.5, 0.75][idx];
          final lx = w * xp;
          final sway = math.sin(timeSec * 1.5 + idx) * 20;
          final cone = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF59E0B).withValues(alpha: 0.45),
              Colors.transparent,
            ],
          );
          final path = Path()
            ..moveTo(lx - 8, 12)
            ..lineTo(lx - 85 + sway, horizonY + 40)
            ..lineTo(lx + 85 + sway, horizonY + 40)
            ..lineTo(lx + 8, 12)
            ..close();
          canvas.drawPath(
            path,
            Paint()..shader = cone.createShader(Rect.fromLTWH(0, 0, w, horizonY + 40)),
          );
        }
      case 1:
        // 인디 클럽: 네온 터널 아치 3개.
        for (var a = 0; a < 3; a++) {
          final aw = w * (0.42 + a * 0.14);
          final ah = horizonY * (0.55 + a * 0.15);
          canvas.drawRect(
            Rect.fromLTWH(w * 0.5 - aw / 2, horizonY - ah, aw, ah),
            Paint()
              ..color = a % 2 == 0 ? const Color(0xFF00F0FF) : const Color(0xFFFF2A85)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5,
          );
        }
      case 2:
        // 메가 클럽: 좌우 VIP 발코니 + 상단 조명 트러스.
        final fill = Paint()..color = const Color(0xFF090D1A);
        final stroke = Paint()
          ..color = const Color(0xFFFF2A85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        for (final x in [0.0, w * 0.8]) {
          final rect = Rect.fromLTWH(x, horizonY * 0.38, w * 0.2, 16);
          canvas.drawRect(rect, fill);
          canvas.drawRect(rect, stroke);
        }
        canvas.drawRect(
          Rect.fromLTWH(w * 0.15, 14, w * 0.7, 10),
          Paint()
            ..color = const Color(0xFF38BDF8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      case 3:
        // 페스티벌: 밤하늘 별 + 거대 메인스테이지 첨탑.
        final star = Paint()..color = Colors.white;
        for (var s = 0; s < 35; s++) {
          final sx = ((s * 97) % 100) / 100 * w;
          final sy = ((s * 43) % 100) / 100 * (horizonY * 0.55);
          final twinkle = 0.3 + 0.7 * (math.sin(timeSec * 2 + s)).abs();
          canvas.drawRect(
            Rect.fromLTWH(sx, sy, 2, 2),
            star..color = Colors.white.withValues(alpha: twinkle),
          );
        }
        final arch = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [Color(0xFF0F172A), Color(0xFF3B0764), Color(0xFF0F172A)],
        );
        final path = Path()
          ..moveTo(w * 0.08, horizonY)
          ..lineTo(w * 0.15, horizonY * 0.32)
          ..lineTo(w * 0.28, horizonY * 0.52)
          ..lineTo(w * 0.36, horizonY * 0.22)
          ..lineTo(w * 0.50, horizonY * 0.06)
          ..lineTo(w * 0.64, horizonY * 0.22)
          ..lineTo(w * 0.72, horizonY * 0.52)
          ..lineTo(w * 0.85, horizonY * 0.32)
          ..lineTo(w * 0.92, horizonY)
          ..close();
        canvas.drawPath(
          path,
          Paint()
            ..shader = arch.createShader(Rect.fromLTWH(0, 0, w, horizonY))
            ..style = PaintingStyle.fill,
        );
        canvas.drawPath(
          path,
          Paint()
            ..color = fever ? const Color(0xFFFFE600) : const Color(0xFF00F0FF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
    }
  }

  void _drawSubwoofers(Canvas canvas, double w, double horizonY) {
    final spkW = w * 0.065;
    final spkH = horizonY * 0.52;
    final pulseScale = 1 + beatPulse * 0.22;
    for (final sx in [w * 0.16 - spkW / 2, w * 0.84 - spkW / 2]) {
      final body = RRect.fromRectAndRadius(
        Rect.fromLTWH(sx, horizonY - spkH, spkW, spkH),
        const Radius.circular(6),
      );
      canvas.drawRRect(
        body,
        Paint()..color = const Color(0xFF0F172A),
      );
      canvas.drawRRect(
        body,
        Paint()
          ..color = const Color(0xFF334155)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      for (final cyRatio in [0.3, 0.72]) {
        final cx = sx + spkW / 2;
        final cy = horizonY - spkH + spkH * cyRatio;
        final r = math.min(spkW, spkH * 0.35) * 0.34 * pulseScale;
        canvas.drawCircle(
            Offset(cx, cy), r, Paint()..color = const Color(0xFF020617));
        canvas.drawCircle(
          Offset(cx, cy),
          r,
          Paint()
            ..color = fever ? const Color(0xFFFF2A85) : const Color(0xFF00F0FF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      }
    }
  }

  void _drawLedWall(Canvas canvas, double w, double horizonY) {
    const bars = 36;
    final wallW = w * (venue.id == 0 ? 0.36 : 0.52);
    final startX = (w - wallW) / 2;
    final barWidth = wallW / bars;
    for (var i = 0; i < bars; i++) {
      final distCenter = (i - bars / 2).abs() / (bars / 2);
      final rawAmp = isPlaying
          ? 0.14 + beatPulse * (0.55 + 0.45 * math.sin(timeSec * 3.0 + i * 0.7))
          : 0.14;
      final amp = rawAmp * (1.15 - distCenter * 0.4);
      final bh = math.max(
          4.0, amp * (horizonY * 0.62) * (fever ? 1.35 : 1.0));
      final hue = (i * 7 + timeSec * 70) % 360;
      canvas.drawRect(
        Rect.fromLTWH(startX + i * barWidth, horizonY - bh, barWidth * 0.72, bh),
        Paint()
          ..color = HSLColor.fromAHSL(0.82, hue, 0.95, 0.60).toColor(),
      );
    }
  }

  void _drawLasers(Canvas canvas, double w, double h, double horizonY) {
    final numLasers = venue.id == 3 ? 8 : venue.id == 2 ? 6 : 4;
    for (var l = 0; l < numLasers; l++) {
      final srcX = w * (0.2 + (l / math.max(1, numLasers - 1)) * 0.6);
      final srcY = horizonY * 0.22;
      final swing =
          math.sin(timeSec * (fever ? 5.2 : 2.1) + l * 1.1) * (w * 0.36);
      final col = neonPalette[(l + (timeSec * 3).floor()) % neonPalette.length];
      final beam = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [col.withValues(alpha: 0.55), Colors.transparent],
      );
      final path = Path()
        ..moveTo(srcX, srcY)
        ..lineTo(srcX + swing - 42, h)
        ..lineTo(srcX + swing + 42, h)
        ..close();
      canvas.drawPath(
        path,
        Paint()..shader = beam.createShader(Rect.fromLTWH(0, 0, w, h)),
      );
    }
  }

  void _drawPyro(Canvas canvas, double w, double horizonY) {
    for (final xp in [0.24, 0.38, 0.62, 0.76]) {
      final fx = w * xp;
      final fh = 120.0 * (0.26 + math.sin(timeSec * 9 + xp * 40).abs() * 0.14);
      final grad = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: pyroLevel),
          const Color(0xFFFDE047).withValues(alpha: pyroLevel * 0.9),
          const Color(0xFFEA580C).withValues(alpha: pyroLevel * 0.7),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(fx, horizonY - fh * 0.4),
          width: 56,
          height: fh * 1.2,
        ),
        Paint()
          ..shader = grad.createShader(
            Rect.fromCircle(center: Offset(fx, horizonY - fh * 0.5), radius: fh * 0.65),
          ),
      );
    }
  }

  void _drawCo2(Canvas canvas, double w, double h, double horizonY) {
    for (final xp in [0.31, 0.69]) {
      final cx = w * xp;
      final ch = h * 0.36;
      final grad = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFFF1F5F9).withValues(alpha: 0.92 * co2Level),
          Colors.transparent,
        ],
      );
      final path = Path()
        ..moveTo(cx - 6, horizonY)
        ..lineTo(cx - 38, horizonY - ch)
        ..lineTo(cx + 38, horizonY - ch)
        ..lineTo(cx + 6, horizonY)
        ..close();
      canvas.drawPath(
        path,
        Paint()..shader = grad.createShader(Rect.fromLTWH(0, horizonY - ch, w, ch)),
      );
    }
  }

  void _drawDj(Canvas canvas, double w, double horizonY, Color theme) {
    final djBounce = isPlaying ? beatPulse * 6 : 0.0;
    final djX = w * 0.5;
    final djY = horizonY - 32 - djBounce;
    final rim = fever ? const Color(0xFFFFE600) : const Color(0xFF00F0FF);

    final bodyPaint = Paint()..color = const Color(0xFF090D16);
    final rimPaint = Paint()
      ..color = rim
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    // 어깨 + 머리 실루엣.
    canvas.drawArc(
      Rect.fromCircle(center: Offset(djX, djY + 20), radius: 18),
      math.pi,
      math.pi,
      false,
      rimPaint,
    );
    canvas.drawCircle(Offset(djX, djY + 20), 18, bodyPaint);
    canvas.drawCircle(Offset(djX, djY), 11, bodyPaint);
    canvas.drawCircle(Offset(djX, djY), 11, rimPaint);

    // 빌드업·피버 때는 손을 든다.
    if (isBuildup || fever) {
      final armWave = math.sin(timeSec * 10) * 6;
      canvas.drawLine(
        Offset(djX + 12, djY + 10),
        Offset(djX + 24 + armWave, djY - 18),
        rimPaint,
      );
    }

    // LED DJ 부스.
    final boothW = w * 0.24;
    final booth = RRect.fromRectAndRadius(
      Rect.fromLTWH(djX - boothW / 2, horizonY - 18, boothW, 32),
      const Radius.circular(8),
    );
    canvas.drawRRect(booth, Paint()..color = const Color(0xFF0F172A));
    canvas.drawRRect(
      booth,
      Paint()
        ..color = rim
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawRect(
      Rect.fromLTWH(djX - boothW * 0.38, horizonY - 6, boothW * 0.76, 5),
      Paint()..color = fever ? const Color(0xFFFFE600) : const Color(0xFF00F0FF),
    );
  }

  void _drawCrowd(Canvas canvas, double w, double h, double horizonY, Color theme) {
    for (var idx = 0; idx < agents.length; idx++) {
      final c = agents[idx];
      final cx = c.xNorm * w;
      final cyBase = horizonY + 24 + c.depthNorm * (h - horizonY - 18);
      final scale = 0.52 + c.depthNorm * 0.88;

      var jump = 0.0;
      if (isPlaying) {
        if (fever) {
          jump = (math.sin(timeSec * 12 + c.phase)).abs() * 28 * scale;
        } else if (isBuildup) {
          jump = math.sin(timeSec * 22 + idx) * 2.5 * scale;
        } else {
          jump = beatPulse * 11 * scale * (idx % 2 == 0 ? 1 : 0.6);
        }
      }
      final y = cyBase - jump;
      final headR = 11 * scale;

      // 페스티벌 토템.
      if (c.hasTotem && venue.id == 3) {
        final sway = math.sin(timeSec * 3 + c.phase) * 12;
        canvas.drawLine(
          Offset(cx, y),
          Offset(cx + sway, y - 68 * scale),
          Paint()
            ..color = const Color(0xFFE2E8F0)
            ..strokeWidth = 2,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx + sway - 16 * scale, y - 82 * scale, 32 * scale, 18 * scale),
            const Radius.circular(4),
          ),
          Paint()..color = c.color,
        );
      }

      final rimColor = fever ? const Color(0xFFFFE600) : c.color;
      final fill = Paint()..color = const Color(0xFF070913);
      final rim = Paint()
        ..color = rimColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * scale;

      // 어깨 + 머리.
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, y + headR * 2.1), radius: headR * 1.65),
        math.pi,
        math.pi,
        false,
        rim,
      );
      canvas.drawCircle(Offset(cx, y + headR * 2.1), headR * 1.65, fill);
      canvas.drawCircle(Offset(cx, y), headR, fill);
      canvas.drawCircle(Offset(cx, y), headR, rim);

      // 팔 들기 + 글로우스틱.
      if (isBuildup || fever || (isPlaying && c.hasGlowstick)) {
        final wave = math.sin(timeSec * 8 + c.phase) * 8 * scale;
        final arm = Paint()
          ..color = c.color
          ..strokeWidth = 3 * scale;
        canvas.drawLine(
          Offset(cx - headR * 1.1, y + headR),
          Offset(cx - headR * 1.5 + wave, y - headR * 1.75),
          arm,
        );
        canvas.drawLine(
          Offset(cx + headR * 1.1, y + headR),
          Offset(cx + headR * 1.5 + wave, y - headR * 1.75),
          arm,
        );
      }

      // 피버 때 떠오르는 이모지.
      if (fever && idx % 6 == 0) {
        final tp = TextPainter(
          text: TextSpan(
            text: c.emoji,
            style: TextStyle(fontSize: 14 * scale),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(cx - 8, y - headR * 2.4));
      }
    }
  }

  void _drawParticles(Canvas canvas, double w, double h) {
    for (final p in particles) {
      canvas.drawRect(
        Rect.fromLTWH(p.x * w, p.y * h, p.size * 2, p.size * 2),
        Paint()..color = p.color.withValues(alpha: p.life.clamp(0.0, 1.0)),
      );
    }
  }
}
