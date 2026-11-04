"""Original deterministic elemental sound design, synchronized to presentation events.

No sampled libraries. Preview mix only; not a production game audio binding.
"""
import io
import json
import wave
import hashlib
from pathlib import Path

import numpy as np

RATE = 48000


def synthesize(spec):
    index = spec['index']
    family = index // 3
    variant = index % 3
    rng = np.random.default_rng(5800 + index)
    output = np.zeros((round(spec['loop'] * RATE), 2), dtype=np.float64)

    def layer(start, duration, amp, pitch, kind, pan=0, decay=5, rising=False):
        count = round(duration * RATE)
        t = np.arange(count) / RATE
        u = t / duration
        noise = rng.standard_normal(count)
        low = np.convolve(noise, np.ones(35) / 35, mode='same')
        high = noise - np.convolve(noise, np.ones(7) / 7, mode='same')
        env = np.minimum(1, t / .009) * np.exp(-u * decay)
        env *= np.minimum(1, (duration - t) / .025)
        if rising:
            env = np.sin(np.pi * u / 2) ** 2 * np.minimum(1, (duration-t)/.025)
        phase = 2 * np.pi * (pitch * t + pitch * (1 if rising else -.42) * t*t / duration / 2)
        tone = np.sin(phase)
        if kind == 'fire':
            signal = low * 2.0 + tone * .28 + high * .07 * (np.sin(t*133)**8)
        elif kind == 'wood':
            signal = tone * np.exp(-t*18) + np.sin(phase*2.73)*.24 + low*.9
            signal += high*.12*(np.sin(t*311)**20)
        elif kind == 'water':
            signal = low*1.7 + np.sin(phase + .8*np.sin(t*39))*.25
            signal += np.sin(phase*2.1)*np.maximum(0,np.sin(t*61))**9*.14
        elif kind == 'electric':
            gate = .35+.65*np.maximum(0,np.sin(t*79))**3
            signal = (high*.12+np.sin(phase)*.26+np.sin(phase*1.99)*.08)*gate + low*.55
        else:
            signal = tone*.7+low*1.8+high*.06
        mono = amp * signal * env
        left, right = np.sqrt((1-pan)/2), np.sqrt((1+pan)/2)
        lo = max(0, round(start*RATE))
        hi = min(len(output),lo+count)
        if hi > lo:
            output[lo:hi,0] += mono[:hi-lo]*left
            output[lo:hi,1] += mono[:hi-lo]*right

    charge_start = spec['start']+.06
    charge_duration = spec['release']-charge_start
    kinds = ['fire','wood','water','electric','electric']
    kind = kinds[family]
    # Quiet intake/strain: a rising texture, then a short gap before the release.
    layer(charge_start, charge_duration-.035, .15, [100,75,180,270,160][family],
          kind, -.55, rising=True)
    release_duration = spec['contact']-spec['release']+.08
    layer(spec['release'], release_duration, .31, [130,92,260,540,210][family]*(1+variant*.10),
          kind, -.1, decay=2)
    if variant == 1:
        layer(spec['release']-.02,.16,.13,380 if family>=3 else 150,kind,-.3)
    for k, beat in enumerate(spec['beats']):
        layer(beat, .48 if family!=3 else .27, .33/(1+k*.25),
              [73,67,115,240,56][family]*(1+variant*.08),kind,.55,decay=5)
        # Short body thump under each contact, lower and longer for a dive.
        layer(beat,.28 if family<4 else .43,.26/(1+k*.3),
              53 if family<4 else 39,'body',.28,decay=7)
    layer(spec['contact']+.13,.57,.09,[125,88,340,620,115][family],kind,.45,decay=5)
    # Gentle saturation keeps transients bounded without peak-normalizing quiet cues.
    output = np.tanh(output * 1.6) * .72
    assert np.max(np.abs(output)) < .73
    return output


def write_wav(path, samples):
    buffer = io.BytesIO()
    with wave.open(buffer, 'wb') as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes((samples*32767).astype('<i2').tobytes())
    path.write_bytes(buffer.getvalue())


def build_audio(specs, out):
    folder = Path(out) / 'audio'
    folder.mkdir(exist_ok=True)
    report = []
    for spec in specs:
        samples = synthesize(spec)
        path = folder / f"{spec['index']+1:02d}.wav"
        write_wav(path,samples)
        report.append({'file':path.name,'rate':RATE,'channels':2,
            'peak_dbfs':round(20*np.log10(np.max(np.abs(samples))),2),
            'rms_dbfs':round(20*np.log10(np.sqrt(np.mean(samples**2))),2),
            'release':spec['release'],'contact_beats':spec['beats'],
            'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
    (Path(out)/'audio-review.json').write_text(json.dumps({
        'provenance':'Original deterministic synthesis; no external samples.',
        'listening_status':'No physical headphone/speaker listening claimed.',
        'clips':report},indent=2))
    return report
