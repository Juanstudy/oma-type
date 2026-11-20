# Feature: Settings Panel (unified configuration view)

## Objective
A single in-overlay settings panel that absorbs every knob currently spread
across F1-F4 menus and settings.json, styled with the same dithered aesthetic.

## Problem
There are now ~15 tunable settings (typing mode, quote length, duration, word
count, language, punctuation, numbers, sound theme, volume, and 9 background
keys). They are only reachable through scattered keybind menus (F1-F4, Ctrl+B/D/V)
or by hand-editing settings.json. Discoverability is zero and the menus add
keybind pressure.

## Chosen direction
In-overlay slide-in panel (Monkeytype-style), NOT a separate Quickshell window:
- The overlay is already the Wayland layer; a second window means another
  layer, another focus cycle, and more Wayland surface bugs.
- The panel reuses the dithered background for visual consistency.
- One toggle (proposed: Ctrl+, or dedicated key) shows/hides.

## Proposed scope
* P1: Panel shell — slide-in view inside TypingOverlay, Esc to close, blocks
  typing input while open.
* P2: Typing section — mode, quote length, duration, word count, language,
  punctuation/numbers toggles (reuses existing setters + saveSettings).
* P3: Sound section — theme picker (6 themes), volume slider (existing HUD toast).
* P4: Background section — enable, image path (file picker via CLI bg), blur,
  dither, intensity, levels, cell size, dim, adaptive dim, vignette. Each
  control writes through the existing settings pipeline.
* P5: Retire F1-F4 menus in favor of panel sections; keep Tab/Esc.

## Open questions
* Form factor: user decision pending (in-overlay panel vs separate window).

## Acceptance criteria
* Every settings.json key is adjustable from the panel.
* Changes persist (saveSettings) and apply live without restart.
* Typing input is impossible while the panel is open.
* node --test stays green; panel is QML-only (no node-testable logic expected).

## Progress
* [x] P1 panel shell — `components/SettingsPanel.qml` slide-in view inside the
  card body (`TypingOverlay.qml` VIEW 3), `open` property + NumberAnimation
  slide/fade, Esc closes, `activeView === "settings"` guard blocks typing input.
* [x] P2 typing section — SegGroup rows for mode/quote length/duration/word
  count/language + punctuation/numbers ToggleRows; writes go through
  `setMode`/`setQuoteLength`/etc. and `saveSettings` (punctuation/numbers reset
  + save via the `settingsChanged` handler).
* [x] P3 sound section — 6-theme SegGroup + percent volume SliderRow; writes
  `soundTheme`/`soundVolume` and commits via `saveSettings`.
* [x] P4 background section — image toggle + path TextInput + blur/dither/
  intensity/levels(2-16)/cell(1-6)/dim/adaptive-dim/vignette rows; every change
  updates the bound root property and commits through `saveSettings`.
* [ ] P5 retire F1-F4 menus
