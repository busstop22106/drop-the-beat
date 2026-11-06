import 'package:flutter/material.dart';

import '../data/songs.dart';
import '../theme/app_theme.dart';
import 'game_screen.dart';

/// 홈 화면 — 스테이지·곡 선택, 타이밍 보정, 공연 시작.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// 타이밍 보정값 (밀리초). 실기기에서 소리와 화면이 어긋나면 조정.
  int _calibrationMs = 0;

  @override
  Widget build(BuildContext context) {
    final song = prototypeSong;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Text(
                'DROP THE BEAT',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  letterSpacing: -1,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '지하 술집에서 월드 페스티벌까지.\n당신의 타이밍에 관객이 터져나옵니다.',
                style: TextStyle(
                    fontSize: 15, color: AppTheme.textMuted, height: 1.5),
              ),
              const SizedBox(height: 28),
              // 스테이지 카드.
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('스테이지 1',
                        style: TextStyle(
                            fontSize: 13, color: AppTheme.neonCyan)),
                    const SizedBox(height: 6),
                    Text(
                      undergroundBarStage.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      undergroundBarStage.description,
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 곡 카드.
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('오늘의 곡',
                        style: TextStyle(
                            fontSize: 13, color: AppTheme.neonPink)),
                    const SizedBox(height: 6),
                    Text(
                      song.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${song.artist}  ·  ${song.bpm.toInt()} BPM  ·  '
                      '1:08  ·  타이밍 ${song.events.length}개',
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // 타이밍 보정.
              Text(
                '타이밍 보정  ${_calibrationMs > 0 ? '+' : ''}$_calibrationMs ms',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Text(
                '실기기에서 소리가 화면보다 늦게 들리면 +방향, 빨리 들리면 −방향으로 조정하세요.',
                style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
              Slider(
                value: _calibrationMs.toDouble(),
                min: -150,
                max: 150,
                divisions: 30,
                label: '$_calibrationMs ms',
                onChanged: (v) => setState(() => _calibrationMs = v.round()),
              ),
              const SizedBox(height: 8),
              const Text(
                '플레이 방법: 비트가 판정선에 닿을 때 DROP 패드를 탭하세요. '
                '드롭을 Perfect로 맞추면 관객이 환호해요.',
                style: TextStyle(
                    fontSize: 13, color: AppTheme.textMuted, height: 1.5),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GameScreen(
                        song: song,
                        calibrationOffsetMs: _calibrationMs,
                      ),
                    ),
                  );
                },
                child: const Text('공연 시작하기'),
              ),
              const SizedBox(height: 16),
              const Text(
                '프로토타입 v0.1 — 곡 1개 · 스테이지 1개. '
                'Suno 곡 교체 방법은 README를 참조하세요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
