#!/usr/bin/env python3
"""Génère tous les bruitages et musiques d'EPO par synthèse (aucun fichier externe).

Usage : python3 tools/gen_audio.py   (depuis le dossier epo/)
Les fichiers .wav sont écrits dans assets/audio/.
"""
import math
import os
import random
import struct
import wave

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
random.seed(1947)


def write(name, samples, sr=SR):
    os.makedirs(OUT, exist_ok=True)
    peak = max(1e-6, max(abs(s) for s in samples))
    gain = 0.9 / peak if peak > 0.9 else 1.0
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s * gain)) * 32767)) for s in samples))


def n(sec):
    return int(sec * SR)


def env(i, total, attack=0.005, decay=None):
    t = i / SR
    a = min(1.0, t / attack) if attack > 0 else 1.0
    if decay is None:
        return a * (1 - i / total)
    return a * math.exp(-t / decay)


def lowpass(samples, alpha):
    out, y = [], 0.0
    for s in samples:
        y += alpha * (s - y)
        out.append(y)
    return out


def highpass(samples, alpha):
    out, prev_x, prev_y = [], 0.0, 0.0
    for s in samples:
        y = alpha * (prev_y + s - prev_x)
        out.append(y)
        prev_x, prev_y = s, y
    return out


def noise(count):
    return [random.uniform(-1, 1) for _ in range(count)]


def mix(*tracks):
    length = max(len(t) for t in tracks)
    return [sum(t[i] for t in tracks if i < len(t)) for i in range(length)]


def tone(freq, sec, wave_type="sine", vol=1.0, attack=0.005, decay=None, vibrato=0.0):
    out = []
    total = n(sec)
    phase = 0.0
    for i in range(total):
        f = freq * (1 + vibrato * math.sin(2 * math.pi * 5.5 * i / SR))
        phase += 2 * math.pi * f / SR
        if wave_type == "sine":
            v = math.sin(phase)
        elif wave_type == "square":
            v = 1.0 if math.sin(phase) > 0 else -1.0
        elif wave_type == "brass":
            v = sum(math.sin(phase * h) / h ** 1.1 for h in range(1, 7))
        else:
            v = 2 * ((phase / (2 * math.pi)) % 1) - 1
        out.append(v * vol * env(i, total, attack, decay))
    return out


def silence(sec):
    return [0.0] * n(sec)


def concat(*parts):
    out = []
    for p in parts:
        out += p
    return out


def place(track, sample, at_sec, vol=1.0):
    start = n(at_sec)
    need = start + len(sample)
    if need > len(track):
        track += [0.0] * (need - len(track))
    for i, s in enumerate(sample):
        track[start + i] += s * vol
    return track


# --- Interface -------------------------------------------------------------------
def ui_sounds():
    write("click", [s * env(i, n(0.04), 0.001, 0.008) for i, s in enumerate(mix(tone(1800, 0.04, vol=0.5), noise(n(0.04))))])
    write("hover", [s * 0.3 for s in tone(2400, 0.02, attack=0.001, decay=0.005)])
    write("confirm", concat(tone(660, 0.07, "square", 0.25, decay=0.05), tone(990, 0.12, "square", 0.25, decay=0.07)))
    write("error", tone(170, 0.22, "square", 0.3, decay=0.12))
    write("coin", concat(tone(1320, 0.06, vol=0.5, decay=0.04), tone(1760, 0.25, vol=0.5, decay=0.1)))
    sw = noise(n(0.14))
    write("card", [s * math.sin(math.pi * i / len(sw)) * 0.6 for i, s in enumerate(highpass(sw, 0.7))])
    pg = lowpass(noise(n(0.25)), 0.3)
    write("page", [s * math.sin(math.pi * i / len(pg)) ** 2 for i, s in enumerate(pg)])
    thud = [math.sin(2 * math.pi * 70 * i / SR) * env(i, n(0.3), 0.002, 0.08) for i in range(n(0.3))]
    creak = [s * env(i, n(0.3), 0.01, 0.1) * 0.4 for i, s in enumerate(lowpass(noise(n(0.3)), 0.08))]
    write("crate", mix(thud, creak))
    stamp = mix([math.sin(2 * math.pi * 90 * i / SR) * env(i, n(0.2), 0.001, 0.05) for i in range(n(0.2))],
                [s * env(i, n(0.2), 0.001, 0.02) * 0.5 for i, s in enumerate(noise(n(0.2)))])
    write("stamp", stamp)
    notes = [523, 659, 784, 1047]
    write("rare", concat(*[tone(f, 0.09, "sine", 0.4, decay=0.08) for f in notes]))
    leg = concat(*[tone(f, 0.11, "brass", 0.3, decay=0.12) for f in notes + [1319, 1568]])
    write("legendary", leg + tone(2093, 0.6, "sine", 0.3, decay=0.25))
    # Clairon de promotion (sol do mi sol)
    bugle = concat(tone(392, 0.16, "brass", 0.35, 0.01), silence(0.03), tone(523, 0.16, "brass", 0.35, 0.01), silence(0.03),
                   tone(659, 0.16, "brass", 0.35, 0.01), silence(0.03), tone(784, 0.7, "brass", 0.35, 0.01, vibrato=0.004))
    write("rankup", bugle)
    write("victory", concat(tone(523, 0.2, "brass", 0.35), tone(659, 0.2, "brass", 0.35), tone(784, 0.2, "brass", 0.35), tone(1047, 0.9, "brass", 0.35, vibrato=0.005)))
    write("defeat", concat(tone(392, 0.35, "brass", 0.3), tone(370, 0.35, "brass", 0.3), tone(349, 0.35, "brass", 0.3), tone(330, 1.0, "brass", 0.3, vibrato=0.01)))
    # Sifflet de tranchée (début de bataille)
    write("whistle", [s * (1 if (i // n(0.2)) % 2 == 0 or i > n(0.45) else 0.2) for i, s in enumerate(tone(2600, 0.8, "sine", 0.4, 0.01, vibrato=0.012))])


# --- Combat ---------------------------------------------------------------------
def gun(name, dur, body_freq, crack_decay, body_decay, lp):
    total = n(dur)
    crack = [s * env(i, total, 0.0005, crack_decay) for i, s in enumerate(noise(total))]
    body = [s * env(i, total, 0.001, body_decay) for i, s in enumerate(lowpass(noise(total), lp))]
    thump = [math.sin(2 * math.pi * body_freq * i / SR) * env(i, total, 0.001, body_decay * 0.6) for i in range(total)]
    write(name, mix([c * 0.6 for c in crack], [b * 1.6 for b in body], [t * 0.8 for t in thump]))


def combat_sounds():
    gun("rifle", 0.5, 110, 0.01, 0.08, 0.25)
    gun("musket", 0.9, 80, 0.02, 0.2, 0.12)
    gun("mg", 0.18, 120, 0.006, 0.04, 0.3)
    gun("cannon", 1.8, 45, 0.03, 0.5, 0.04)
    gun("explosion", 2.2, 38, 0.05, 0.7, 0.03)
    gun("tank_gun", 1.4, 55, 0.02, 0.35, 0.06)
    # Choc métallique d'épées
    total = n(0.6)
    partials = [(2100, 0.12), (3370, 0.08), (5230, 0.05), (1230, 0.2)]
    clang = [sum(math.sin(2 * math.pi * f * i / SR) * math.exp(-i / SR / d) for f, d in partials) * 0.25 for i in range(total)]
    write("sword", mix(clang, [s * env(i, total, 0.0005, 0.005) for i, s in enumerate(noise(total))]))
    # Flèche / sifflement
    total = n(0.35)
    wh = highpass(noise(total), 0.9)
    write("arrow", [s * math.sin(math.pi * i / total) * 0.6 for i, s in enumerate(wh)])
    # Impact sourd
    total = n(0.18)
    write("hit", mix([math.sin(2 * math.pi * 140 * i / SR) * env(i, total, 0.001, 0.03) for i in range(total)],
                     [s * env(i, total, 0.001, 0.015) * 0.6 for i, s in enumerate(lowpass(noise(total), 0.3))]))
    # Mécanisme d'arme (clic-clac)
    click = lambda f: [math.sin(2 * math.pi * f * i / SR) * env(i, n(0.05), 0.0005, 0.006) + random.uniform(-1, 1) * env(i, n(0.05), 0.0005, 0.003) for i in range(n(0.05))]
    write("mech", concat(click(2500), silence(0.07), click(1700)))
    write("part", click(1900))
    # Moteur de char (boucle)
    total = n(2.0)
    eng = [(math.sin(2 * math.pi * 32 * i / SR) * 0.6 + (1 if math.sin(2 * math.pi * 16 * i / SR) > 0.7 else 0) * 0.3) for i in range(total)]
    write("engine", [s * 0.6 for s in lowpass(mix(eng, [x * 0.3 for x in noise(total)]), 0.08)])


# --- Musiques ---------------------------------------------------------------------
def snare():
    total = n(0.18)
    return mix([s * env(i, total, 0.001, 0.05) * 0.7 for i, s in enumerate(highpass(noise(total), 0.6))],
               [math.sin(2 * math.pi * 190 * i / SR) * env(i, total, 0.001, 0.03) * 0.4 for i in range(total)])


def kick():
    total = n(0.3)
    out, ph = [], 0.0
    for i in range(total):
        f = 50 + 70 * math.exp(-i / SR / 0.03)
        ph += 2 * math.pi * f / SR
        out.append(math.sin(ph) * env(i, total, 0.001, 0.12))
    return out


def march():
    bpm = 108
    beat = 60 / bpm
    bars = 8
    track = silence(bars * 4 * beat + 1)
    sn, kk = snare(), kick()
    for bar in range(bars):
        for b in range(4):
            t = (bar * 4 + b) * beat
            if b in (0, 2):
                place(track, kk, t, 0.8)
            place(track, sn, t + beat / 2, 0.35)
            if b == 3:
                place(track, sn, t + beat * 0.75, 0.25)
            place(track, sn, t, 0.18)
    # Mélodie de fifre (gamme de ré majeur)
    melody = [74, 76, 78, 81, 79, 78, 76, 74, 76, 78, 79, 81, 83, 81, 78, 76,
              74, 76, 78, 81, 79, 78, 76, 78, 79, 78, 76, 74, 73, 74, 76, 74]
    for k, midi in enumerate(melody):
        f = 440 * 2 ** ((midi - 69) / 12)
        place(track, tone(f, beat * 0.95, "sine", 0.12, 0.02, decay=0.5, vibrato=0.006), k * beat * 2 / 2 * 1.0 + 0.0, 1.0)
    # Basse
    bass = [50, 50, 55, 57, 50, 50, 57, 50]
    for bar, midi in enumerate(bass):
        f = 440 * 2 ** ((midi - 69) / 12)
        place(track, tone(f, beat * 3.6, "brass", 0.1, 0.03, decay=1.2), bar * 4 * beat, 1.0)
    write("music_march", track[: n(bars * 4 * beat)])


def ambient():
    dur = 16.0
    track = silence(dur)
    chords = [[50, 57, 62, 65], [46, 53, 58, 62], [48, 55, 60, 64], [45, 52, 57, 61]]
    for c, chord in enumerate(chords):
        for midi in chord:
            f = 440 * 2 ** ((midi - 69) / 12)
            seg = [math.sin(2 * math.pi * f * i / SR) * 0.07 * math.sin(math.pi * i / n(4.6)) for i in range(n(4.6))]
            place(track, seg, c * 4.0 - (0.3 if c else 0), 1.0)
    # Tambour lointain
    kk = lowpass(kick(), 0.2)
    for t in [0.0, 4.0, 8.0, 12.0, 2.0, 10.0]:
        place(track, kk, t, 0.25)
    write("music_ambient", track[: n(dur)])


def battle_music():
    bpm = 132
    beat = 60 / bpm
    bars = 8
    track = silence(bars * 4 * beat + 1)
    sn, kk = snare(), kick()
    for bar in range(bars):
        for b in range(4):
            t = (bar * 4 + b) * beat
            place(track, kk, t, 0.9)
            place(track, sn, t + beat / 2, 0.3)
            place(track, sn, t + beat * 0.75, 0.2)
    riff = [45, 45, 48, 45, 50, 48, 45, 43]
    for bar, midi in enumerate(riff):
        for k in range(4):
            f = 440 * 2 ** ((midi - 69) / 12)
            place(track, tone(f, beat * 0.9, "brass", 0.09, 0.01, decay=0.3), (bar * 4 + k) * beat, 1.0)
    brass = [69, 72, 74, 76, 74, 72, 69, 67]
    for bar, midi in enumerate(brass):
        f = 440 * 2 ** ((midi - 69) / 12)
        place(track, tone(f, beat * 3.5, "brass", 0.08, 0.05, decay=1.5, vibrato=0.004), bar * 4 * beat, 1.0)
    write("music_battle", track[: n(bars * 4 * beat)])


if __name__ == "__main__":
    ui_sounds()
    combat_sounds()
    march()
    ambient()
    battle_music()
    print("Sons générés dans", os.path.abspath(OUT))
