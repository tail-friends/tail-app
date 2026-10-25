const assert = require("node:assert/strict");
const { matchesStatus } = require("../../../project-status/site/app.js");

assert.equal(matchesStatus("complete", false, "complete"), true);
assert.equal(matchesStatus("complete", true, "complete"), false);
assert.equal(matchesStatus("complete", true, "review"), true);
assert.equal(matchesStatus("complete", true, "incomplete"), true);
assert.equal(matchesStatus("not_started", false, "incomplete"), true);
assert.equal(matchesStatus("not_started", false, "complete"), false);

console.log("status filter rules: OK");
