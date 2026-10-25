# oma-type

**A minimalist, ultra-fast Monkeytype & Raycast-inspired typing practice plugin for [Omarchy](https://omarchy.org).**

Runs natively inside `omarchy-shell` (Quickshell / Qt Quick) with sub-millisecond input latency, GPU text rendering, PipeWire mechanical switch sounds, and live theme synchronization.

---

## Features

* **⚡ Ultra-low Latency:** Rendered natively via Wayland `wlr-layer-shell` and Qt Quick SceneGraph. No Electron, no browser overhead.
* **⌨ Mechanical Switch Sounds:** Realistic audio feedback (`thock`, `clicky`, `typewriter`) powered by native PipeWire (`pw-play`) out-of-process for zero lag and zero GUI lockups.
* **📖 500 Curated Quotes:** Sourced from the official Monkeytype collection (short and medium) with author/source attributions.
* **🔤 1,000 Common English Words:** High-frequency vocabulary (`english_1k`) with Fisher-Yates shuffle and anti-adjacent repeat buffers.
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

| Key | Action |
|---|---|
| `Any Letter` | Starts the timer / types character |
| `Space` | Advances to next word (only when current word is typed) |
| `Backspace` | Erases previous character |
| `Tab` | Restarts the test with fresh text |
| `Esc` | Closes the overlay (or returns from stats to test) |
| `Enter` | Restarts after finishing a test / returns from stats |

---

## Architecture & Memory Record

See [`ENGRAM.md`](ENGRAM.md) for the full architectural record, post-mortems (Wayland focus, PipeWire audio, layout binding loops), and test suite documentation.
