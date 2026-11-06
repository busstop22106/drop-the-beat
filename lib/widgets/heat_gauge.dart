import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 관객 에너지 게이지 — "Heat" 바.
/// 에너지가 낮으면 차갑게(시안), 높으면 뜨겁게(핑크)로 색이 바뀐다.
class HeatGauge extends StatelessWidget {
  const HeatGauge({required this.heat, super.key});

  /// 0~100.
  final double heat;

  @override
  Widget build(BuildContext context) {
    final color = Color.lerp(
      AppTheme.neonCyan,
      AppTheme.neonPink,
      (heat / 100).clamp(0.0, 1.0),
    )!;
    final label = heat >= 80
        ? '관객이 미쳤어요'
        : heat >= 55
            ? '분위기 좋아요'
            : heat >= 30
                ? '조금 식어가는 중'
                : '관객이 지루해해요';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '관객 에너지  $label',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textPrimary),
            ),
            Text(
              '${heat.round()}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 12,
            color: AppTheme.surfaceLight,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: (heat / 100).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.neonCyan, color],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
