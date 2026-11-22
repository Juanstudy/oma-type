# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Synthetic stress benchmark suite (`bin/oma-type bench [samples]` and `npm run bench` via `core/Bench.js` and `scripts/bench.js`) measuring keystroke dispatch latency, percentiles (p50, p95, p99), and throughput with full side-effect isolation (history clean, audio muted).

### Fixed
- Fixed straight 90-degree corners in idle state by adding SDF corner radius clipping to dithered scrims.

## [0.2.0] - 2026-11-21

### Added
- High-contrast in-body Settings Panel with category navigation (`typing`, `sound`, `appearance`).
- 100% opaque tactile surface plate (`surfacePlate`) eliminating high-frequency Bayer dithering noise bleed over typography.
- Structured tactile `SettingCard` groupings with accent category indicators and clean row dividers.
- Proportional 620px centered container layout fixing wide gaps between labels and controls.
- Native file picker helper (`bin/pick-image`) supporting Zenity, Kdialog, and Yad with layer-shell focus handling.
- Focus mode (`F11` / `Ctrl+Shift+F`) with smooth scaling animation and clean zen presentation.
- Interactive window dragging and edge resize handles.
- Header deduplication: test mode selector pill automatically hides in settings and stats views.
- CLI `--version` flag in `bin/oma-type`.

### Changed
- Aligned versioning strategy to SemVer pre-1.0 (`0.2.0`).

## [0.1.0] - 2026-11-20

### Added
- Initial Monkeytype & Raycast-inspired typing practice overlay for Wayland (Quickshell).
- Core typing engine with Quote, Time, and Words modes.
- Spanish language dictionary and quotes with authentic accent handling (á, é, í, ó, ú, ñ).
- Mechanical keyboard switch sound synthesis (Cream, Topre, Typewriter, Thock).
- 8x8 Bayer dithering wallpaper shader pipeline with adaptive contrast scrim.
- Adaptive wallpaper accent color extraction and Aether palette harmonization.
- Local dead-key accent composition for seamless international typing on layer-shell.
- CLI tool (`bin/oma-type`) with desktop launcher and Omarchy shell IPC integration.
