# oma-type · Engram Memory & Architecture Record

> Persistent engineering record, architectural decisions, and post-mortems for **oma-type**.
> Exported from the active agent memory (Engram) on 2026-10-25.

---

## 1. Project Overview & Identity

* **Name:** `oma-type` (`juancasanueva.oma-type`)
* **Purpose:** Minimalist, ultra-fast typing speed test and quote practice for Omarchy Linux.
* **Inspiration:** Raycast *Typing Practice* + Monkeytype.
* **Runtime:** `omarchy-shell` (Quickshell, Qt Quick / C++ SceneGraph, Wayland `wlr-layer-shell`).
* **Design Pillars:**
  1. **Sub-millisecond latency:** Zero virtual DOM, zero electron, GPU-accelerated text rendering.
  2. **Swiss Minimalism:** Pure typography, high whitespace, no gratuitous borders, zero emojis, dark theme integration.
  3. **Rock-solid stability:** Decoupled external audio, non-blocking asynchronous calls, immune to compositor deadlocks.

---

## 2. Component Inventory

```
~/Projects/oma-type/
├── manifest.json            # Omarchy shell plugin descriptor (kind: overlay, keepLoaded: true)
├── TypingOverlay.qml        # Main Quickshell overlay window (1080×640, centered layout)
├── oma-type.desktop         # Freedesktop .desktop entry (indexed by oma-cast & system menus)
├── bin/
│   └── oma-type             # Shell CLI (install, reload, doctor, toggle, show, hide)
├── core/
│   ├── Words.js             # 1,000 common English words (Monkeytype english_1k) + Fisher-Yates
│   ├── Quotes.js            # 500 curated quotes (250 short, 250 medium) with authors
│   ├── quotes.json          # Raw quotes database (105 KB)
│   ├── Engine.js            # Deterministic state machine (time mode, quote mode, WPM math)
│   └── History.js           # Analytics aggregator (best/avg WPM, accuracy, trend coordinates)
├── tests/
│   ├── engine.test.js       # Node.js native unit tests for Engine and Words (9 tests)
│   └── history.test.js      # Unit tests for analytics and trend generation (4 tests)
└── assets/
    └── sounds/
        ├── thock/           # 4 mechanical linear switch audio samples (Gateron Oil King / Creams)
        ├── clicky/          # 3 mechanical clicky audio samples (Cherry MX Blue)
        └── typewriter/      # 3 vintage mechanical typewriter samples
```

---

## 3. Engram Observations & Engineering Decisions

### Observation 38: Initial Architecture Decision
* **What:** Build as a native `omarchy-shell` Quickshell plugin rather than a standalone binary or webview.
* **Why:** Omarchy Shell is always resident in memory (~90 MB RAM). A native QML overlay renders directly via Qt SceneGraph on GPU and maps in ~30 ms with zero process startup overhead.
* **Theme Binding:** Binds live to `qs.Commons.Color.menu.*` and `Style.font.family` (JetBrainsMono Nerd Font), automatically matching wallpaper and theme changes.

### Observation 40: QML Property Scope & ReferenceErrors
* **What:** Caret bars were appearing after every word due to `ReferenceError: isCaretAtEnd is not defined`.
* **Learned:** In QML, when a property binding throws a `ReferenceError` during evaluation, the binding engine drops the expression and reverts the property to its C++ default value (`true` for `Rectangle.visible`). Always assign explicit `id`s to delegate items to avoid scope shadowing.

### Observation 41: Quote Mode Implementation
* **What:** Implemented Quote Mode with 500 clean quotes from Monkeytype's official repository (250 short: 35-95 chars, 250 medium: 96-180 chars).
* **Architecture:** In Quote mode, timing runs as an ascending stopwatch (`0.0s → elapsed`). The test completes automatically on typing the very last character of the last word (no trailing space required). Author attribution is rendered below the text and in the final results card.

### Observation 42 & 43: Analytics, Trends & Swiss Minimalism
* **What:** Built a persistent metrics system (`~/.local/share/oma-type/history.json`) and progress curve.
* **Anti-Slop Pivot:** Stripped out emojis (`🏆`, `📊`, `⌨`), heavy rounded card borders, and candy buttons. Replaced them with pure typography hierarchy: large numbers (34px) with tiny lowercase labels (10-12px) below.
* **WPM Curve:** Drawn on a borderless QML `Canvas` using smooth Bézier curves, subtle gradient fill, a dashed average guideline (`avg: XX wpm`), and animated draw-in on entrance (360ms `OutCubic`).

### Observation 45: Multi-line Cursor Tracking
* **What:** Caret was freezing on line 1 while user typed on line 2.
* **Root Cause:** `smoothCaret` was placed as a direct visual child of a QML `Flow`. A `Flow` manages layout coordinates of all its visual children, fighting with manual `targetX`/`targetY` updates.
* **Solution:** Wrapped `Flow` inside an ordinary `Item` (`flowWrapper`), with `smoothCaret` as a sibling. `Flow` handles only word rows; `smoothCaret` moves in free absolute coordinates.

### Observation 47: Space Key Word Skipping Bug
* **What:** Pressing Space in the middle of a word skipped the rest of the word and advanced to the next word.
* **Fix:** Enforced strict word completion: `if (session.charIndex < currentWord.chars.length) return session;`. Space only advances when the current word is 100% typed.

### Observation 48: Raycast Layout & Hero WPM
* **What:** Redesigned UI to match Raycast's centered, spacious typing experience.
* **Geometry:** Card scaled to 880×540, text centered vertically and horizontally. Added Raycast top-center segmented control pill (`[ Quote short ▾ | Time 15s ▾ | Stats ]`). Replaced standard results with giant 92px hero WPM number.

### Observations 49 & 50: Critical Post-Mortem — System Freeze & Wayland Lockup
* **Incident:** App froze during fast typing, locking the entire OS keyboard/mouse input (only workspace switching worked), forcing a hard reboot.
* **Root Cause 1 (QtMultimedia Deadlock):** Rapid repeated calls to `SoundEffect.play()` on Linux using the FFmpeg backend with PipeWire caused internal thread mutex deadlocks inside `QFFmpegAudioDecoder`, freezing the Qt main GUI thread.
* **Root Cause 2 (Wayland Exclusive Trap):** `WlrKeyboardFocus.Exclusive` instructs the compositor (Hyprland) to route 100% of input to that surface. When the client's GUI thread deadlocked, no other application could receive input.
* **Root Cause 3 (Infinite Layout Loop):** `centeredTypingBox` had dynamic height bound to `flowWrapper.height`, which depended on `Flickable.contentY`, which was mutated by `updateCaretPosition`, triggering recursive 100% CPU layout recalculations.
* **Resolutions:**
  1. Set `centeredTypingBox` height to a rock-solid, static `240px` (later `310px` at 1.25x).
  2. Changed `WlrKeyboardFocus` from `Exclusive` to `OnDemand` (`root.opened ? OnDemand : None`).
  3. Removed `QtMultimedia` entirely from the UI process.

### Observation 51: Decoupled Safe Audio via `pw-play`
* **What:** Restored mechanical keyboard sound effects (`thock`, `clicky`, `typewriter`) safely without any risk of freezing.
* **Mechanism:** Audio is played by spawning native PipeWire processes asynchronously via `Quickshell.execDetached(["pw-play", "--volume", "0.55", file])` with a 35ms rate limiter.
* **Benefit:** Audio runs in isolated OS processes managed by the Linux kernel. The Quickshell UI thread never touches audio decoders or audio mutexes. Stress-tested with 100 rapid concurrent triggers in 0.6s with zero stalls.

### Observation 52: Dictionary Expansion (1K Words) & 1.25x Scale
* **What:** Expanded wordlist from 200 to 1,000 words (Monkeytype `english_1k.json`) to maximize randomness and vocabulary diversity. Scaled UI to 1.25x:
  * Window: 1080×640 px.
  * Typing font: 30 px.
  * Smooth caret: 35 px height, 3.2 px width.
  * Hero WPM: 115 px font size.
  * Stats metrics: 34 px font size, 180 px canvas height.

---

## 4. Key Formulas & Math

### Net Words Per Minute (WPM)
Standard typographical definition: 1 word = 5 characters (including spaces).
$$\text{WPM} = \max\left(0, \operatorname{round}\left(\frac{\text{correctChars}}{5} \times \frac{60}{\text{elapsedSeconds}}\right)\right)$$

### Raw WPM
Brute keystrokes without error deduction:
$$\text{Raw WPM} = \max\left(0, \operatorname{round}\left(\frac{\text{correctChars} + \text{incorrectChars} + \text{extraChars}}{5} \times \frac{60}{\text{elapsedSeconds}}\right)\right)$$

### Accuracy Percentage
$$\text{Accuracy} = \operatorname{round}\left(\frac{\text{correctChars}}{\max(1, \text{totalKeypresses})} \times 100\right)$$

---

## 5. Verification & Testing

* **Unit Tests:** `node --test tests/` (13/13 passing tests):
  * `Words.js`: 1,000 words loaded, shuffle without adjacent duplicates.
  * `Engine.js`: Idle → running → finished transitions, space blocking mid-word, backspace unwinding, quote completion on final character, WPM and accuracy formulas.
  * `History.js`: Storage limiting, metrics summary calculations, chronological trend generation.
* **Runtime Verification:** `oma-type doctor` (6/6 checks passing):
  * `omarchy-shell is installed`: OK
  * `omarchy-shell is running`: OK
  * `plugin is linked`: OK
  * `plugin is enabled`: OK
  * `plugin answers IPC`: OK
  * `desktop launcher is installed`: OK
