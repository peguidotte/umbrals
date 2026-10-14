"""Original, bounded PCM synthesis for Umbral's UI, magic, impacts and ambience."""
import json
import argparse
import math
from pathlib import Path
import random
import struct
import wave

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--output", type=Path, default=Path(__file__).resolve().parents[1] / "builds/asset-work/audio")
ROOT = parser.parse_args().output.resolve()
if ROOT.is_relative_to(Path(__file__).resolve().parents[1] / "assets"):
    parser.error("Generate into staging, then create a new version with tools/assets.py")
ROOT.mkdir(parents=True, exist_ok=True)
SAMPLE_RATE = 22050
records = []


def write(name, duration, sample):
    frames = bytearray()
    maximum = 0
    energy = 0
    for index in range(int(duration * SAMPLE_RATE)):
        time = index / SAMPLE_RATE
        amplitude = max(-0.85, min(0.85, sample(time, index)))
        value = int(amplitude * 32767)
        maximum = max(maximum, abs(value))
        energy += value * value
        frames.extend(struct.pack('<h', value))
    with wave.open(str(ROOT / f'{name}.wav'), 'wb') as output:
        output.setparams((1, 2, SAMPLE_RATE, 0, 'NONE', 'not compressed'))
        output.writeframes(frames)
    records.append({'asset': name, 'seconds': duration, 'peak_dbfs': round(20 * math.log10(maximum / 32767), 2), 'clipped_samples': 0})


for name, frequencies, duration in [
    ('hover', [440, 660], .05), ('draw', [294, 440], .16),
    ('capture', [330, 440, 660], .5), ('evolve', [294, 440, 587, 880], .7),
    ('fire', [147, 220], .24), ('leaf', [440, 587], .22), ('storm', [196, 784], .18),
]:
    def tone(t, _, frequencies=frequencies, duration=duration):
        attack = min(1, t / .008)
        envelope = attack * (1 - t / duration) ** 2
        return .20 * envelope * sum(math.sin(2 * math.pi * f * t) for f in frequencies) / len(frequencies)
    write(name, duration, tone)

randomizer = random.Random(1201)
noise = [randomizer.uniform(-1, 1) for _ in range(int(.25 * SAMPLE_RATE))]
write('impact', .25, lambda t, i: .23 * math.exp(-t * 26) * (math.sin(2 * math.pi * (88 - t * 70) * t) * .85 + noise[i] * .15))

def pad(t, _):
    fade = min(1, t / .45, (12 - t) / .45)
    waves = sum(math.sin(2 * math.pi * f * t) for f in [110, 146.6666667, 220, 293.3333333]) / 4
    return .12 * max(0, fade) * waves * (.8 + .2 * math.sin(t * math.pi / 6))

write('ambience', 12, pad)
write('boss_pulse', 12, lambda t, _: .14 * math.exp(-((t % .75) * 18)) * math.sin(2 * math.pi * 73.333333 * t) * min(1, t / .2, (12-t) / .2))
(ROOT / 'audio-manifest.json').write_text(json.dumps({'source': 'original deterministic synthesis', 'sample_rate': SAMPLE_RATE, 'mono': True, 'assets': records}, indent=2))
print(f'Generated {len(records)} original audio assets; every source peaks below 0 dBFS.')
