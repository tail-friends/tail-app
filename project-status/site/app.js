const STATUS_LABELS = {
  complete: "완료",
  partial: "일부 구현",
  needs_confirmation: "확인 필요",
  not_started: "미완료",
  not_registered: "집계 준비 중",
};

let statusData;

const escapeHtml = (value) =>
  String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");

function progressCard(label, item) {
  if (item.state !== "ready") {
    return `<article class="progress-card"><span>${label}</span><strong>집계 준비 중</strong><small>확정된 API 작업이 등록되면 계산합니다.</small></article>`;
  }
  return `<article class="progress-card">
    <span>${label}</span>
    <strong>${item.percent}%</strong>
    <div class="bar" aria-label="${label} ${item.percent}%"><span style="width:${item.percent}%"></span></div>
    <small>${item.complete}/${item.total} 완료 · ${item.remaining}개 남음 (${item.remaining_percent}%)</small>
  </article>`;
}

function renderProgress() {
  const progress = statusData.progress;
  document.querySelector("#progress-cards").innerHTML = [
    progressCard("Android UI", progress.ui.android),
    progressCard("iOS UI", progress.ui.ios),
    progressCard("Android API", progress.api.android),
    progressCard("iOS API", progress.api.ios),
  ].join("");
}

function badge(value, reviewRequired = false) {
  if (reviewRequired) return '<span class="badge review">재검토 필요</span>';
  return `<span class="badge ${escapeHtml(value)}">${escapeHtml(STATUS_LABELS[value] || value)}</span>`;
}

function matchesStatus(value, reviewRequired, filter) {
  if (filter === "all") return true;
  if (filter === "complete") return value === "complete" && !reviewRequired;
  if (filter === "review") return reviewRequired || value === "needs_confirmation";
  return value !== "complete";
}

function links(values, kind) {
  if (!values?.length) return "-";
  return values
    .map((number) => `<a href="https://github.com/tail-friends/tail-app/${kind}/${number}" target="_blank" rel="noreferrer">#${number}</a>`)
    .join(", ");
}

function renderDesigns(platform, statusFilter) {
  const rows = statusData.designs.filter((design) => {
    const state = design.ui[platform].status;
    return matchesStatus(state, design.review_required, statusFilter);
  });
  document.querySelector("#status-head").innerHTML = `<tr>
    <th>번호</th><th>화면·상태</th><th>플랫폼</th><th>UI 상태</th>
    <th>API 상태</th><th>Issue</th><th>PR</th><th>버전</th><th>디자인</th>
  </tr>`;
  document.querySelector("#status-body").innerHTML = rows
    .map((design) => {
      const state = design.ui[platform];
      return `<tr>
        <td><strong>${escapeHtml(design.figma_number)}</strong></td>
        <td>${escapeHtml(design.name)}</td>
        <td>${platform === "android" ? "Android" : "iOS"}</td>
        <td>${badge(state.status, design.review_required)}</td>
        <td>${badge(design.api[platform])}</td>
        <td>${links(state.related_issues, "issues")}</td>
        <td>${links(state.related_prs, "pull")}</td>
        <td>${escapeHtml(design.current_design_version || "미동기화")}</td>
        <td><a href="${escapeHtml(design.figma_url)}" target="_blank" rel="noreferrer">Figma 열기</a></td>
      </tr>`;
    })
    .join("");
}

function renderApi(platform, statusFilter) {
  document.querySelector("#status-head").innerHTML = `<tr>
    <th>작업 ID</th><th>메서드</th><th>경로</th><th>Figma 번호</th>
    <th>플랫폼</th><th>연동 상태</th><th>Issue</th><th>PR</th>
  </tr>`;
  if (statusData.api_catalog_status !== "ready") {
    document.querySelector("#status-message").hidden = false;
    document.querySelector("#status-message").textContent =
      "OpenAPI/Swagger 명세가 아직 등록되지 않아 API 진행률은 집계 준비 중입니다.";
    document.querySelector("#status-body").innerHTML = "";
    return;
  }
  const rows = statusData.api_tasks.filter((task) =>
    matchesStatus(task.integration[platform].status, false, statusFilter),
  );
  document.querySelector("#status-body").innerHTML = rows
    .map((task) => {
      const state = task.integration[platform];
      return `<tr>
        <td><strong>${escapeHtml(task.id)}</strong></td>
        <td>${escapeHtml(task.method)}</td>
        <td><code>${escapeHtml(task.path)}</code></td>
        <td>${escapeHtml(task.figma_numbers.join(", "))}</td>
        <td>${platform === "android" ? "Android" : "iOS"}</td>
        <td>${badge(state.status)}</td>
        <td>${links(state.related_issues, "issues")}</td>
        <td>${links(state.related_prs, "pull")}</td>
      </tr>`;
    })
    .join("");
}

function renderTable() {
  const kind = document.querySelector("#kind-filter").value;
  const platform = document.querySelector("#platform-filter").value;
  const filter = document.querySelector("#status-filter").value;
  document.querySelector("#status-message").hidden = true;
  if (kind === "ui") renderDesigns(platform, filter);
  else renderApi(platform, filter);
}

function renderTimeline(target, items, emptyText) {
  document.querySelector(target).innerHTML = items.length
    ? items
        .map((item) => `<div class="timeline-item">
          <p><strong>${escapeHtml(item.title || item.kind)}</strong></p>
          <p>${escapeHtml((item.reasons || []).join(" · ") || item.completed_scope || "")}</p>
          <small>${escapeHtml(item.merged_at || "")}${item.url ? ` · <a href="${escapeHtml(item.url)}" target="_blank" rel="noreferrer">${escapeHtml(item.pr_number ? `#${item.pr_number}` : "Figma")}</a>` : ""}</small>
        </div>`)
        .join("")
    : `<p class="empty">${emptyText}</p>`;
}

async function start() {
  const response = await fetch("./data/status.json", { cache: "no-store" });
  if (!response.ok) throw new Error(`현황 데이터 요청 실패: ${response.status}`);
  statusData = await response.json();
  document.querySelector("#generated-at").textContent =
    `마지막 생성: ${new Date(statusData.generated_at).toLocaleString("ko-KR")}`;
  renderProgress();
  renderTable();
  renderTimeline("#review-items", statusData.review_items, "확인이 필요한 항목이 없습니다.");
  renderTimeline("#history", statusData.history, "Merge 및 변경 이력이 없습니다.");
  document.querySelectorAll("select").forEach((element) =>
    element.addEventListener("change", renderTable),
  );
}

start().catch((error) => {
  document.querySelector("#generated-at").textContent = error.message;
  document.querySelector("#generated-at").style.color = "#a34f42";
});
