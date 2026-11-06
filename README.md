# oma-type

[![CI](https://github.com/Juanstudy/oma-type/actions/workflows/ci.yml/badge.svg)](https://github.com/Juanstudy/oma-type/actions/workflows/ci.yml)

**A minimalist, ultra-fast Monkeytype & Raycast-inspired typing practice plugin for [Omarchy](https://omarchy.org).**

Runs natively inside `omarchy-shell` (Quickshell / Qt Quick) with sub-millisecond input latency, GPU text rendering, PipeWire mechanical switch sounds, and live theme synchronization.

---

## Features

* **⚡ Ultra-low Latency:** Rendered natively via Wayland `wlr-layer-shell` and Qt Quick SceneGraph. No Electron, no browser overhead.
* **⌨ Mechanical Switch Sounds:** Realistic audio feedback (`thock`, `cream`, `topre`, `clicky`, `typewriter`) powered by native PipeWire (`pw-play`) out-of-process for zero lag and zero GUI lockups.
* **📖 500 Curated Quotes & 1,000 Words:** Sourced from official Monkeytype collections (`english_1k` and quotes) with author attributions.
* **🎯 Multiple Practice Modes:** `Time` (15s, 30s, 60s), `Words` (10, 25, 50, 100), and `Quote` (short, medium) with optional punctuation and numbers toggles.
* **📊 Swiss-Minimalist Stats & Graph:** Real-time analytics, Best WPM, Average WPM, and a smooth hardware-rendered Bézier progress curve.
* **🎨 Native Omarchy Theme:** Automatically inherits your active Omarchy theme colors (`qs.Commons.Color`) and monospace font.
* **🖥 1.25x Scaled Centered Layout:** Clean, spacious 1080×640 window with centered 30px typography and a giant 115px hero WPM result screen.

---

## Installation

```bash
cd ~/Projects/oma-type
bin/oma-type install
bin/oma-type doctor
```

## Usage

* **Via oma-cast / Application Menu:** Open your launcher (`Super + Space`), type `type` or `typing`, and press `Enter`.
* **Via CLI:**
  ```bash
  oma-type toggle    # Open or close the overlay
  oma-type show      # Open
  oma-type hide      # Close
  oma-type reload    # Hot-reload plugin after edits
  oma-type doctor    # Health check
  ```
* **Via Hyprland Keybinding:**
  Add to `~/.config/hypr/bindings.lua`:
  ```lua
  o.bind("SUPER + SHIFT + T", "Typing Practice", "oma-type toggle")
  ```

---

## Keyboard Controls

| Key | Shortcut | Action |
|---|---|---|
| `F1` | `Ctrl + M` | Cycle mode (`Time` → `Words` → `Quote`) |
| `F2` | `Ctrl + L` / `Ctrl + D` | Cycle option: Timer (`15s`/`30s`/`60s`), Words (`10`/`25`/`50`/`100`), or Quote (`short`/`medium`) |
| `F3` | `Ctrl + S` | Cycle mechanical sound (`thock` → `cream` → `topre` → `clicky` → `typewriter` → `off`) |
| `F4` | `Ctrl + H` / `Ctrl + E` | Toggle stats & analytics graph |
| `Ctrl + Up` | — | Increase volume (+5%) with floating HUD toast |
| `Ctrl + Down` | — | Decrease volume (-5%) with floating HUD toast |
| `Ctrl + P` | — | Toggle punctuation marks and capitals (`punc`) |
| `Ctrl + N` | — | Toggle numbers injection (`123`) |
| `Tab` | — | Restart test with fresh text |
| `Esc` | — | Close overlay (or return from stats to test) |
| `Enter` | — | Restart after finishing a test / return from stats |
| `Space` | — | Advance to next word (skips incomplete word as incorrect, Monkeytype-style) |
| `Backspace` | — | Erase previous character |

---

## Configuration

Settings are automatically saved on every change to `~/.config/oma-type/settings.json`:

```json
{
  "soundTheme": "thock",
  "mode": "time",
  "quoteLength": "short",
  "duration": 15,
  "wordCount": 25,
  "punctuation": false,
  "numbers": false,
  "soundVolume": 0.55
}
```

* `soundTheme`: `"thock"` | `"cream"` | `"topre"` | `"clicky"` | `"typewriter"` | `"off"`
* `mode`: `"time"` | `"words"` | `"quote"`
* `duration`: `15` | `30` | `60`
* `wordCount`: `10` | `25` | `50` | `100`
* `quoteLength`: `"short"` | `"medium"`
* `punctuation`: `true` | `false`
* `numbers`: `true` | `false`
* `soundVolume`: `0.0` to `1.0` (PipeWire switch playback volume)



---

## Architecture & Memory Record

See [`ENGRAM.md`](ENGRAM.md) for the full architectural record, post-mortems (Wayland focus, PipeWire audio, layout binding loops), and test suite documentation.
