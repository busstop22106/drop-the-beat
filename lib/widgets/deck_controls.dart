import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// DJ 덱 컨트롤 — 제미나이 DJ HYPE의 덱을 Flutter로 옮긴 것.
/// 노브·조그휠·루프 롤·FX 패드·베이스 킬.
/// 주의: audioplayers는 실시간 DSP 필터/EQ를 제공하지 않아서,
/// 노브·패드는 실제 음색이 아니라 텐션+비주얼 연동으로 동작한다.
/// (진짜 필터가 필요하면 flutter_soloud로 오디오 엔진을 교체해야 한다.)

/// 위아래 드래그로 돌리는 로터리 노브.
/// [value]는 -100~100(필터) 또는 -12~12(베이스) 범위.
class DeckKnob extends StatelessWidget {
  const DeckKnob({
    super.key,
    required this.label,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.accent,
    required this.onChanged,
  });

  final String label;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final Color accent;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final angle = (value - min) / (max - min) * 270 - 135;
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        // 위로 올리면 값 증가. 필터는 1.4배, 베이스는 0.2배 감도.
        final step = (max - min) > 50 ? 1.4 : 0.2;
        onChanged((value - details.delta.dy * step).clamp(min, max));
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-0.3, -0.3),
                colors: [Color(0xFF2D3142), Color(0xFF12131C)],
              ),
              border: Border.all(color: AppTheme.surfaceLight, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: angle * math.pi / 180,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 4,
                      height: 15,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(color: accent, blurRadius: 6),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            valueText,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// 빙글빙글 도는 바이닐 조그휠. 드래그는 텐션을 쌓는다.
class JogWheel extends StatelessWidget {
  const JogWheel({
    super.key,
    required this.angleDeg,
    required this.onScratchStart,
    required this.onScratchMove,
  });

  final double angleDeg;
  final VoidCallback onScratchStart;
  final ValueChanged<double> onScratchMove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => onScratchStart(),
      onPanUpdate: (details) => onScratchMove(details.delta.dx),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1F2937), Color(0xFF020617)],
              ),
              border: Border.all(color: AppTheme.surfaceLight, width: 3),
            ),
            child: Transform.rotate(
              angle: angleDeg * math.pi / 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.surfaceLight.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFD946EF), Color(0xFF22D3EE)],
                      ),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 6,
                        height: 6,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: SizedBox(
                        width: 3,
                        height: 9,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppTheme.neonCyan,
                            borderRadius: BorderRadius.all(Radius.circular(2)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '💿 조그휠',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const Text(
            '스크래치',
            style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

/// 루프 롤 패드 4개 (1/2, 1/4, 1/8, 1/16). 누르면 텐션 급상승.
/// [activeDiv]가 0이면 전부 꺼진 상태.
class LoopRollRow extends StatelessWidget {
  const LoopRollRow({
    super.key,
    required this.activeDiv,
    required this.onSelect,
  });

  final int activeDiv;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '🔁 비트 쪼개기 (LOOP ROLL)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
              ),
            ),
            Text(
              activeDiv > 0 ? '1/$activeDiv ACTIVE' : 'OFF',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.neonCyan,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [2, 4, 8, 16].map((div) {
            final active = activeDiv == div;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: div == 16 ? 0 : 6),
                child: GestureDetector(
                  onTap: () => onSelect(div),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? AppTheme.neonCyan : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: active ? Colors.white : AppTheme.surfaceLight,
                      ),
                      boxShadow: active
                          ? [
                              const BoxShadow(
                                color: Color(0x6600F0FF),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      '1/$div',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: active ? Colors.black : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// FX 패드 4개: 라이저·에어혼·화염·CO2. 누르면 텐션 +18, 비주얼 연동.
class FxRow extends StatelessWidget {
  const FxRow({super.key, required this.onFx});

  final ValueChanged<String> onFx;

  @override
  Widget build(BuildContext context) {
    const fxs = [
      ('riser', '🌪️ 라이저'),
      ('airhorn', '📢 에어혼'),
      ('pyro', '🔥 화염'),
      ('co2', '💨 CO2'),
    ];
    return Row(
      children: fxs.map((fx) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: fx.$1 == 'co2' ? 0 : 6),
            child: GestureDetector(
              onTap: () => onFx(fx.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.surfaceLight,
                  ),
                ),
                child: Text(
                  fx.$2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 베이스 킬 토글 버튼. 켜져 있는 동안 텐션이 오른다.
class BassKillButton extends StatelessWidget {
  const BassKillButton({
    super.key,
    required this.active,
    required this.onToggle,
  });

  final bool active;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFDC2626) : AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? const Color(0xFFF87171) : AppTheme.surfaceLight,
          ),
          boxShadow: active
              ? [
                  const BoxShadow(
                    color: Color(0x99EF4444),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Text(
          '🔇 BASS KILL',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: active ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
