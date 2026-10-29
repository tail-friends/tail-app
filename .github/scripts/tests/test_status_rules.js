const assert = require("node:assert/strict");
const fs = require("node:fs");
const { matchesStatus, renderProgress, renderDesigns, renderApi, badge } = require("../../../project-status/site/app.js");

assert.equal(matchesStatus("complete", false, "complete"), true);
assert.equal(matchesStatus("complete", true, "complete"), false);
assert.equal(matchesStatus("complete", true, "review"), true);
assert.equal(matchesStatus("complete", true, "incomplete"), true);
assert.equal(matchesStatus("not_started", false, "incomplete"), true);
assert.equal(matchesStatus("not_started", false, "complete"), false);
assert.equal(matchesStatus("partial", false, "partial"), true);
assert.equal(matchesStatus("partial", true, "partial"), false);
assert.equal(matchesStatus("not_registered", false, "preparing"), true);
assert.equal(matchesStatus("complete", true, "preparing"), false);
assert.match(badge("complete", false, "ui"), /퍼블리싱 완료/);
assert.match(badge("complete", true, "ui"), /재검토 필요/);
assert.doesNotMatch(badge("complete", true, "ui"), /퍼블리싱 완료/);

// Execute the actual renderers with a tiny DOM sink; no browser/package install.
const nodes = {};
global.document = { querySelector: (key) => nodes[key] ||= { innerHTML: "", textContent: "", hidden: true } };
const ready = { state:"ready", complete:1, total:89, remaining:88, percent:1.1, remaining_percent:98.9 };
const preparing = { state:"preparing", complete:null, total:null, percent:null };
const design = (number, ui, api, review=false) => ({
  figma_number:number, name:"테스트", figma_url:"https://www.figma.com/design/test", review_required:review,
  current_design_version:"v2", api:{ android:api },
  ui:{ android:{ status:ui, related_prs:[100], related_issues:[99], notes:["Debug 전용, API 미연동", "<script>bad()</script>"] } },
});
const data = {
  progress:{ ui:{android:ready,ios:ready}, api:{android:preparing,ios:preparing} },
  designs:[design("04", "complete", "not_registered"), design("04-1", "partial", "complete"), design("04-2", "complete", "complete", true)],
  api_catalog_status:"preparing", api_tasks:[],
};
renderProgress(data);
assert.match(nodes["#progress-cards"].innerHTML,/Android UI 머지 진행률/);
assert.match(nodes["#progress-cards"].innerHTML,/iOS API 연동/);
assert.match(nodes["#progress-cards"].innerHTML,/1\/89 완료/);
assert.equal((nodes["#progress-cards"].innerHTML.match(/집계 준비 중/g)||[]).length,2);
const mergedUi = {...ready, merged:3, percent:3.4, remaining:86, remaining_percent:96.6, verified_percent:1.1};
renderProgress({...data, progress:{...data.progress, ui:{android:mergedUi, ios:mergedUi}}});
assert.match(nodes["#progress-cards"].innerHTML,/3\/89 화면 머지/);
assert.match(nodes["#progress-cards"].innerHTML,/검증 완료 1개/);
assert.match(nodes["#progress-cards"].innerHTML,/3.4%/);
assert.doesNotMatch(nodes["#progress-cards"].innerHTML,/null%/);
renderDesigns("android", "complete", data);
assert.equal((nodes["#status-body"].innerHTML.match(/<tr>/g)||[]).length,1);
assert.match(nodes["#status-body"].innerHTML,/집계 준비 중/);
assert.match(nodes["#status-body"].innerHTML,/Debug 전용, API 미연동/);
assert.match(nodes["#status-body"].innerHTML,/&lt;script&gt;/);
assert.doesNotMatch(nodes["#status-body"].innerHTML,/<script>/);
renderDesigns("android", "review", data);
assert.match(nodes["#status-body"].innerHTML,/04-2/);
assert.match(nodes["#status-body"].innerHTML,/재검토 필요/);
assert.match(nodes["#status-body"].innerHTML,/badge complete/); // API stays complete.
renderDesigns("android", "partial", data);
assert.match(nodes["#status-body"].innerHTML,/04-1/);
assert.doesNotMatch(nodes["#status-body"].innerHTML,/04-2/);
renderApi("android", "all", data);
assert.equal(nodes["#status-body"].innerHTML,"");
assert.equal(nodes["#status-message"].hidden,false);
assert.match(nodes["#status-message"].textContent,/집계 준비 중/);
data.api_tasks = [{id:"API-FIXTURE", method:"POST", path:"/fixture-only", figma_numbers:["04"], integration:{android:{status:"complete",related_issues:[],related_prs:[101]}}}];
renderApi("android", "complete", data);
assert.match(nodes["#status-body"].innerHTML,/API-FIXTURE/);
assert.match(nodes["#status-body"].innerHTML,/badge complete/);
renderApi("ios", "all", data);
assert.equal(nodes["#status-body"].innerHTML,"");
const index = fs.readFileSync("project-status/site/index.html","utf8");
assert.match(index,/value="partial"/);
assert.match(index,/value="preparing"/);
assert.match(index,/UI 퍼블리싱과 API 연동은 독립 집계/);

console.log("status filters, independent UI/API renderers and historical page compatibility: OK");
