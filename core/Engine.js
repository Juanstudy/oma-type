// Core typing test engine for oma-type

function createSession(opts) {
  var options = opts || {};
  var mode = options.mode || "time"; // "time" | "quote"
  var duration = typeof options.duration === "number" ? options.duration : 15;
  var wordList = options.words || [];
  var quote = options.quote || null;

  var words = wordList.map(function(text) {
    var chars = [];
    for (var i = 0; i < text.length; i++) {
      chars.push({ char: text[i], state: "pending" });
    }
    return {
      text: text,
      chars: chars,
      extra: ""
    };
  });

  return {
    mode: mode,
    duration: duration,
    quote: quote,
    words: words,
    wordIndex: 0,
    charIndex: 0,
    status: "idle", // "idle" | "running" | "finished"
    startTime: null,
    endTime: null,
    totalKeypresses: 0,
    correctChars: 0,
    incorrectChars: 0,
    extraChars: 0
  };
}

function finishSession(session, now) {
  if (session.status === "finished") return;
  session.status = "finished";
  if (session.mode === "time" && session.startTime !== null) {
    session.endTime = Math.min(now, session.startTime + session.duration * 1000);
  } else {
    session.endTime = now;
  }
}

function handleKey(session, key, timestamp) {
  var now = typeof timestamp === "number" ? timestamp : Date.now();

  if (session.status === "finished") return session;

  // In time mode: check time expiry before processing key
  if (session.mode === "time" && session.status === "running") {
    if (now >= session.startTime + session.duration * 1000) {
      finishSession(session, now);
      return session;
    }
  }

  // Ignore control keys, F-keys, Escape, Tab, etc.
  if (!key || (key.length > 1 && key !== "Backspace" && key !== "Space")) {
    return session;
  }

  // Handle start on first printable character
  if (session.status === "idle") {
    if (key === "Backspace") return session;
    session.status = "running";
    session.startTime = now;
  }

  var currentWord = session.words[session.wordIndex];
  if (!currentWord) {
    finishSession(session, now);
    return session;
  }

  // Space: advance to next word only when current word is fully typed
  if (key === " " || key === "Space") {
    // If user is in the middle of a word, do not jump/skip to the end
    if (session.charIndex < currentWord.chars.length) {
      return session;
    }

    session.totalKeypresses++;

    // Check if current word was completed 100% correctly
    var wordPerfect = true;
    if (currentWord.extra.length > 0) wordPerfect = false;
    for (var i = 0; i < currentWord.chars.length; i++) {
      if (currentWord.chars[i].state !== "correct") {
        wordPerfect = false;
        break;
      }
    }

    if (wordPerfect) {
      // Correct space counts toward WPM
      session.correctChars++;
    }

    session.wordIndex++;
    session.charIndex = 0;

    // Check if we reached beyond all words
    if (session.wordIndex >= session.words.length) {
      finishSession(session, now);
    }
    return session;
  }

  // Backspace: step back
  if (key === "Backspace") {
    if (currentWord.extra.length > 0) {
      currentWord.extra = currentWord.extra.slice(0, -1);
      session.extraChars = Math.max(0, session.extraChars - 1);
      session.totalKeypresses++;
      return session;
    }

    if (session.charIndex > 0) {
      session.charIndex--;
      var lastChar = currentWord.chars[session.charIndex];
      if (lastChar.state === "correct") session.correctChars = Math.max(0, session.correctChars - 1);
      if (lastChar.state === "incorrect") session.incorrectChars = Math.max(0, session.incorrectChars - 1);
      lastChar.state = "pending";
      session.totalKeypresses++;
      return session;
    }

    // Step back to previous word if at start of current word and previous word had mistakes
    if (session.charIndex === 0 && session.wordIndex > 0) {
      var prevWord = session.words[session.wordIndex - 1];
      var hasErrors = prevWord.extra.length > 0;
      if (!hasErrors) {
        for (var c = 0; c < prevWord.chars.length; c++) {
          if (prevWord.chars[c].state !== "correct") {
            hasErrors = true;
            break;
          }
        }
      }
      if (hasErrors) {
        session.wordIndex--;
        session.charIndex = prevWord.chars.length;
        session.totalKeypresses++;
      }
      return session;
    }

    return session;
  }

  // Printable character typing
  session.totalKeypresses++;

  if (session.charIndex < currentWord.chars.length) {
    var target = currentWord.chars[session.charIndex];
    if (key === target.char) {
      target.state = "correct";
      session.correctChars++;
    } else {
      target.state = "incorrect";
      session.incorrectChars++;
    }
    session.charIndex++;

    // In quote mode: if this was the last char of the last word, finish immediately!
    if (session.mode === "quote" &&
        session.wordIndex === session.words.length - 1 &&
        session.charIndex === currentWord.chars.length) {
      finishSession(session, now);
      return session;
    }
  } else {
    // Extra characters past target word
    if (currentWord.extra.length < 15) {
      currentWord.extra += key;
      session.extraChars++;
    }
  }

  return session;
}

function tick(session, timestamp) {
  var now = typeof timestamp === "number" ? timestamp : Date.now();
  if (session.status === "running") {
    if (session.mode === "time") {
      if (now >= session.startTime + session.duration * 1000) {
        finishSession(session, now);
      }
    }
  }
  return session;
}

function calculateStats(session, timestamp) {
  var now = typeof timestamp === "number" ? timestamp : Date.now();

  var elapsedSeconds = 0;
  if (session.status === "idle") {
    elapsedSeconds = 0;
  } else if (session.status === "running") {
    elapsedSeconds = Math.max(0.1, (now - session.startTime) / 1000);
  } else {
    elapsedSeconds = Math.max(0.1, (session.endTime - session.startTime) / 1000);
  }

  var elapsedMinutes = Math.max(0.001, elapsedSeconds / 60);

  var totalTypedChars = session.correctChars + session.incorrectChars + session.extraChars;
  var rawWpm = Math.max(0, Math.round((totalTypedChars / 5) / elapsedMinutes));
  var netWpm = Math.max(0, Math.round((session.correctChars / 5) / elapsedMinutes));

  var accuracy = session.totalKeypresses > 0
    ? Math.max(0, Math.min(100, Math.round((session.correctChars / session.totalKeypresses) * 100)))
    : 100;

  var timeLeft = null;
  if (session.mode === "time") {
    timeLeft = session.status === "idle"
      ? session.duration
      : Math.max(0, Math.ceil(session.duration - (session.status === "finished" ? (session.endTime - session.startTime) / 1000 : elapsedSeconds)));
  }

  return {
    mode: session.mode,
    wpm: netWpm,
    rawWpm: rawWpm,
    accuracy: accuracy,
    timeLeft: timeLeft,
    elapsedSeconds: Math.round(elapsedSeconds * 10) / 10,
    isFinished: session.status === "finished",
    status: session.status,
    totalKeypresses: session.totalKeypresses,
    correctChars: session.correctChars,
    incorrectChars: session.incorrectChars,
    extraChars: session.extraChars,
    quote: session.quote
  };
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    createSession: createSession,
    handleKey: handleKey,
    tick: tick,
    calculateStats: calculateStats
  };
}
