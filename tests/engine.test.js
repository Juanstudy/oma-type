const test = require("node:test");
const assert = require("node:assert/strict");
const { WORDS, getRandomWords } = require("../core/Words.js");
const { createSession, handleKey, tick, calculateStats } = require("../core/Engine.js");

test("Words: dataset has 1000 words and getRandomWords works without consecutive duplicates", () => {
  assert.equal(WORDS.length, 1000);
  const words = getRandomWords(50);
  assert.equal(words.length, 50);

  for (let i = 1; i < words.length; i++) {
    assert.notEqual(words[i], words[i - 1], `Consecutive duplicate at ${i}: ${words[i]}`);
  }
});

test("Engine: initial state is idle and starts on first printable key", () => {
  const session = createSession({ duration: 15, words: ["the", "quick", "brown"] });
  assert.equal(session.status, "idle");
  assert.equal(session.wordIndex, 0);
  assert.equal(session.charIndex, 0);

  const t0 = 100000;
  handleKey(session, "t", t0);
  assert.equal(session.status, "running");
  assert.equal(session.startTime, t0);
  assert.equal(session.charIndex, 1);
  assert.equal(session.correctChars, 1);
  assert.equal(session.words[0].chars[0].state, "correct");
});

test("Engine: typing incorrect character records incorrect state", () => {
  const session = createSession({ duration: 15, words: ["cat"] });
  handleKey(session, "x", 100000);
  assert.equal(session.words[0].chars[0].state, "incorrect");
  assert.equal(session.incorrectChars, 1);
  assert.equal(session.correctChars, 0);
});

test("Engine: space advances to next word and awards correct space if word was perfect", () => {
  const session = createSession({ duration: 15, words: ["hi", "there"] });
  const t0 = 100000;
  handleKey(session, "h", t0);
  handleKey(session, "i", t0 + 100);
  handleKey(session, " ", t0 + 200);

  assert.equal(session.wordIndex, 1);
  assert.equal(session.charIndex, 0);
  // 'h' (1) + 'i' (1) + ' ' (1) = 3 correct chars
  assert.equal(session.correctChars, 3);
});

test("Engine: space in the middle of a word skips to next word and marks remaining characters as incorrect", () => {
  const session = createSession({ duration: 15, words: ["because", "we"] });
  const t0 = 100000;
  handleKey(session, "b", t0);
  handleKey(session, "e", t0 + 100);

  // Pressing space at character 2 of a 7-letter word
  handleKey(session, " ", t0 + 200);

  // Must advance to next word
  assert.equal(session.wordIndex, 1);
  assert.equal(session.charIndex, 0);

  // First 2 chars were correct ('b', 'e')
  assert.equal(session.words[0].chars[0].state, "correct");
  assert.equal(session.words[0].chars[1].state, "correct");

  // Remaining 5 un-typed chars ('c', 'a', 'u', 's', 'e') marked as incorrect
  for (let i = 2; i < 7; i++) {
    assert.equal(session.words[0].chars[i].state, "incorrect");
  }
  assert.equal(session.incorrectChars, 5);
  assert.equal(session.correctChars, 2);

  // Space on untouched word (charIndex === 0) does not skip the word
  handleKey(session, " ", t0 + 300);
  assert.equal(session.wordIndex, 1);
  assert.equal(session.charIndex, 0);
});

test("Engine: backspace steps back within current word", () => {
  const session = createSession({ duration: 15, words: ["code"] });
  handleKey(session, "c", 100000);
  handleKey(session, "x", 100100); // incorrect 'x' instead of 'o'
  assert.equal(session.charIndex, 2);
  assert.equal(session.incorrectChars, 1);

  handleKey(session, "Backspace", 100200);
  assert.equal(session.charIndex, 1);
  assert.equal(session.incorrectChars, 0);
  assert.equal(session.words[0].chars[1].state, "pending");
});

test("Engine: time expiration transitions session to finished", () => {
  const session = createSession({ duration: 15, words: ["test"] });
  const t0 = 100000;
  handleKey(session, "t", t0);
  assert.equal(session.status, "running");

  // Tick before expiry
  tick(session, t0 + 14000);
  assert.equal(session.status, "running");

  // Tick at or after expiry
  tick(session, t0 + 15000);
  assert.equal(session.status, "finished");
  assert.equal(session.endTime, t0 + 15000);
});

test("Engine: calculateStats computes accurate WPM and accuracy", () => {
  const session = createSession({ duration: 15, words: ["the", "cat"] });
  const t0 = 100000;
  handleKey(session, "t", t0);
  handleKey(session, "h", t0 + 100);
  handleKey(session, "e", t0 + 200);
  handleKey(session, " ", t0 + 300);
  handleKey(session, "c", t0 + 400);
  handleKey(session, "a", t0 + 500);
  handleKey(session, "t", t0 + 600);
  // 3 + 1 + 3 = 7 correct chars in 6 seconds (0.1 min)
  // WPM = (7 / 5) / (6 / 60) = 1.4 / 0.1 = 14 WPM

  const stats = calculateStats(session, t0 + 6000);
  assert.equal(stats.wpm, 14);
  assert.equal(stats.accuracy, 100);
  assert.equal(stats.timeLeft, 9);
});

test("Engine Quote Mode: finishes immediately on last char of last word and supports punctuation", () => {
  const quote = { id: 1, text: "Be kind.", source: "Unknown" };
  const session = createSession({
    mode: "quote",
    words: ["Be", "kind."],
    quote: quote
  });

  assert.equal(session.mode, "quote");
  assert.equal(session.status, "idle");

  const t0 = 100000;
  // Type 'B', 'e', ' '
  handleKey(session, "B", t0);
  assert.equal(session.status, "running");
  handleKey(session, "e", t0 + 100);
  handleKey(session, " ", t0 + 200);

  assert.equal(session.wordIndex, 1);
  assert.equal(session.charIndex, 0);

  // Type 'k', 'i', 'n', 'd', '.'
  handleKey(session, "k", t0 + 300);
  handleKey(session, "i", t0 + 400);
  handleKey(session, "n", t0 + 500);
  handleKey(session, "d", t0 + 600);
  assert.equal(session.status, "running");

  // Last character of quote
  handleKey(session, ".", t0 + 700);
  assert.equal(session.status, "finished");
  assert.equal(session.endTime, t0 + 700);

  const stats = calculateStats(session, t0 + 700);
  assert.equal(stats.isFinished, true);
  assert.equal(stats.accuracy, 100);
  assert.equal(stats.timeLeft, null);
  assert.equal(stats.quote.source, "Unknown");
});

test("Engine Words Mode: finishes immediately on last char of last word without needing space", () => {
  const session = createSession({
    mode: "words",
    words: ["quick", "fox"]
  });

  assert.equal(session.mode, "words");
  assert.equal(session.status, "idle");

  const t0 = 100000;
  // Type 'quick'
  "quick".split("").forEach((ch, idx) => handleKey(session, ch, t0 + idx * 50));
  assert.equal(session.status, "running");
  assert.equal(session.wordIndex, 0);

  // Advance with space
  handleKey(session, " ", t0 + 300);
  assert.equal(session.wordIndex, 1);
  assert.equal(session.charIndex, 0);

  // Type 'fo'
  handleKey(session, "f", t0 + 400);
  handleKey(session, "o", t0 + 450);
  assert.equal(session.status, "running");

  // Type final char 'x' -> should finish immediately!
  handleKey(session, "x", t0 + 500);
  assert.equal(session.status, "finished");
  assert.equal(session.endTime, t0 + 500);

  const stats = calculateStats(session, t0 + 500);
  assert.equal(stats.isFinished, true);
  assert.equal(stats.timeLeft, null);
  assert.equal(stats.wordCount, 2);
});

test("Engine Spanish: correctly handles accented vowels and enye (á, é, í, ó, ú, ñ)", () => {
  const session = createSession({
    mode: "words",
    words: ["año", "más"]
  });

  const t0 = 100000;
  // Type 'a'
  handleKey(session, "a", t0);
  assert.equal(session.words[0].chars[0].state, "correct");

  // Type 'ñ'
  handleKey(session, "ñ", t0 + 100);
  assert.equal(session.words[0].chars[1].state, "correct");

  // Type 'o'
  handleKey(session, "o", t0 + 200);
  assert.equal(session.words[0].chars[2].state, "correct");

  // Advance with space
  handleKey(session, " ", t0 + 300);
  assert.equal(session.wordIndex, 1);
  assert.equal(session.charIndex, 0);

  // Type 'm'
  handleKey(session, "m", t0 + 400);
  // Type 'á'
  handleKey(session, "á", t0 + 500);
  assert.equal(session.words[1].chars[1].state, "correct");

  // Backspace on 'á'
  handleKey(session, "Backspace", t0 + 550);
  assert.equal(session.charIndex, 1);
  assert.equal(session.words[1].chars[1].state, "pending");

  // Retype 'á' and 's'
  handleKey(session, "á", t0 + 600);
  handleKey(session, "s", t0 + 700);

  // Test should finish on last char of 'más'
  assert.equal(session.status, "finished");
  assert.equal(session.correctChars, 3 + 1 + 3); // "año" (3) + space (1) + "más" (3) = 7

  const stats = calculateStats(session, t0 + 700);
  assert.equal(stats.accuracy, 78);
  assert.ok(stats.wpm > 0);
});

