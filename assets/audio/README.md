# assets/audio

프로토타입 곡 파일이 들어가는 폴더.

- `prototype_drop.mp3` — tools/make_track.py로 합성한 128 BPM 프로토타입 곡
  (67.5초, 드롭 22.5초·45.0초). 이 MP3는 바이너리라 GitHub 커넥터
  스냅샷 푸시로 올릴 수 없어서, 채팅 첨부로 따로 전달된다.
  맥북에서 이 폴더에 파일을 넣어주세요.

- `prototype_drop.wav` — 합성 원본(무손실). 앱에는 필요 없어서
  GitHub에는 올리지 않아도 됩니다. MP3만 있으면 됩니다.

## Suno 곡으로 교체할 때

1. Suno에서 만든 곡 MP3를 이 폴더에 넣는다. (예: `suno_festival_anthem.mp3`)
2. `lib/data/songs.dart`에 새 `SongMetadata`를 추가한다.
   - `bpm`: Suno 곡 정보에 표시된 BPM.
   - `events`: 드롭·빌드업 타이밍을 곡을 들으며 마킹한다.
     파형에서 드롭 시작 지점을 찾아 초 단위로 기록하면 된다.
3. `lib/screens/home_screen.dart`의 곡 카드를 새 곡으로 바꾼다.
