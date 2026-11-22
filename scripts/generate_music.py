#!/usr/bin/env python3
"""Synthesize a gentle, seamless music-box loop (C major, 92 BPM, 16 bars).
Writes ios/App/App/Audio/music_loop.m4a. Original composition, no samples."""
import math, struct, wave, subprocess, os, tempfile
SR = 22050
BPM = 92
BEAT = 60 / BPM
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "ios", "App", "App", "Audio", "music_loop")

def freq(n):  # MIDI note -> Hz
    return 440 * 2 ** ((n - 69) / 12)

# chord roots per bar (C, Am, F, G) x 4, bass two octaves down
prog = [48, 45, 41, 43] * 4
chords = {48: [60, 64, 67], 45: [57, 60, 64], 41: [53, 57, 60], 43: [55, 59, 62]}
# melody: (beat offset within 4-bar phrase, midi, length in beats); 4 phrases with variation
A = [(0,72,1),(1,76,1),(2,79,1.5),(3.5,76,.5),(4,74,1),(5,72,1),(6,74,2),
     (8,72,1),(9,69,1),(10,72,1.5),(11.5,74,.5),(12,76,1),(13,74,1),(14,72,2)]
B = [(0,76,1),(1,79,1),(2,81,1.5),(3.5,79,.5),(4,76,1),(5,74,1),(6,72,2),
     (8,69,1),(9,72,1),(10,74,1),(11,76,1),(12,74,1.5),(13.5,72,.5),(14,72,2)]
melody = []
for i, ph in enumerate([A, B, A, B]):
    melody += [(o + i * 16, n, l) for o, n, l in ph]

total = int(SR * BEAT * 64)
buf = [0.0] * total

def bell(start_beat, note, length, amp):
    f = freq(note); s0 = int(start_beat * BEAT * SR); n = int((length * BEAT + 1.2) * SR)
    for i in range(n):
        idx = (s0 + i) % total          # wrap tail around -> seamless loop
        t = i / SR
        env = min(1, t / 0.004) * math.exp(-3.2 * t)
        v = math.sin(2*math.pi*f*t) + 0.35*math.sin(2*math.pi*2*f*t)*math.exp(-4*t) + 0.12*math.sin(2*math.pi*3*f*t)*math.exp(-6*t)
        buf[idx] += v * env * amp

def pad(start_beat, notes, amp):
    s0 = int(start_beat * BEAT * SR); n = int(4 * BEAT * SR)
    for i in range(n):
        t = i / SR
        env = math.sin(math.pi * min(1, i / n))  # soft swell per bar
        v = sum(math.sin(2*math.pi*freq(x)*t) for x in notes) / len(notes)
        buf[(s0 + i) % total] += v * env * amp

for bar, r in enumerate(prog):
    pad(bar * 4, chords[r], 0.10)
    bell(bar * 4, r - 12 + 12, 2, 0.22)        # soft bass note
    for k, x in enumerate([0, 1, 2, 1]):        # gentle arpeggio on beats
        bell(bar * 4 + k, chords[r][x], 1, 0.10)
for o, nn, l in melody:
    bell(o, nn, l, 0.30)

peak = max(abs(x) for x in buf)
with tempfile.TemporaryDirectory() as d:
    wav = os.path.join(d, "m.wav")
    with wave.open(wav, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(x / peak * 0.8 * 32767)) for x in buf))
    subprocess.run(["afconvert", "-f", "m4af", "-d", "aac", "-b", "64000", wav, OUT + ".m4a"], check=True)
print("wrote", OUT + ".m4a", f"{total/SR:.1f}s")
