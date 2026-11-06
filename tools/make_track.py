#!/usr/bin/env python3
"""DROP THE BEAT 프로토타입 곡 합성기.

128 BPM, 4/4, 36마디, 67.5초 EDM 트랙을 numpy로 합성한다.
곡 구조는 lib/data/songs.dart의 마디 지도와 정확히 일치한다:

    인트로       마디 1-4    0.0-7.5초
    빌드업       마디 5-12   7.5-22.5초
    드롭 1       마디 13-20  22.5-37.5초
    브레이크다운 마디 21-24  37.5-45.0초
    드롭 2       마디 25-32  45.0-60.0초
    아웃트로     마디 33-36  60.0-67.5초

사용법:
    python3 tools/make_track.py
    -> assets/audio/prototype_drop.wav (44.1kHz 16bit)
    -> ffmpeg으로 MP3 인코딩: assets/audio/prototype_drop.mp3

Suno 곡으로 교체하면 이 스크립트는 더 이상 필요 없다.
"""

import os

import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, sosfilt

SR = 44100
BPM = 128
BEAT = 60.0 / BPM          # 0.46875초
BAR = BEAT * 4             # 1.875초
N_BARS = 36
DURATION = N_BARS * BAR    # 67.5초

rng = np.random.default_rng(7)

# 코드 진행: Am - F - C - G (마디마다 한 코드)
CHORDS = [
    ([110.00, 130.81, 164.81], 55.00),   # Am
    ([87.31, 110.00, 130.81], 43.65),    # F
    ([130.81, 164.81, 196.00], 65.41),   # C
    ([98.00, 123.47, 146.83], 49.00),    # G
]

# A 마이너 펜타토닉 리드 음계
PENTA = [440.00, 523.25, 587.33, 659.25, 783.99, 880.00]


def _t(dur):
    return np.arange(int(dur * SR)) / SR


def _env(n, attack, decay):
    """간단한 attack/decay 엔벨로프."""
    t = np.arange(n) / SR
    a = np.clip(t / max(attack, 1e-6), 0, 1)
    d = np.exp(-t / max(decay, 1e-6))
    return a * d


def _lowpass(x, cutoff):
    sos = butter(4, cutoff, btype="low", fs=SR, output="sos")
    return sosfilt(sos, x)


def _saw(freq, dur, harmonics=8):
    t = _t(dur)
    out = np.zeros_like(t)
    for k in range(1, harmonics + 1):
        out += np.sin(2 * np.pi * freq * k * t) / k
    return out * 0.6


def kick(dur=0.30):
    """피치가 150Hz에서 45Hz로 떨어지는 킥."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    freq = 150 * np.exp(-t * 28) + 45
    phase = 2 * np.pi * np.cumsum(freq) / SR
    return np.sin(phase) * np.exp(-t * 20)


def hat(dur=0.06, open_=False):
    """하이햇: 고역 노이즈 짧은 버스트."""
    n = int(dur * SR)
    noise = rng.standard_normal(n)
    hp = np.diff(noise, prepend=0.0)
    decay = 0.010 if open_ else 0.004
    return hp * np.exp(-np.arange(n) / SR / decay) * 0.5


def clap(dur=0.18):
    """클래프: 노이즈 3연타 + 감쇠."""
    n = int(dur * SR)
    noise = rng.standard_normal(n)
    burst = np.zeros(n)
    for start in (0, int(0.012 * SR), int(0.024 * SR)):
        end = min(n, start + int(0.02 * SR))
        burst[start:end] += 1.0
    return noise * burst * np.exp(-np.arange(n) / SR / 0.03) * 0.8


def bass_note(freq, dur):
    """쏘우 베이스 1음."""
    return _lowpass(_saw(freq, dur, harmonics=5), 700) * _env(
        int(dur * SR), 0.005, 0.12
    )


def pad(freqs, dur):
    """디튠 패드: 코드 음들을 느리게 울린다."""
    n = int(dur * SR)
    out = np.zeros(n)
    for f in freqs:
        out += _saw(f * 1.003, dur, harmonics=6) * 0.5
        out += _saw(f * 0.997, dur, harmonics=6) * 0.5
    out = _lowpass(out, 1400)
    env = np.clip(np.arange(n) / SR / 0.4, 0, 1)  # 느린 어택
    env *= np.clip((dur - np.arange(n) / SR) / 0.4, 0, 1)  # 릴리스
    return out * env * 0.35


def stab(freqs, dur=0.22):
    """드롭 코드 스탭."""
    n = int(dur * SR)
    out = np.zeros(n)
    for f in freqs:
        out += _saw(f, dur, harmonics=6)
    return _lowpass(out, 2500) * _env(n, 0.005, 0.07) * 0.5


def lead_note(freq, dur):
    """리드 1음: 스퀘어 계열."""
    t = _t(dur)
    out = np.zeros_like(t)
    for k in (1, 3, 5):
        out += np.sin(2 * np.pi * freq * k * t) / k
    return out * _env(int(dur * SR), 0.005, 0.09) * 0.4


def riser(dur):
    """빌드업 라이저: 상승 노이즈 + 스윕."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    noise = rng.standard_normal(n)
    hp = np.diff(noise, prepend=0.0)
    sweep_freq = 200 * (1600 / 200) ** (t / dur)
    sweep = np.sin(2 * np.pi * np.cumsum(sweep_freq) / SR)
    gain = np.clip(t / dur, 0, 1) ** 2
    return (hp * 0.4 + sweep * 0.3) * gain


def crash(dur=1.5):
    """크래시 심벌: 긴 노이즈 감쇠."""
    n = int(dur * SR)
    noise = rng.standard_normal(n)
    hp = np.diff(noise, prepend=0.0)
    return hp * np.exp(-np.arange(n) / SR / 0.45) * 0.6


def snare_roll(dur, hits=16):
    """스네어 롤: 점점 빨라지며 커지는 16연타."""
    out = np.zeros(int(dur * SR))
    step = dur / hits
    for i in range(hits):
        start = int(i * step * SR)
        seg = clap(0.09) * (0.3 + 0.7 * i / hits)
        end = min(len(out), start + len(seg))
        out[start:end] += seg[: end - start]
    return out


def add(mix, start_sec, seg, gain=1.0):
    """믹스에 구간 오디오를 더한다."""
    start = int(start_sec * SR)
    end = min(len(mix), start + len(seg))
    mix[start:end] += seg[: end - start] * gain


def main():
    mix = np.zeros(int(DURATION * SR))

    # 리드 리프 패턴 (드롭 마디마다 8분음표 8개, 고정 패턴)
    riff = [0, 1, 3, 5, 4, 3, 2, 1]

    for bar in range(N_BARS):
        bar_start = bar * BAR
        chord, bass_root = CHORDS[bar % 4]
        section = (
            "intro" if bar < 4 else
            "build" if bar < 12 else
            "drop1" if bar < 20 else
            "break" if bar < 24 else
            "drop2" if bar < 32 else
            "outro"
        )

        # 킥: 인트로·빌드·드롭은 4온더플로어, 브레이크는 1박만, 아웃트로는 유지.
        if section in ("intro", "build", "drop1", "drop2", "outro"):
            for b in range(4):
                add(mix, bar_start + b * BEAT, kick())
        elif section == "break":
            add(mix, bar_start, kick())

        # 하이햇: 오프비트 8분. 드롭은 16분으로 촘촘하게.
        if section in ("intro", "build", "drop1", "drop2"):
            step = BEAT / 2 if section in ("drop1", "drop2") else BEAT
            t = bar_start + BEAT / 2
            while t < bar_start + BAR - 0.01:
                add(mix, t, hat(open_=(section in ("drop1", "drop2"))), gain=0.8)
                t += step

        # 클래프: 빌드·드롭에서 2·4박.
        if section in ("build", "drop1", "drop2"):
            add(mix, bar_start + BEAT, clap())
            add(mix, bar_start + BEAT * 3, clap())

        # 베이스: 빌드·드롭에서 오프비트 8분 루트음.
        if section in ("build", "drop1", "drop2"):
            for i in range(8):
                add(mix, bar_start + i * BEAT / 2 + BEAT / 2,
                    bass_note(bass_root, BEAT / 2), gain=0.9)

        # 패드: 인트로·브레이크·아웃트로에서 마디 코드.
        if section in ("intro", "break", "outro"):
            add(mix, bar_start, pad(chord, BAR), gain=0.9)

        # 드롭: 코드 스탭(오프비트) + 리드 리프(8분음표).
        if section in ("drop1", "drop2"):
            for i in range(4):
                add(mix, bar_start + i * BEAT + BEAT / 2,
                    stab(chord), gain=0.9)
            for i in range(8):
                note = PENTA[riff[(i + bar) % len(riff)]]
                add(mix, bar_start + i * BEAT / 2,
                    lead_note(note, BEAT / 2), gain=0.9)

        # 빌드업 후반 4마디: 라이저. 마지막 2마디: 스네어 롤.
        if section == "build" and bar >= 8:
            add(mix, bar_start, riser(BAR), gain=0.9)
        if section == "build" and bar >= 10:
            add(mix, bar_start, snare_roll(BAR), gain=0.9)

        # 드롭 시작 크래시.
        if bar in (12, 24):
            add(mix, bar_start, crash(), gain=0.9)

    # 마스터: 페이드 인/아웃 + 소프트 클립 + 정규화.
    n = len(mix)
    fade_in = np.clip(np.arange(n) / SR / 0.5, 0, 1)
    fade_out = np.clip((DURATION - np.arange(n) / SR) / 2.0, 0, 1)
    mix = np.tanh(mix * 0.9) * fade_in * fade_out
    peak = np.max(np.abs(mix))
    mix = mix / peak * 0.89

    out_dir = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "assets", "audio",
    )
    os.makedirs(out_dir, exist_ok=True)
    wav_path = os.path.join(out_dir, "prototype_drop.wav")
    wavfile.write(wav_path, SR, (mix * 32767).astype(np.int16))

    rms = float(np.sqrt(np.mean(mix ** 2)))
    print(f"WAV 저장: {wav_path}")
    print(f"길이: {DURATION:.2f}초 (36마디, 128 BPM)")
    print(f"피크: {peak:.3f} -> 정규화 후 0.89, RMS: {rms:.3f}")
    print("드롭 시각: 22.50초 (마디 13), 45.00초 (마디 25)")


if __name__ == "__main__":
    main()
