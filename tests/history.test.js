const test = require("node:test");
const assert = require("node:assert/strict");
const { createEntry, addEntry, getSummary, getRecentTrend } = require("../core/History.js");

test("History: createEntry extracts values from stats", () => {
  const stats = { wpm: 85, rawWpm: 90, accuracy: 98, elapsedSeconds: 15, quote: { source: "Dijkstra" } };
  const entry = createEntry(stats, "quote");
  assert.equal(entry.wpm, 85);
  assert.equal(entry.rawWpm, 90);
  assert.equal(entry.accuracy, 98);
  assert.equal(entry.mode, "quote");
  assert.equal(entry.quoteSource, "Dijkstra");
});

test("History: addEntry unshifts and limits capacity", () => {
  let history = [];
  for (let i = 1; i <= 5; i++) {
    history = addEntry(history, { id: i, wpm: i * 10 }, 3);
  }
  assert.equal(history.length, 3);
  assert.equal(history[0].id, 5);
  assert.equal(history[1].id, 4);
  assert.equal(history[2].id, 3);
});

test("History: getSummary calculates best, avg, and totals", () => {
  const history = [
    { wpm: 60, accuracy: 100, elapsedSeconds: 15 },
    { wpm: 80, accuracy: 90, elapsedSeconds: 15 },
    { wpm: 100, accuracy: 95, elapsedSeconds: 30 }
  ];
  const summary = getSummary(history);
  assert.equal(summary.totalTests, 3);
  assert.equal(summary.bestWpm, 100);
  assert.equal(summary.avgWpm, 80); // (60 + 80 + 100) / 3
  assert.equal(summary.avgAccuracy, 95); // (100 + 90 + 95) / 3
  assert.equal(summary.totalSeconds, 60);
});

test("History: getRecentTrend returns chronological order for plotting", () => {
  const history = [
    { id: 3, wpm: 90 },
    { id: 2, wpm: 80 },
    { id: 1, wpm: 70 }
  ]; // newest first: [3, 2, 1]
  const trend = getRecentTrend(history, 2);
  assert.equal(trend.length, 2);
  // Chronological: id 2 first, then id 3
  assert.equal(trend[0].wpm, 80);
  assert.equal(trend[1].wpm, 90);
});
