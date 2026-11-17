# Feature: Typing Robustness (post-delivery debt from background audit)

## Objective
Fix the high/medium irregularities found in the 2026-11-16 audit that affect
day-to-day typing, without touching the shipped dithered-background feature.

## Problem
1. Dead keys (´ ` ¨ ^ ~) are not filtered in the key handler: on Spanish
   keyboards the dead keystroke is typed as a literal incorrect character
   before the composed accented character arrives.
2. `soundBaseDir` hardcodes an absolute home path; breaks if the repo moves
   or is used via the omarchy plugins symlink.
3. `core/quotes.json` and `core/words_es.json` are unreferenced duplicates of
   data embedded in `core/Quotes.js` / `core/Words.js` (drift risk).

## Tasks
* T1: Filter dead keys in input handling — extract `isDeadKey()` to
  `core/Keys.js` with node tests (test-first), wire guard into
  TypingOverlay.qml key handler. Qt 6 dead-key range verified from official
  docs: 0x01001250-0x01001293.
* T2: Resolve `soundBaseDir` relative to the QML file (plugin symlink safe),
  with `OMA_TYPE_SOUNDS_DIR` env override. Output must be a raw filesystem
  path (consumer is `pw-play`, not an Audio element).
* T3: Remove duplicate `core/quotes.json` + `core/words_es.json`; fix stale
  tree in ENGRAM.md.

## Route / evidence
* All tasks: direct inline (mechanical, understood, few files each).
* Delivery: single PR to main (small slices, no budget risk).

## Acceptance criteria
* node --test: all pass (new keys.test.js included).
* Typing ´ + a produces one á input (manual runtime check by user).
* No hardcoded home paths remain for assets.
* Duplicate JSONs gone, docs tree updated.

## Progress
* [x] T1 dead-key filter (RED observed: 1 failing module test, GREEN 26/26) — commit 69fb7e2
* [x] T2 sound dir relative resolution (symlink path check: 5 packs listed) — commit 44afade
* [x] T3 duplicate data files removed (grep zero refs pre-delete; 26/26) — commit 3546ffb
* [ ] PR opened (pending)
