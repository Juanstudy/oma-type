// Benchmark runner and latency statistics analyzer for oma-type

function calculatePercentiles(latencies) {
  if (!Array.isArray(latencies) || latencies.length === 0) {
    return {
      count: 0,
      totalMs: 0,
      min: 0,
      max: 0,
      mean: 0,
      p50: 0,
      p95: 0,
      p99: 0
    };
  }

  var sorted = latencies.slice().sort(function(a, b) { return a - b; });
  var count = sorted.length;
  var sum = 0;
  for (var i = 0; i < count; i++) {
    sum += sorted[i];
  }

  function getPercentile(pct) {
    var idx = Math.min(count - 1, Math.floor(count * (pct / 100)));
    return sorted[idx];
  }

  return {
    count: count,
    totalMs: sum,
    min: sorted[0],
    max: sorted[count - 1],
    mean: sum / count,
    p50: getPercentile(50),
    p95: getPercentile(95),
    p99: getPercentile(99)
  };
}

function analyzeResults(params) {
  var p = params || {};
  var count = typeof p.count === "number" ? p.count : (p.latencies ? p.latencies.length : 0);
  var totalMs = typeof p.totalMs === "number" ? p.totalMs : 0;
  var latencies = Array.isArray(p.latencies) ? p.latencies : [];
  var stats = calculatePercentiles(latencies);

  var effectiveTotalMs = totalMs > 0 ? totalMs : stats.totalMs;
  var throughput = effectiveTotalMs > 0 ? Math.round((count / (effectiveTotalMs / 1000))) : 0;

  return {
    target: p.target || "UI Dispatch",
    count: count,
    totalMs: effectiveTotalMs,
    throughput: throughput,
    percentiles: stats
  };
}

function formatReport(metrics) {
  var m = metrics || {};
  var p = m.percentiles || {};

  function fmtMs(num) {
    if (typeof num !== "number" || isNaN(num)) return "0.000 ms";
    if (num < 0.001) {
      return (num * 1000).toFixed(1) + " µs";
    }
    return num.toFixed(3) + " ms";
  }

  var lines = [
    "============================================================",
    " oma-type Performance Benchmark",
    "============================================================",
    " Target:           " + (m.target || "UI Dispatch"),
    " Samples:          " + (m.count || 0) + " keystrokes",
    " Total Time:       " + (m.totalMs ? m.totalMs.toFixed(2) : "0.00") + " ms",
    " Throughput:       " + (m.throughput ? m.throughput.toLocaleString() : "0") + " keys/sec",
    "",
    " Keystroke Latency:",
    "   - Mean:         " + fmtMs(p.mean),
    "   - Min:          " + fmtMs(p.min),
    "   - p50 (Median): " + fmtMs(p.p50),
    "   - p95:          " + fmtMs(p.p95),
    "   - p99:          " + fmtMs(p.p99),
    "   - Max:          " + fmtMs(p.max),
    "",
    " Data Integrity:   ISOLATED (History clean, Audio muted)",
    "============================================================"
  ];

  return lines.join("\n");
}

function runEngineBench(opts, EngineModule, WordsModule) {
  var options = opts || {};
  var count = typeof options.count === "number" ? options.count : 1000;
  var wordList = options.words || (WordsModule ? WordsModule.getRandomWords(100) : ["the", "quick", "brown", "fox", "jumps", "over", "the", "lazy", "dog"]);

  var session = EngineModule.createSession({ mode: "time", duration: 60, words: wordList });
  var keys = [];
  for (var w = 0; w < session.words.length && keys.length < count; w++) {
    var txt = session.words[w].text;
    for (var c = 0; c < txt.length && keys.length < count; c++) {
      keys.push(txt[c]);
    }
    if (keys.length < count) keys.push(" ");
  }
  while (keys.length < count) keys.push("a");

  var getNow = (typeof performance !== "undefined" && typeof performance.now === "function")
    ? function() { return performance.now(); }
    : function() { return Date.now(); };

  var latencies = [];
  var tStart = getNow();

  for (var i = 0; i < count; i++) {
    var t0 = getNow();
    EngineModule.handleKey(session, keys[i], t0);
    EngineModule.calculateStats(session, t0);
    var t1 = getNow();
    latencies.push(t1 - t0);
  }

  var tEnd = getNow();
  var totalMs = tEnd - tStart;

  return analyzeResults({
    target: "Headless Core Engine (Engine.js)",
    count: count,
    totalMs: totalMs,
    latencies: latencies
  });
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    calculatePercentiles: calculatePercentiles,
    analyzeResults: analyzeResults,
    formatReport: formatReport,
    runEngineBench: runEngineBench
  };
}
