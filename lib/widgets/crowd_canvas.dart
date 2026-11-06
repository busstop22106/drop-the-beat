import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 관객석 캔버스. 비트에 맞춰 뛰고, 에너지가 높을수록 높이·빠르게 반응한다.
/// 드롭을 Perfect로 맞추면 [cheer]가 1.0이 되었다가 서서히 식으면서
/// 환호 링이 퍼진다.
class CrowdCanvas extends StatelessWidget {
  const CrowdCanvas({
    required this.heat,
    required this.beatPhase,
    required this.cheer,
    super.key,
  });

  /// 관객 에너지 0~100.
  final double heat;

  /// 박자 내 위상 0.0~1.0. 0.0이 박자 정각이다.
  final double beatPhase;

  /// 환호 강도 0.0~1.0. 드롭 Perfect 직후 1.0.
  final double cheer;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CrowdPainter(
        heat: heat,
        beatPhase: beatPhase,
        cheer: cheer,
      ),
    );
  }
}

class _CrowdPainter extends CustomPainter {
  _CrowdPainter({
    required this.heat,
    required this.beatPhase,
    required this.cheer,
  });

  final double heat;
  final double beatPhase;
  final double cheer;

  static const int _figures = 26;

  @override
  void paint(Canvas canvas, Size size) {
    // 무대 조명 — 에너지가 높을수록 밝아진다.
    final lightAlpha = (0.10 + heat / 100 * 0.22).clamp(0.0, 0.32);
    final beamPaint = Paint()
      ..color = AppTheme.neonPurple.withValues(alpha: lightAlpha)
      ..style = PaintingStyle.fill;
    final leftBeam = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.35, 0)
      ..lineTo(size.width * 0.55, size.height)
      ..lineTo(size.width * 0.15, size.height)
      ..close();
    final rightBeam = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width * 0.65, 0)
      ..lineTo(size.width * 0.45, size.height)
      ..lineTo(size.width * 0.85, size.height)
      ..close();
    canvas.drawPath(leftBeam, beamPaint);
    canvas.drawPath(rightBeam, beamPaint);

    // 환호 링 — 드롭 Perfect 직후 퍼진다.
    if (cheer > 0.05) {
      for (var i = 0; i < 2; i++) {
        final progress = (1.0 - cheer + i * 0.25).clamp(0.0, 1.0);
        final ringPaint = Paint()
          ..color = AppTheme.neonPink.withValues(alpha: cheer * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;
        canvas.drawCircle(
          Offset(size.width / 2, size.height * 0.45),
          progress * size.width * 0.55 + 10,
          ringPaint,
        );
      }
    }

    // 박자 펄스: 박자 정각 직후 1, 다음 박자 직전 0.
    final pulse = 1.0 - beatPhase;
    final baseAmp = 3.0 + (heat / 100) * 13.0;

    for (var i = 0; i < _figures; i++) {
      // 인덱스만으로 결정되는 고정 지터 — 프레임마다 흔들리지 않는다.
      final jitter = ((i * 37) % 10) / 10.0;
      final jitter2 = ((i * 53) % 10) / 10.0;
      final x = (i + 0.5) / _figures * size.width + (jitter - 0.5) * 14;
      final groundY = size.height * 0.94;
      final figureH = size.height * (0.26 + jitter2 * 0.10);
      final bounce = pulse * baseAmp * (0.6 + jitter * 0.6);
      final topY = groundY - figureH + bounce * 0.6;

      // 몸통 색: 에너지가 오르면 어두운 실루엣에서 네온 퍼플로.
      final bodyColor = Color.lerp(
        const Color(0xFF23233A),
        AppTheme.neonPurple,
        (heat / 100 * 0.55).clamp(0.0, 1.0),
      )!;

      final bodyPaint = Paint()..color = bodyColor;
      final headPaint = Paint()..color = bodyColor;

      // 몸통 (둥근 사각형).
      final bodyW = size.width / _figures * 0.52;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - bodyW / 2, topY + figureH * 0.28, bodyW,
              figureH * 0.72 - bounce * 0.6),
          const Radius.circular(6),
        ),
        bodyPaint,
      );
      // 머리.
      canvas.drawCircle(
        Offset(x, topY + figureH * 0.14),
        figureH * 0.14,
        headPaint,
      );

      // 팔 들기 — 에너지가 높거나 환호 중이면 두 팔을 위로.
      final armsUp = heat > 65 || cheer > 0.25;
      if (armsUp) {
        final armPaint = Paint()
          ..color = bodyColor
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round;
        final shoulderY = topY + figureH * 0.36;
        final handY = shoulderY - figureH * 0.28 - pulse * 4;
        canvas.drawLine(
            Offset(x - bodyW / 2, shoulderY), Offset(x - bodyW, handY), armPaint);
        canvas.drawLine(
            Offset(x + bodyW / 2, shoulderY), Offset(x + bodyW, handY), armPaint);
      }

      // 폰 라이트 — 환호 중 일부 관객이 폰을 든다.
      if (cheer > 0.2 && (i % 3 == 0)) {
        final glowPaint = Paint()
          ..color = (i % 2 == 0 ? AppTheme.neonCyan : AppTheme.neonYellow)
              .withValues(alpha: 0.9 * cheer);
        canvas.drawCircle(
          Offset(x + bodyW * 0.7, topY - figureH * 0.12),
          3.0 + cheer * 2.0,
          glowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CrowdPainter oldDelegate) {
    return oldDelegate.heat != heat ||
        oldDelegate.beatPhase != beatPhase ||
        oldDelegate.cheer != cheer;
  }
}
