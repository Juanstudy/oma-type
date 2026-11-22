# AGENTS.md — oma-type Architectural & Review Guidelines

Guidelines for AI agents and automated code reviewers (`gentleman-guardian-angel`, PR reviewers, and assistant agents) working on `oma-type`.

---

## 1. Project Overview & Identity
`oma-type` is a minimalist, ultra-low-latency typing speed test plugin for **Omarchy** (`omarchy-shell` / Quickshell / Qt Quick) running natively on Wayland (`wlr-layer-shell`).

Performance, responsiveness (sub-millisecond input latency), and clean separation of concerns are non-negotiable foundations of this repository.

---

## 2. Core Architectural Guardrails

### 2.1 Headless Core (`core/`)
* **Pure JavaScript only:** Modules inside `core/` (e.g. `Engine.js`, `History.js`, `Settings.js`, `Words.js`, `Quotes.js`, `Keys.js`, `Palette.js`) must be 100% headless CommonJS.
* **Zero UI / Qt / QML dependencies:** Never import or couple Qt, QML, DOM, or browser APIs inside `core/`.
* **State Machine & Logic:** All typing state transitions (`idle` → `running` → `finished`), metrics math (WPM, Raw WPM, Accuracy, Error Rate), word slicing, and dead-key composition logic belong in `core/`.
* **Testability:** Any module in `core/` must run and be fully verified via Node.js and Bun without a graphical environment.

### 2.2 Presentation Layer (`components/` & `TypingOverlay.qml`)
* **Container / Presentational separation:** QML files should strictly handle rendering, animations, tactile surfaces, and user input events, delegating business logic to `core/`.
* **Wayland Layer-Shell Constraints:** Respect `wlr-layer-shell` focus rules. Dead-key accent composition (e.g., `á`, `é`, `í`, `ó`, `ú`, `ñ`) must be handled locally in key-catcher logic to prevent layer-shell input freezes.
* **Audio Out-of-Process:** Mechanical switch sound playback must be spawned out-of-process via PipeWire (`pw-play`). Never block the Qt GUI thread with synchronous audio operations.

---

## 3. Dependency & Testing Policy

* **Zero External npm Dependencies:** `package.json` must remain dependency-free. Do not add external npm runtime libraries or heavyweight test runners.
* **Native Test Runner:** Tests in `tests/` use the native Node.js test runner (`node:test`) and assertions (`node:assert/strict`).
* **Test Coverage for Logic:** Any new calculation, state transition, or helper in `core/` must have a corresponding test in `tests/`.
* **Cross-Runtime Compatibility:** All tests must pass cleanly in both:
  * `npm test` (`node --test tests/*.test.js`)
  * `bun test`

---

## 4. Release & Versioning Protocol

All changes affecting versions and releases must strictly adhere to the following protocol:

### 4.1 Triple Version Synchronization
Whenever a release version is bumped (following [Semantic Versioning](https://semver.org/)), the exact same version string `X.Y.Z` **MUST** be updated in all three files simultaneously:
1. `package.json`: `"version": "X.Y.Z"`
2. `manifest.json`: `"version": "X.Y.Z"`
3. `bin/oma-type`: `VERSION="X.Y.Z"`

### 4.2 Changelog Format ([Keep a Changelog](https://keepachangelog.com/))
* Every user-facing change must be documented in `CHANGELOG.md`.
* Maintain the `## [Unreleased]` section at the top for in-flight work.
* Release headers must follow: `## [X.Y.Z] - YYYY-MM-DD`.
* Group items strictly under Keep a Changelog categories:
  * `### Added` (for new features)
  * `### Changed` (for changes in existing functionality)
  * `### Deprecated` (for soon-to-be removed features)
  * `### Removed` (for now removed features)
  * `### Fixed` (for any bug fixes)
  * `### Security` (in case of vulnerabilities)

### 4.3 Git Conventions
* **Conventional Commits:** All commit messages must follow [Conventional Commits](https://www.conventionalcommits.org/):
  * `feat:` new features
  * `fix:` bug fixes
  * `docs:` documentation updates
  * `style:` formatting, UI styling
  * `refactor:` code restructuring without behavior changes
  * `test:` adding or refactoring tests
  * `chore:` maintenance, build tasks
  * `chore(release): vX.Y.Z with changelog and SemVer alignment` for release bumps.
* **Git Tags:** Tag releases with a leading `v`, e.g., `v0.2.0`, matching the synchronized version.

---

## 5. Review Checklist for Automated Agents (`gga`)

When reviewing a PR or commit diff, flag and reject:
1. ❌ Any import of QML/Qt/DOM globals or methods inside `core/`.
2. ❌ Any newly added runtime dependency in `package.json`.
3. ❌ Core logic changes introduced without accompanying `tests/*.test.js` updates.
4. ❌ Version bumps that leave `package.json`, `manifest.json`, or `bin/oma-type` out of sync.
5. ❌ Version bumps missing an entry in `CHANGELOG.md`.
6. ❌ Synchronous operations or shell blocks that could hang the Wayland layer-shell event loop.
