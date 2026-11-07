# oma-type · Feature: Soporte de Idioma Español (spanish_1k + tildes y ñ)
Soporte completo y nativo para práctica de mecanografía en idioma español con vocabulario curado (spanish_1k), soporte para caracteres acentuados (á, é, í, ó, ú) y la letra ñ, selector en la píldora superior y atajo de teclado dedicado.

## Specs

* S1: "Diccionario en Español (spanish_1k)" — Incorporar el dataset oficial Monkeytype de 1.000 palabras frecuentes en español con tildes y ñ en `core/Words.js`.
* S2: "Persistencia de Idioma" — Actualizar `core/Settings.js` con `VALID_LANGUAGES = ["english", "spanish"]` y default `language: "english"`.
* S3: "Generación de Palabras Multilingüe" — Extender `Words.getRandomWords(count, avoidList, options)` para soportar `options.language: "english" | "spanish"`.
* S4: "Soporte de Tildes y Teclas Muertas" — Garantizar que el motor (`core/Engine.js`) y `TypingOverlay.qml` manejen caracteres acentuados y ñ de forma natural sin desfasar el cursor suave.
* S5: "Control en la UI y Atajo de Teclado" — Añadir chip de idioma interactivo (`ES` / `EN`) en la píldora superior y atajo `Ctrl + I` con floating HUD toast (`Idioma: Español` / `Language: English`).
* S6: "Tests Unitarios" — Cobertura TDD para `core/Words.js`, `core/Settings.js` y `core/Engine.js` con palabras en español y caracteres acentuados.
* S7: "Documentación" — Actualizar `README.md` con la feature de idioma español y el atajo `Ctrl + I`.

## Tasks

* T1: Actualizar `VALID_LANGUAGES` en `core/Settings.js` y pruebas en `tests/settings.test.js` [S2, S6] (route: inline, commit: 3b07d77)
* T2: Integrar dataset `WORDS_ES` y soporte de `language` en `core/Words.js` y `tests/words.test.js` [S1, S3, S6] (route: inline, commit: 3b07d77)
* T3: Verificar compatibilidad del motor para tildes y ñ con tests en `tests/engine.test.js` [S4, S6] (route: inline, commit: 3b07d77)
* T4: Integrar selector de idioma (`ES`/`EN`), atajo `Ctrl+I` y HUD toast en `TypingOverlay.qml` [S4, S5] (route: inline, commit: 3b07d77)
* T5: Actualizar tablas y configuraciones en `README.md` [S7] (route: inline, commit: 3b07d77)

## Log

* L1: "### 1. 🇪🇸 Soporte de Idioma Español (spanish_1k + tildes y ñ)"
