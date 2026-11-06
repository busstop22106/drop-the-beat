# DROP THE BEAT — 클럽 DJ 리듬 게임 (프로토타입 v0.1)

지하 술집에서 월드 페스티벌 헤드라이너까지. 관객이 원하는 타이밍에
변조(드롭)를 넣으면 관객이 환호하는 리듬 게임이다.

## 지금 들어 있는 것

- 곡 1개: `Midnight Drop` (128 BPM, 67.5초, 합성 프로토타입 곡)
- 스테이지 1개: 지하 술집 (관객 20명)
- 핵심 플레이: 비트 트랙 + DROP 패드 탭, Perfect/Good/Miss 판정,
  관객 에너지(Heat) 게이지, 콤보, 환호 애니메이션, 결과 화면(별·점수·관객 리뷰)
- 타이밍 보정 슬라이더 (홈 화면, ±150ms)

## 맥북에서 실행하기

VM에는 Flutter SDK가 없어서 직접 빌드는 못 한다. 맥북에서 한다.

```bash
# 1. 저장소 받기 (처음 한 번)
git clone https://github.com/busstop22106/drop-the-beat.git
cd drop-the-beat

# 2. Flutter 프로젝트 껍데기 만들기 (처음 한 번)
#    아래 명령은 android/ ios/ 등 네이티브 껍데기를 만든다.
#    이미 있는 lib/ pubspec.yaml assets/는 덮어쓰지 않으니,
#    생성 후 git status로 확인하고 필요한 것만 커밋한다.
flutter create --org com.dropbeat --project-name drop_the_beat .

# 3. 프로토타입 곡 MP3 넣기 (처음 한 번)
#    채팅 첨부로 받은 prototype_drop.mp3를 아래 경로에 복사
cp ~/Downloads/prototype_drop.mp3 assets/audio/prototype_drop.mp3

# 4. 실행
flutter pub get
flutter run            # 실기기 연결 후
flutter test           # 엔진 테스트
flutter build apk --release   # APK 빌드
```

MP3를 안 넣어도 앱은 실행된다. 무음으로 비트맵만 돌아가고,
스낵바로 파일이 없다고 알려준다.

## GitHub Actions로 APK 빌드하기 (선택)

`docs/android-apk-workflow.yml`을 맥북에서
`.github/workflows/android-apk.yml`로 복사해 커밋·푸시하면,
이후 main 푸시마다 Actions가 APK를 빌드해 Artifacts에 올린다.
(커넥터 스냅샷 푸시는 `.github/workflows/`를 올릴 수 없어서 직접 복사해야 한다.)

## 구조

```
lib/
  main.dart                 앱 진입점
  theme/app_theme.dart      클럽 네온 테마
  engine/                   순수 Dart (Flutter import 금지 — 테스트 가능)
    song.dart               곡 메타데이터·비트맵 이벤트
    judgment.dart           판정 창·점수
    game_state.dart         에너지·콤보·점수 상태
  data/songs.dart           프로토타입 곡 + 이벤트 시각표
  services/audio_engine.dart audioplayers 래퍼 + 오디오 시계
  screens/                  홈·게임·결과
  widgets/                  관객 캔버스·비트 트랙·에너지 게이지
test/engine_test.dart       판정·점수·상태 테스트
tools/make_track.py         프로토타입 곡 합성기 (numpy)
assets/audio/               곡 파일 (MP3는 첨부로 따로 전달)
docs/android-apk-workflow.yml
```

작명별과 같은 규칙을 따른다: `lib/engine/`은 순수 Dart만,
화면은 UI만, 상태 관리는 setState + ChangeNotifier 없이 타이머 기반.

## 타이밍이 어긋나 보이면

리듬 게임에서 제일 중요한 것은 소리와 화면의 동기화다.

1. 홈 화면의 **타이밍 보정 슬라이더**를 먼저 조정한다.
   소리가 화면보다 늦게 들리면 +방향, 빨리 들리면 −방향이다.
2. 그래도 어긋나면 MP3 인코더 지연이 원인일 수 있다.
   `assets/audio/`에 WAV를 넣고 `assetPath`를 바꾸면 지연이 줄어든다.
3. 그래도 안 되면 오디오 패키지 교체를 검토한다.
   현재 `audioplayers`인데, `just_audio`나 저지연 특화인
   `flutter_soloud`로 바꾸는 것이 다음 수순이다.

## Suno 곡 교체 방법

1. Suno에서 만든 곡 MP3를 `assets/audio/`에 넣는다.
2. `lib/data/songs.dart`에 새 `SongMetadata`를 추가한다.
   - `bpm`: Suno 곡 정보의 BPM.
   - `events`: 곡을 들으며 드롭·빌드업 타이밍을 초 단위로 마킹한다.
     파형에서 드롭 시작 지점을 찾으면 된다.
3. 홈 화면의 곡 카드를 새 곡으로 바꾼다.

Suno 유료 플랜(Pro 이상)으로 만든 곡은 상업적 이용이 가능하다.
구독을 유지하는 전제이며, 약관은 바뀔 수 있으니 출시 전에 한 번 더 확인한다.

## 다음 단계 (프로토타입 이후)

- 곡 6곡 + 스테이지 3개 (홍대 클럽 → 이태원 클럽 → 페스티벌 서브)
- 명성·팬 수·출연료·장비 업그레이드 시스템
- 곡 팩 유료 잠금 해제 (결제 연동 — 정적 구조가 아니라 서버 검증 필요)
- 일시정지, 이펙트 버튼(필터·에코), 관객 요청 미션
- 오디오 지연 실측 후 보정 기본값 조정
