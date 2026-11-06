/// 순수 Dart 모델 — Flutter import 없음.
/// 공연 무대(커리어 스테이지) 정의. 제미나이 DJ HYPE 구현의
/// 4단계 무대(지하 술집 → 인디 클럽 → 메가클럽 → 페스티벌)를 가져왔다.
/// 색상은 0xAARRGGBB int로 들고, 위젯에서 Color(hex)로 변환한다.

class Venue {
  const Venue({
    required this.id,
    required this.badge,
    required this.name,
    required this.sub,
    required this.crowdCount,
    required this.rows,
    required this.payMultiplier,
    required this.themeColorHex,
    required this.bgTopHex,
    required this.bgBottomHex,
  });

  final int id;
  final String badge;
  final String name;
  final String sub;
  final int crowdCount;
  final int rows;
  final int payMultiplier;

  /// 테마 색상 (0xAARRGGBB).
  final int themeColorHex;

  /// 무대 배경 그라디언트 상·하단 색상.
  final int bgTopHex;
  final int bgBottomHex;
}

/// 4개 무대. 관객 수·행 수·개런티 배율이 무대가 커질수록 커진다.
const List<Venue> venues = [
  Venue(
    id: 0,
    badge: 'STAGE 1',
    name: '동네 지하 술집',
    sub: '관객 28명 · 개런티 배율 x1.0 · 좁지만 뜨거운 매니아층',
    crowdCount: 28,
    rows: 2,
    payMultiplier: 1,
    themeColorHex: 0xFFF59E0B,
    bgTopHex: 0xFF160D08,
    bgBottomHex: 0xFF080504,
  ),
  Venue(
    id: 1,
    badge: 'STAGE 2',
    name: '로컬 인디 클럽',
    sub: '관객 85명 · 개런티 배율 x2.0 · 서브우퍼와 네온 레이저 해금',
    crowdCount: 85,
    rows: 4,
    payMultiplier: 2,
    themeColorHex: 0xFF00F0FF,
    bgTopHex: 0xFF06152D,
    bgBottomHex: 0xFF040711,
  ),
  Venue(
    id: 2,
    badge: 'STAGE 3',
    name: '강남 메가 클럽',
    sub: '관객 220명 · 개런티 배율 x4.0 · 초대형 LED 월 & CO2 제트',
    crowdCount: 220,
    rows: 6,
    payMultiplier: 4,
    themeColorHex: 0xFFFF2A85,
    bgTopHex: 0xFF1F0626,
    bgBottomHex: 0xFF08020D,
  ),
  Venue(
    id: 3,
    badge: 'FINAL STAGE',
    name: '월드 디제이 페스티벌',
    sub: '관객 550명+ · 개런티 배율 x10.0 · 밤하늘 불꽃놀이 & 메가 레이저 쇼',
    crowdCount: 550,
    rows: 9,
    payMultiplier: 10,
    themeColorHex: 0xFFFFE600,
    bgTopHex: 0xFF090420,
    bgBottomHex: 0xFF020108,
  ),
];
