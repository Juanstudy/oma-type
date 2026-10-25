// History analytics and metrics aggregator for oma-type

function createEntry(stats, mode) {
  var s = stats || {};
  return {
    id: Date.now(),
    timestamp: Date.now(),
    mode: mode || "time",
    wpm: typeof s.wpm === "number" ? s.wpm : 0,
    rawWpm: typeof s.rawWpm === "number" ? s.rawWpm : 0,
    accuracy: typeof s.accuracy === "number" ? s.accuracy : 100,
    elapsedSeconds: typeof s.elapsedSeconds === "number" ? s.elapsedSeconds : 0,
    quoteSource: s.quote && s.quote.source ? String(s.quote.source) : ""
  };
}

function addEntry(historyList, entry, maxEntries) {
  var list = Array.isArray(historyList) ? historyList.slice() : [];
  var limit = typeof maxEntries === "number" ? maxEntries : 200;

  // Newest first
  list.unshift(entry);
  if (list.length > limit) {
    list = list.slice(0, limit);
  }
  return list;
}

function getSummary(historyList) {
  var list = Array.isArray(historyList) ? historyList : [];
  if (list.length === 0) {
    return {
      totalTests: 0,
      bestWpm: 0,
      avgWpm: 0,
      avgAccuracy: 0,
      totalSeconds: 0
    };
  }

  var bestWpm = 0;
  var sumWpm = 0;
  var sumAcc = 0;
  var totalSec = 0;

  for (var i = 0; i < list.length; i++) {
    var item = list[i];
    var w = item.wpm || 0;
    var acc = item.accuracy !== undefined ? item.accuracy : 100;
    var sec = item.elapsedSeconds || 0;

    if (w > bestWpm) bestWpm = w;
    sumWpm += w;
    sumAcc += acc;
    totalSec += sec;
  }

  return {
    totalTests: list.length,
    bestWpm: bestWpm,
    avgWpm: Math.round(sumWpm / list.length),
    avgAccuracy: Math.round(sumAcc / list.length),
    totalSeconds: Math.round(totalSec)
  };
}

function getRecentTrend(historyList, count) {
  var list = Array.isArray(historyList) ? historyList : [];
  var limit = typeof count === "number" ? count : 15;

  // Take the most recent `limit` tests
  var recent = list.slice(0, limit);
  // Reverse so they are in chronological order: oldest -> newest
  recent.reverse();

  return recent.map(function(item, idx) {
    return {
      index: idx + 1,
      wpm: item.wpm || 0,
      rawWpm: item.rawWpm || 0,
      accuracy: item.accuracy !== undefined ? item.accuracy : 100,
      mode: item.mode || "time"
    };
  });
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    createEntry: createEntry,
    addEntry: addEntry,
    getSummary: getSummary,
    getRecentTrend: getRecentTrend
  };
}
