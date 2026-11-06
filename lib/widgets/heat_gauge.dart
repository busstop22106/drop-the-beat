import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 스테이지 오버레이용 미터 카드 2개 — 클럽 열기(HYPE)와 빌드업 응축(TENSION).
/// 제미나이 DJ HYPE의 우측 상단 게이지를 옮긴 것.
/// HYPE는 기존 Heat(관객 에너지)를 그대로 쓴다.

class HypeGauge extends StatelessWidget {
  const HypeGauge({super.key, required this.value});

  /// 0~100.
  final double value;

  @override
  Widget build(BuildContext context) {
    return _MeterCard(
      label: '❤️ 클럽 열기 (HYPE)',
      labelColor: AppTheme.neonPink,
      percentText: '${value.round()}%',
      value: value,
      gradient: const LinearGradient(
        colors: [Color(0xFFEC4899), Color(0xFFD946EF), Color(0xFFFACC15)],
      ),
    );
  }
}

class TensionGauge extends StatelessWidget {
  const TensionGauge({super.key, required this.value});

  /// 0~100.
  final double value;

  @override
  Widget build(BuildContext context) {
    return _MeterCard(
      label: '⚡ 빌드업 응축 (TENSION)',
      labelColor: AppTheme.neonCyan,
      percentText: '${value.round()}%',
      value: value,
      gradient: const LinearGradient(
        colors: [Color(0xFF22D3EE), Color(0xFF3B82F6), Color(0xFFD946EF)],
      ),
      hint: '필터·루프 롤·FX로 충전 후 드랍!',
    );
  }
}

class _MeterCard extends StatelessWidget {
  const _MeterCard({
    required this.label,
    required this.labelColor,
    required this.percentText,
    required this.value,
    required this.gradient,
    this.hint,
  });

  final String label;
  final Color labelColor;
  final String percentText;
  final double value;
  final Gradient gradient;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: labelColor,
                ),
              ),
              Text(
                percentText,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      Container(color: AppTheme.surfaceLight),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: constraints.maxWidth * (value / 100).clamp(0.0, 1.0),
                        decoration: BoxDecoration(gradient: gradient),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 3),
            Text(
              hint!,
              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
