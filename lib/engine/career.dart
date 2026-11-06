/// 순수 Dart 모델 — Flutter import 없음.
/// 커리어 누적치: 공연 개런티(달러)와 팬덤 수.
/// 세션 내에서만 유지된다 (제미나이 원본도 세션 단위).
/// 홈 화면이 들고 있다가 게임 결과를 받아 누적한다.

class Career {
  int cash = 450;
  int fans = 120;

  void addReward({required int cash, required int fans}) {
    this.cash += cash;
    this.fans += fans;
  }
}
