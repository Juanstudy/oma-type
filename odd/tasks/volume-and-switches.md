# oma-type · Feature: Control de Volumen y Nuevos Switches Mecánicos
Control de volumen interactivo con atajos de teclado y feedback acústico/HUD en tiempo real, junto con la incorporación de nuevos packs de sonido mecánicos (NovelKeys Cream y Topre electro-capacitive).

## Specs

* S1: "Nuevos Switches Mecánicos" — Añadir packs de sonido de alta fidelidad para `cream` (POM linear clack) y `topre` (electro-capacitive deep dome thud) en `assets/sounds/cream/` y `assets/sounds/topre/`.
* S2: "Validación de Settings" — Actualizar `core/Settings.js` con `VALID_SOUND_THEMES` expandido (`"thock"`, `"cream"`, `"topre"`, `"clicky"`, `"typewriter"`, `"off"`).
* S3: "Control de Volumen por Teclado" — Atajos `Ctrl + Up` (subir volumen +0.05 hasta 1.0) y `Ctrl + Down` (bajar volumen -0.05 hasta 0.0), con persistencia en `~/.config/oma-type/settings.json` y disparo de muestra acústica inmediata.
* S4: "Feedback Visual del Volumen (HUD Toast)" — Mostrar un indicador visual sutil (toast/badge flotante `󰕾 XX%`) al modificar el volumen que se desvanece suavemente tras 1.2 segundos.
* S5: "Ciclo de Switches Actualizado" — `F3` y `Ctrl + S` deben ciclar todos los perfiles de audio en orden: `thock` → `cream` → `topre` → `clicky` → `typewriter` → `off`.
* S6: "Tests Unitarios" — Actualizar `tests/settings.test.js` verificando los nuevos temas de sonido y límites de volumen.
* S7: "Documentación" — Actualizar `README.md` con los nuevos temas y los atajos de volumen.

## Tasks

* T1: Actualizar `VALID_SOUND_THEMES` y pruebas en `core/Settings.js` y `tests/settings.test.js` [S2, S6] (route: inline, commit: bc1af74)
* T2: Generar e instalar muestras acústicas de alta fidelidad para `cream` y `topre` [S1] (route: inline, commit: bc1af74)
* T3: Implementar control de volumen (`Ctrl+Up`/`Down`) y ciclo de switches en `TypingOverlay.qml` [S3, S5] (route: inline, commit: bc1af74)
* T4: Implementar toast visual minimalista de volumen en `TypingOverlay.qml` [S4] (route: inline, commit: bc1af74)
* T5: Actualizar tabla de atajos y configuraciones en `README.md` [S7] (route: inline, commit: bc1af74)

## Log

* L1: "### 3. 🔊 Control de Volumen y Nuevos Switches :=))))))"
