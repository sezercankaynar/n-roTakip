"""Uygulamadaki ses dosyalarını üretir: python3 tool/gen_sounds.py"""
import math, struct, wave

RATE = 44100

def write(path, samples):
    with wave.open(path, "w") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s)) * 32000)) for s in samples))

def tone(freq, dur, vol=0.9):
    n = int(RATE * dur)
    fade = int(RATE * 0.005)
    out = []
    for i in range(n):
        env = min(1, i / fade, (n - i) / fade)
        out.append(vol * env * math.sin(2 * math.pi * freq * i / RATE))
    return out

def silence(dur):
    return [0.0] * int(RATE * dur)

# Metronom: 110/dk, tek vuruşluk döngü (60/110 sn)
beat = 60 / 110
write("assets/sounds/metronome_110.wav", tone(1500, 0.04) + silence(beat - 0.04))
# Uyarı: üç kısa yüksek bip
write("assets/sounds/alarm.wav", (tone(1000, 0.15) + silence(0.08)) * 3)
# Bilgi: tek yumuşak bip
write("assets/sounds/chime.wav", tone(800, 0.25, 0.7))
