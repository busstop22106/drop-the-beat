import 'package:flutter/material.dart';

import '../engine/game_state.dart';
import '../engine/song.dart';
import '../theme/app_theme.dart';
import 'game_screen.dart';

/// 공연 결과 화면 — 별·점수·판정 집계·관객 리뷰.
class ResultScreen extends StatelessWidget {
  const ResultScreen({
    required this.result,
    required this.song,
    this.calibrationOffsetMs = 0,
    super.key,
  });

  final GameResult result;
  final SongMetadata song;

  /// 다시 하기 때 유지할 타이밍 보정값.
  final int calibrationOffsetMs;

  String get _review => switch (result.stars) {
        3 => '관객이 미쳤어요. 오늘 밤의 주인공은 당신이에요.',
        2 => '분위기가 뜨거웠어요. 드롭 타이밍만 조금 더 맞추면 전설이 돼요.',
        _ => '첫 공연은 원래 그래요. 비트에 몸을 맡겨보세요.',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Text(
                '공연 종료',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 8),
              Text(
                song.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final filled = i < result.stars;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      filled ? Icons.star : Icons.star_border,
                      size: 44,
                      color: filled
                          ? AppTheme.neonYellow
                          : AppTheme.surfaceLight,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Text(
                '${result.score}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '정확도 ${(result.accuracy * 100).toStringAsFixed(1)}%  ·  '
                '최대 콤보 ${result.maxCombo}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 24),
              _statRow('PERFECT', result.perfectCount, AppTheme.neonPink),
              _statRow('GOOD', result.goodCount, AppTheme.neonCyan),
              _statRow('MISS', result.missCount, AppTheme.textMuted),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '관객 리뷰: "$_review"',
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '명성 +${result.stars * 10}  ·  다음 스테이지 "홍대 클럽"은 '
                '프로토타입에서는 아직 잠겨 있어요.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => GameScreen(
                        song: song,
                        calibrationOffsetMs: calibrationOffsetMs,
                      ),
                    ),
                  );
                },
                child: const Text('다시 하기'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  side: const BorderSide(color: AppTheme.surfaceLight),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('홈으로'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: color)),
          Text('$count',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
