#!/usr/bin/env node
const Bench = require("../core/Bench.js");
const Engine = require("../core/Engine.js");
const Words = require("../core/Words.js");

const count = parseInt(process.argv[2], 10) || 1000;
const results = Bench.runEngineBench({ count: count }, Engine, Words);
console.log(Bench.formatReport(results));
