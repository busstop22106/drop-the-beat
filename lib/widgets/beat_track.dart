import 'package:flutter/material.dart';

import '../engine/song.dart';
import '../theme/app_theme.dart';

/// 비트 트랙 — 다가오는 타이밍 이벤트가 판정선으로 흘러 들어온다.
/// 판정선은 왼쪽 22% 지점, 오른쪽에서 왼쪽으로 흐른다.
class BeatTrack extends StatelessWidget {
  const BeatTrack({
    required this.song,
    required this.events,
    required this.positionSec,
    super.key,
  });

  final SongMetadata song;
  final List<BeatEvent> events;

  /// 현재 곡 위치 (초).
  final double positionSec;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BeatTrackPainter(
        song: song,
        events: events,
        positionSec: positionSec,
      ),
    );
  }
}

class _BeatTrackPainter extends CustomPainter {
  _BeatTrackPainter({
    required this.song,
    required this.events,
    required this.positionSec,
  });

  final SongMetadata song;
  final List<BeatEvent> events;
  final double positionSec;

  /// 판정선 앞쪽으로 보여줄 시간 (초).
  static const double _windowSec = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final hitX = size.width * 0.22;
    final centerY = size.height / 2;

    // 트랙 라인.
    final linePaint = Paint()
      ..color = AppTheme.surfaceLight
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(8, centerY), Offset(size.width - 8, centerY), linePaint);

    // 판정선 — 박자 위상에 맞춰 살짝 커졌다 작아진다.
    final phase = song.beatPhase(positionSec);
    final ringR = 16.0 + (1.0 - phase) * 5.0;
    final ringPaint = Paint()
      ..color = AppTheme.neonPink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(Offset(hitX, centerY), ringR, ringPaint);
    final dotPaint = Paint()..color = AppTheme.neonPink;
    canvas.drawCircle(Offset(hitX, centerY), 5.0, dotPaint);

    // 이벤트 노트.
    for (final event in events) {
      final dt = event.timeSec - positionSec;
      // 지나간 지 0.25초가 넘은 노트는 그리지 않는다.
      if (dt < -0.25) continue;
      // 2초보다 먼 노트는 아직 그리지 않는다.
      if (dt > _windowSec) continue;
      final x = hitX + (dt / _windowSec) * (size.width - hitX - 12);

      final color = switch (event.type) {
        EventType.drop => AppTheme.neonPink,
        EventType.build => AppTheme.neonCyan,
        EventType.beat => Colors.white,
        EventType.transition => AppTheme.neonYellow,
      };
      final radius = switch (event.type) {
        EventType.drop => 14.0,
        EventType.build => 9.0,
        EventType.beat => 7.0,
        EventType.transition => 10.0,
      };

      final paint = Paint()
        ..color = event.judged
            ? color.withValues(alpha: 0.25)
            : color.withValues(alpha: 0.95);
      canvas.drawCircle(Offset(x, centerY), radius, paint);
      if (event.type == EventType.drop) {
        final outline = Paint()
          ..color = Colors.white.withValues(alpha: event.judged ? 0.2 : 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(Offset(x, centerY), radius + 4, outline);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BeatTrackPainter oldDelegate) {
    return oldDelegate.positionSec != positionSec ||
        oldDelegate.events != events;
  }
}
