import 'package:flutter/material.dart';

import '../data/songs.dart';
import '../engine/career.dart';
import '../engine/game_state.dart';
import '../engine/venue.dart';
import '../theme/app_theme.dart';
import 'game_screen.dart';

/// 홈 화면 — 커리어 현황 · 무대 선택 · 곡 · 타이밍 보정 · 공연 시작.
/// 제미나이 DJ HYPE의 상단 헤더(개런티·팬덤 + 무대 선택)를 옮겼다.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// 타이밍 보정값 (밀리초). 실기기에서 소리와 화면이 어긋나면 조정.
  int _calibrationMs = 0;

  /// 선택한 무대.
  int _venueIndex = 0;

  /// 세션 커리어 (개런티·팬덤).
  final Career _career = Career();

  Future<void> _startGig() async {
    final song = prototypeSong;
    final result = await Navigator.of(context).push<GameResult>(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          song: song,
          venue: venues[_venueIndex],
          calibrationOffsetMs: _calibrationMs,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _career.addReward(cash: result.cashEarned, fans: result.fansEarned);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final song = prototypeSong;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              // 커리어 현황.
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.surfaceLight),
                    ),
                    child: Text(
                      '💰 개런티: \$${_career.cash}   |   🔥 팬덤: ${_career.fans}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'DROP THE BEAT',
                style: TextStyle(
                  fontSize: 40,
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
              const SizedBox(height: 20),
              const Text(
                '🏆 커리어 무대 선택',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.35,
                ),
                itemCount: venues.length,
                itemBuilder: (context, i) {
                  final venue = venues[i];
                  final selected = i == _venueIndex;
                  final theme = Color(venue.themeColorHex);
                  return GestureDetector(
                    onTap: () => setState(() => _venueIndex = i),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected ? theme : AppTheme.surfaceLight,
                          width: selected ? 2 : 1,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: theme.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              venue.badge,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            venue.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            venue.sub,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
                '빌드업에서 필터·루프 롤·FX로 텐션을 모은 뒤 드롭에서 터뜨리면 '
                '개런티와 팬덤이 커져요.',
                style: TextStyle(
                    fontSize: 13, color: AppTheme.textMuted, height: 1.5),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _startGig,
                child: const Text('공연 시작하기'),
              ),
              const SizedBox(height: 16),
              const Text(
                '프로토타입 v0.2 — 곡 1개 · 무대 4개. '
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
