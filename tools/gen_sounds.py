#!/usr/bin/env python3
"""Pixpfs sound generator - synthesizes all SFX + music as WAV files."""
import os
import numpy as np
from scipy.io import wavfile

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sounds")
os.makedirs(OUT, exist_ok=True)
SR = 44100
rng = np.random.default_rng(42)

def save(name, data, norm=True):
    if norm:
        m = np.max(np.abs(data)) or 1.0
        data = data / m * 0.88
    d16 = (data * 32767).astype(np.int16)
    wavfile.write(os.path.join(OUT, name), SR, d16)
    print("wrote", name)

def t(dur): return np.arange(int(SR * dur)) / SR

def env_exp(dur, decay):
    x = t(dur)
    return np.exp(-x * decay)

def lowpass(sig, alpha):
    out = np.empty_like(sig)
    acc = 0.0
    for i, s in enumerate(sig):
        acc += alpha * (s - acc)
        out[i] = acc
    return out

def sine(freq, dur, decay=6.0):
    x = t(dur)
    return np.sin(2 * np.pi * freq * x) * env_exp(dur, decay)

def pad_to(a, n):
    if len(a) < n:
        a = np.concatenate([a, np.zeros(n - len(a))])
    return a

def shot(dur, decay, thump_freq, crack=True, lp=0.35):
    n = rng.standard_normal(int(SR * dur)) * env_exp(dur, decay)
    n = lowpass(n, lp)
    thump = sine(thump_freq, dur, decay * 0.6) * 0.9
    out = n * 1.2 + thump
    if crack:
        out[:600] += rng.standard_normal(600) * 0.7 * np.linspace(1, 0, 600)
    return out

def click(freq=900, dur=0.03, vol=1.0):
    x = t(dur)
    return np.sin(2 * np.pi * freq * x) * np.linspace(vol, 0, len(x))

def ding(freq=1400, dur=0.06):
    x = t(dur)
    return (np.sin(2 * np.pi * freq * x) + 0.5 * np.sin(2 * np.pi * freq * 2.01 * x)) * env_exp(dur, 30)

def whoosh(dur, f0=900, f1=200):
    x = t(dur)
    n = rng.standard_normal(len(x)) * env_exp(dur, 4)
    sweep = np.sin(2 * np.pi * np.cumsum(np.linspace(f0, f1, len(x))) / SR) * env_exp(dur, 3) * 0.4
    return lowpass(n, 0.08) * 0.7 + sweep

def music_loop(bpm, bars, chords, bass_pat, arp, lead=None):
    """Synthwave-ish loop via additive synthesis."""
    beat = 60.0 / bpm
    total = bars * 4 * beat
    n = int(total * SR)
    mix = np.zeros(n)
    step_beat = int(beat * SR)
    # bass
    for i in range(bars * 4):
        f = bass_pat[i % len(bass_pat)]
        seg = np.zeros(n)
        s = i * step_beat
        dur = int(step_beat * 0.9)
        x = np.arange(dur) / SR
        wave = np.sign(np.sin(2 * np.pi * f * x)) * 0.6 + np.sin(2 * np.pi * f * x) * 0.4
        seg[s:s + dur] += wave * env_exp(dur / SR, 5) * 0.5
        mix += seg
    # chords (pad)
    for bar in range(bars):
        chord = chords[bar % len(chords)]
        s = bar * 4 * step_beat
        dur = int(4 * step_beat * 0.98)
        x = np.arange(dur) / SR
        pad = np.zeros(dur)
        for f in chord:
            pad += np.sin(2 * np.pi * f * x) + 0.5 * np.sin(2 * np.pi * f * 2 * x)
        seg = np.zeros(n)
        seg[s:s + dur] += pad * 0.10
        mix += seg
    # arp
    arp_len = int(step_beat / 2 * SR)
    for i in range(bars * 8):
        f = arp[i % len(arp)]
        s = i * int(step_beat / 2 * SR)
        x = np.arange(arp_len) / SR
        wave = np.sin(2 * np.pi * f * x) * env_exp(arp_len / SR, 8)
        seg = np.zeros(n)
        seg[s:s + arp_len] += wave * 0.22
        mix += seg
    # hat
    for i in range(bars * 8):
        s = i * int(step_beat / 2 * SR)
        h = rng.standard_normal(int(0.03 * SR)) * np.linspace(0.15, 0, int(0.03 * SR))
        seg = np.zeros(n)
        seg[s:s + len(h)] += h * 0.5
        mix += seg
    # kick
    for i in range(bars * 4):
        s = i * step_beat
        k = sine(55, 0.25, 14) * 0.9
        seg = np.zeros(n)
        seg[s:s + len(k)] += k * 0.55
        mix += seg
    return mix

def freq(n):  # midi to hz
    return 440.0 * 2 ** ((n - 69) / 12)

if __name__ == "__main__":
    save("shot_rifle.wav", shot(0.16, 22, 140))
    save("shot_smg.wav", shot(0.09, 34, 190, lp=0.5))
    save("shot_sniper.wav", shot(0.55, 7, 85) + pad_to(whoosh(0.4, 2000, 300) * 0.4, int(SR * 0.55)))
    save("shot_shotgun.wav", shot(0.32, 12, 90, lp=0.28))
    save("shot_pistol.wav", shot(0.11, 30, 170, lp=0.45))
    save("footstep.wav", lowpass(rng.standard_normal(int(0.07 * SR)) * env_exp(0.07, 30), 0.12) * 0.8)
    save("jump.wav", whoosh(0.18, 700, 1400) * 0.7)
    save("land.wav", lowpass(rng.standard_normal(int(0.1 * SR)) * env_exp(0.1, 26), 0.1))
    save("slide.wav", whoosh(0.45, 500, 150))
    save("wallrun.wav", whoosh(0.5, 300, 900) * 0.5)
    save("reload.wav", np.concatenate([click(700, 0.04, 0.8), np.zeros(int(0.18 * SR)), click(500, 0.05, 0.9), np.zeros(int(0.1 * SR)), ding(1100, 0.05) * 0.5]))
    save("empty_click.wav", click(1200, 0.02, 0.5))
    save("ui_click.wav", ding(950, 0.05))
    save("ui_hover.wav", ding(1500, 0.03) * 0.4)
    save("hitmarker.wav", np.concatenate([ding(1600, 0.035), np.zeros(int(0.012 * SR)), ding(1300, 0.03)]) * 0.9)
    save("headshot.wav", np.concatenate([ding(2100, 0.04), ding(2600, 0.05)]) * 0.9)
    save("kill.wav", np.concatenate([ding(880, 0.06), ding(1310, 0.09)]))
    save("damage.wav", sine(160, 0.18, 10) * 0.8 + lowpass(rng.standard_normal(int(0.18 * SR)), 0.05) * 0.2)
    save("heartbeat.wav", np.concatenate([sine(58, 0.12, 10), np.zeros(int(0.22 * SR)), sine(52, 0.1, 10)]) * 0.9)
    save("respawn.wav", whoosh(0.4, 300, 1600))
    save("match_start.wav", np.concatenate([whoosh(1.2, 200, 2400) * 0.5, ding(600, 0.3)]) * 0.9)
    save("victory.wav", np.concatenate([sine(freq(72), 0.2, 3), sine(freq(76), 0.2, 3), sine(freq(79), 0.2, 3), sine(freq(84), 0.5, 2)]))
    save("defeat.wav", np.concatenate([sine(freq(67), 0.25, 3), sine(freq(63), 0.25, 3), sine(freq(58), 0.6, 2)]))
    # lobby music: Am F C G synthwave, 100 bpm, 4 bars
    save("music_lobby.wav", music_loop(100, 4,
        chords=[[freq(57), freq(60), freq(64)], [freq(53), freq(57), freq(60)], [freq(48), freq(52), freq(55)], [freq(55), freq(59), freq(62)]],
        bass_pat=[freq(33), freq(33), freq(40), freq(33), freq(29), freq(29), freq(36), freq(36)],
        arp=[freq(69), freq(72), freq(76), freq(72), freq(65), freq(69), freq(72), freq(69)]))
    # match music: tense, minor, 120 bpm
    save("music_match.wav", music_loop(120, 4,
        chords=[[freq(57), freq(60), freq(63)], [freq(55), freq(58), freq(62)], [freq(53), freq(57), freq(60)], [freq(51), freq(55), freq(58)]],
        bass_pat=[freq(33), freq(33), freq(33), freq(31), freq(29), freq(29), freq(29), freq(28)],
        arp=[freq(81), freq(76), freq(72), freq(76), freq(79), freq(74), freq(70), freq(74)]))
    print("ALL SOUNDS DONE")
