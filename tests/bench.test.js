const test = require("node:test");
const assert = require("node:assert/strict");
const Bench = require("../core/Bench.js");
const Engine = require("../core/Engine.js");
const Words = require("../core/Words.js");

test("Bench: calculatePercentiles handles empty input safely", () => {
  const p = Bench.calculatePercentiles([]);
  assert.equal(p.count, 0);
  assert.equal(p.min, 0);
  assert.equal(p.max, 0);
  assert.equal(p.mean, 0);
  assert.equal(p.p50, 0);
  assert.equal(p.p95, 0);
  assert.equal(p.p99, 0);
});

test("Bench: calculatePercentiles computes accurate percentiles on known distribution", () => {
  // Array 1 to 100
  const latencies = [];
  for (let i = 1; i <= 100; i++) {
    latencies.push(i);
  }

  const p = Bench.calculatePercentiles(latencies);
  assert.equal(p.count, 100);
  assert.equal(p.min, 1);
  assert.equal(p.max, 100);
  assert.equal(p.mean, 50.5);
  assert.equal(p.p50, 51); // index 50
  assert.equal(p.p95, 96); // index 95
  assert.equal(p.p99, 100); // index 99
});

test("Bench: analyzeResults computes correct throughput and total time", () => {
  const latencies = [2, 2, 2, 2, 2]; // 5 keystrokes, 10ms total
  const result = Bench.analyzeResults({
    target: "Test Target",
    count: 5,
    totalMs: 10,
    latencies: latencies
  });

  assert.equal(result.target, "Test Target");
  assert.equal(result.count, 5);
  assert.equal(result.totalMs, 10);
  // 5 / (10 / 1000) = 500 keys/sec
  assert.equal(result.throughput, 500);
  assert.equal(result.percentiles.mean, 2);
});

test("Bench: formatReport produces clear text with ISOLATED data notice", () => {
  const result = Bench.analyzeResults({
    target: "UI Dispatch",
    count: 100,
    totalMs: 50,
    latencies: [0.5, 0.5]
  });

  const report = Bench.formatReport(result);
  assert.ok(report.includes("oma-type Performance Benchmark"));
  assert.ok(report.includes("UI Dispatch"));
  assert.ok(report.includes("ISOLATED (History clean, Audio muted)"));
});

test("Bench: runEngineBench runs headless benchmark without error", () => {
  const result = Bench.runEngineBench({ count: 50 }, Engine, Words);
  assert.equal(result.count, 50);
  assert.ok(result.totalMs >= 0);
  assert.ok(result.throughput >= 0);
  assert.equal(result.percentiles.count, 50);
});
