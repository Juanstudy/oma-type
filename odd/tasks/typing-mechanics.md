# oma-type · Feature: Mecánicas de Tipeo (Paridad Monkeytype)
Implementación integral de mecánicas de práctica de tipeo: modo palabras, tiempos extendidos (60s), y opciones de puntuación y números con persistencia de configuración y control por teclado.

## Specs

* S1: "Modo Palabras (Word Count)" — Soporte para modo `words` con selección de 10, 25, 50 y 100 palabras. El test finaliza automáticamente al tipear el último carácter de la última palabra y se cronometra en orden ascendente (stopwatch).
* S2: "Tiempos extendidos" — Añadir duración de 60 segundos (15s, 30s, 60s) en modo `time`.
* S3: "Puntuación (Punctuation)" — Opción para capitalizar palabras e intercalar signos ortográficos (`.`, `,`, `?`, `!`, `-`) en el generador de palabras.
* S4: "Números (Numbers)" — Opción para intercalar números (dígitos y cifras) en el generador de palabras.
* S5: "Persistencia de Configuración" — Actualizar `core/Settings.js` con validación y serialización de `mode` (`"time"` | `"words"` | `"quote"`), `duration` (`15` | `30` | `60`), `wordCount` (`10` | `25` | `50` | `100`), `punctuation` (`boolean`), y `numbers` (`boolean`).
* S6: "Controles de UI y Atajos de Teclado" — Reflejar los modos en el segmented control superior de `TypingOverlay.qml` y añadir/actualizar atajos rápidos (F1 para ciclar Time/Words/Quote, F2 para ciclar el parámetro activo, y atajos para toggles).
* S7: "Suite de Tests Unitarios" — Cobertura TDD exhaustiva para las nuevas mecánicas en `tests/engine.test.js` y `tests/settings.test.js`.

## Tasks

* T1: Extender duraciones (60s) y soporte de modo words en `core/Settings.js` [S2, S5] (route: inline, commit: 30692de)
* T2: Implementar modo words y finalización inmediata en `core/Engine.js` [S1] (route: inline, commit: 30692de)
* T3: Implementar generador de palabras con opciones de puntuación y números en `core/Words.js` [S3, S4] (route: inline, commit: 30692de)
* T4: Añadir suite de tests unitarios TDD para Settings, Engine y Words [S7] (route: inline, commit: 30692de)
* T5: Integrar controles, selector y atajos en `TypingOverlay.qml` [S6] (route: inline, commit: 30692de)
* T6: Documentar nuevas mecánicas y atajos en `README.md` [S1-S6] (route: inline, commit: 30692de)

## Log

* L1: "demole esto con odd y suavecito para abajo 1. Mecánicas de Tipeo (Paridad Monkeytype)"
