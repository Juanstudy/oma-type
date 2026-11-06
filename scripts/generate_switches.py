#!/usr/bin/env python3
"""
Acoustic physical modeling synthesis for oma-type mechanical switches:
- Cream (NovelKeys Cream POM-on-POM crisp clack)
- Topre (Electro-capacitive deep dome raindrop thock)
Generates 16-bit 44.1kHz stereo WAVs matching the exact format of oma-type.
"""

import math
import random
import struct
import wave
import os

SAMPLE_RATE = 44100

def clamp(val, low=-32767, high=32767):
    return max(low, min(high, int(val)))

def generate_cream(variation_seed=0):
    random.seed(variation_seed + 100)
    duration = 0.12 # 120ms
    num_samples = int(SAMPLE_RATE * duration)

    # Base frequencies with slight key-to-key pitch variation
    f_fund = 540.0 + random.uniform(-25.0, 30.0)
    f_mid = 1100.0 + random.uniform(-40.0, 50.0)
    f_high = 2200.0 + random.uniform(-60.0, 80.0)

    samples = []
    prev_noise = 0.0

    for i in range(num_samples):
        t = i / SAMPLE_RATE

        # Micro-transient click impulse (first 4ms)
        click_env = math.exp(-t / 0.003) if t < 0.015 else 0.0
        noise = random.uniform(-1.0, 1.0)
        # Simple high-pass filter on noise
        hp_noise = noise - prev_noise
        prev_noise = noise
        click = hp_noise * click_env * 0.45

        # Resonant POM housing bottom-out
        body_env = math.exp(-t / 0.038)
        mode1 = math.sin(2.0 * math.pi * f_fund * t) * 0.55
        mode2 = math.sin(2.0 * math.pi * f_mid * t + 0.3) * 0.28
        mode3 = math.sin(2.0 * math.pi * f_high * t + 0.7) * 0.12 * math.exp(-t / 0.018)

        body = (mode1 + mode2 + mode3) * body_env

        # Secondary plate bounce tap at ~14ms
        bounce = 0.0
        if t > 0.014:
            tb = t - 0.014
            bounce = math.sin(2.0 * math.pi * (f_fund * 1.15) * tb) * math.exp(-tb / 0.022) * 0.22

        mixed = (click + body + bounce) * 26000.0
        left = clamp(mixed * (1.0 + random.uniform(-0.03, 0.03)))
        right = clamp(mixed * (1.0 + random.uniform(-0.03, 0.03)))
        samples.append((left, right))

    return samples

def generate_topre(variation_seed=0):
    random.seed(variation_seed + 200)
    duration = 0.16 # 160ms
    num_samples = int(SAMPLE_RATE * duration)

    # Deep low-frequency fundamental (rubber dome collapse)
    f_sub = 195.0 + random.uniform(-15.0, 18.0)
    f_body = 380.0 + random.uniform(-20.0, 25.0)
    f_spring = 1250.0 + random.uniform(-30.0, 30.0)

    samples = []
    noise_lpf = 0.0

    for i in range(num_samples):
        t = i / SAMPLE_RATE

        # Soft tactile dome collapse thud (low-pass filtered thump)
        raw_noise = random.uniform(-1.0, 1.0)
        noise_lpf += (raw_noise - noise_lpf) * 0.12 # Low-pass filter
        thump_env = math.exp(-t / 0.018)
        thump = noise_lpf * thump_env * 0.35

        # Deep hollow chamber resonance
        dome_env = math.exp(-t / 0.058)
        sub_wave = math.sin(2.0 * math.pi * f_sub * t) * 0.65
        # Soft subtle distortion for heavy rubber dome resistance
        sub_wave = math.tanh(sub_wave * 1.3)

        body_wave = math.sin(2.0 * math.pi * f_body * t + 0.4) * 0.30

        # Very subtle conical spring ring
        spring_wave = math.sin(2.0 * math.pi * f_spring * t) * 0.06 * math.exp(-t / 0.022)

        # Subtle acoustic rebound at 22ms
        rebound = 0.0
        if t > 0.022:
            tr = t - 0.022
            rebound = math.sin(2.0 * math.pi * (f_sub * 0.9) * tr) * math.exp(-tr / 0.035) * 0.25

        mixed = (thump + (sub_wave + body_wave + spring_wave) * dome_env + rebound) * 27000.0
        left = clamp(mixed * (1.0 + random.uniform(-0.02, 0.02)))
        right = clamp(mixed * (1.0 + random.uniform(-0.02, 0.02)))
        samples.append((left, right))

    return samples

def write_wav(filename, samples):
    with wave.open(filename, 'w') as wav:
        wav.setnchannels(2)
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        frames = bytearray()
        for l, r in samples:
            frames.extend(struct.pack('<hh', l, r))
        wav.writeframes(frames)

def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    cream_dir = os.path.join(base_dir, 'assets', 'sounds', 'cream')
    topre_dir = os.path.join(base_dir, 'assets', 'sounds', 'topre')

    os.makedirs(cream_dir, exist_ok=True)
    os.makedirs(topre_dir, exist_ok=True)

    print("Generating Cream switch samples...")
    for i in range(1, 5):
        samples = generate_cream(i)
        filepath = os.path.join(cream_dir, f"{i}.wav")
        write_wav(filepath, samples)
        print(f"  -> {filepath} ({len(samples)} frames)")

    print("Generating Topre switch samples...")
    for i in range(1, 5):
        samples = generate_topre(i)
        filepath = os.path.join(topre_dir, f"{i}.wav")
        write_wav(filepath, samples)
        print(f"  -> {filepath} ({len(samples)} frames)")

    print("Done generating switch acoustics!")

if __name__ == '__main__':
    main()
