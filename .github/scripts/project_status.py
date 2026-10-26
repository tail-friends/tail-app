#!/usr/bin/env python3
"""Build the Tail Friends design/API status dashboard without third-party packages."""

from __future__ import annotations

import argparse
import copy
import hashlib
import html
import json
import os
import re
import shutil
import sys
import urllib.error
import urllib.parse
import urllib.request
import zipfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable


ROOT = Path(__file__).resolve().parents[2]
STATUS_ROOT = ROOT / "project-status"
DATA_ROOT = STATUS_ROOT / "data"
SITE_ROOT = STATUS_ROOT / "site"
METADATA_PATTERN = re.compile(r"<!--\s*tail-status\s*(.*?)-->", re.DOTALL | re.IGNORECASE)
ISSUE_PATTERN = re.compile(
    r"(?:closes|fixes|resolves)\s+#(\d+)", re.IGNORECASE
)
ALLOWED_METADATA_KEYS = {
    "figma_numbers",
    "work_type",
    "platforms",
    "completed_scope",
    "completed",
    "api_work_ids",
    "design_version",
    "design_review",
}
PLATFORM_NAMES = {"android": "Android", "ios": "iOS"}


class StatusError(RuntimeError):
    pass


def read_json(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as source:
        return json.load(source)


def write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(value, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace(
        "+00:00", "Z"
    )


def parse_timestamp(value: str) -> datetime:
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def parse_list(value: str) -> list[str]:
    return [item.strip() for item in value.split(",") if item.strip()]


def active_metadata_blocks(body: str | None) -> list[re.Match[str]]:
    # Keep original offsets so automation can replace only the actual block.
    scanned = re.sub(
        r"```.*?```|~~~.*?~~~", lambda match: " " * len(match.group()),
        body or "", flags=re.DOTALL,
    )
    return list(METADATA_PATTERN.finditer(scanned))


def parse_pr_metadata(body: str | None) -> tuple[dict[str, Any] | None, list[str]]:
    matches = active_metadata_blocks(body)
    if not matches:
        return None, ["tail-status 메타데이터 블록이 없습니다."]
    if len(matches) != 1:
        return None, ["tail-status 메타데이터 블록이 중복되어 있습니다."]
    match = matches[0]

    raw: dict[str, str] = {}
    errors: list[str] = []
    for line in match.group(1).splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        if ":" not in stripped:
            errors.append(f"메타데이터 줄 형식이 잘못됐습니다: {stripped}")
            continue
        key, value = stripped.split(":", 1)
        key = key.strip().lower()
        if key not in ALLOWED_METADATA_KEYS:
            errors.append(f"지원하지 않는 메타데이터 키입니다: {key}")
            continue
        if key in raw:
            errors.append(f"메타데이터 키가 중복되어 있습니다: {key}")
        raw[key] = value.strip()

    work_type = raw.get("work_type", "").upper()
    if work_type not in {"UI", "API", "OTHER"}:
        errors.append("work_type은 UI, API, OTHER 중 하나여야 합니다.")

    platforms = [item.lower() for item in parse_list(raw.get("platforms", ""))]
    if work_type in {"UI", "API"} and not platforms:
        errors.append("UI/API 작업에는 platforms가 필요합니다.")
    if any(platform not in PLATFORM_NAMES for platform in platforms):
        errors.append("platforms에는 Android와 iOS만 사용할 수 있습니다.")

    completed_text = raw.get("completed", "").lower()
    if completed_text not in {"true", "false"}:
        errors.append("completed는 true 또는 false여야 합니다.")

    scope = raw.get("completed_scope", "").strip()
    if work_type in {"UI", "API"} and not scope:
        errors.append("completed_scope가 비어 있습니다.")

    metadata = {
        "figma_numbers": parse_list(raw.get("figma_numbers", "")),
        "work_type": work_type,
        "platforms": list(dict.fromkeys(platforms)),
        "completed_scope": scope,
        "completed": completed_text == "true",
        "api_work_ids": parse_list(raw.get("api_work_ids", "")),
        "design_version": raw.get("design_version", "").strip() or None,
        "design_review": raw.get("design_review", "").strip().lower() or None,
    }

    if work_type == "UI" and not metadata["figma_numbers"]:
        errors.append("UI 작업에는 figma_numbers가 필요합니다.")
    if work_type == "API" and not metadata["api_work_ids"]:
        errors.append("API 작업에는 api_work_ids가 필요합니다.")
    if metadata["design_review"] not in {None, "implemented", "no_changes_needed"}:
        errors.append(
            "design_review는 implemented 또는 no_changes_needed만 사용할 수 있습니다."
        )
    return metadata, errors


def github_request(url: str, token: str) -> tuple[Any, dict[str, str]]:
    request = urllib.request.Request(
        url,
        headers={
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {token}",
            "User-Agent": "tail-friends-project-status",
            "X-GitHub-Api-Version": "2022-11-28",
        },
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        payload = json.load(response)
        return payload, dict(response.headers.items())


def fetch_merged_pull_requests(repository: str, token: str) -> list[dict[str, Any]]:
    pulls: list[dict[str, Any]] = []
    for page in range(1, 21):
        query = urllib.parse.urlencode(
            {
                "state": "closed",
                "base": "develop",
                "per_page": 100,
                "page": page,
                "sort": "updated",
                "direction": "desc",
            }
        )
        payload, _ = github_request(
            f"https://api.github.com/repos/{repository}/pulls?{query}", token
        )
        if not isinstance(payload, list):
            raise StatusError("GitHub PR 목록 응답 형식이 올바르지 않습니다.")
        pulls.extend(item for item in payload if item.get("merged_at"))
        if len(payload) < 100:
            break
    return pulls


def merge_figma_state_from_previous(
    designs: list[dict[str, Any]], previous: dict[str, Any] | None
) -> None:
    if not previous:
        return
    previous_designs = {
        item.get("node_id"): item for item in previous.get("designs", [])
    }
    for design in designs:
        old = previous_designs.get(design["node_id"])
        if not old:
            continue
        design["current_design_version"] = old.get("current_design_version")
        design["review_required"] = bool(old.get("review_required"))


def _append_unique(values: list[Any], value: Any) -> None:
    if value not in values:
        values.append(value)


def _related_issue_numbers(body: str | None) -> list[int]:
    return sorted({int(match) for match in ISSUE_PATTERN.findall(body or "")})


def apply_merged_prs(
    designs: list[dict[str, Any]],
    api_catalog: dict[str, Any],
    pulls: Iterable[dict[str, Any]],
    tracking_started_at: str,
) -> tuple[list[dict[str, Any]], list[dict[str, Any]], list[int]]:
    design_by_number = {item["figma_number"]: item for item in designs}
    api_by_id = {item["id"]: item for item in api_catalog.get("tasks", [])}
    review_items: list[dict[str, Any]] = []
    history: list[dict[str, Any]] = []
    applied_prs: set[int] = set()

    for design in designs:
        for platform in PLATFORM_NAMES:
            for pr_number in design["ui"][platform].get("related_prs", []):
                applied_prs.add(int(pr_number))

    for pull in sorted(pulls, key=lambda item: item.get("merged_at") or ""):
        number = int(pull["number"])
        if number in applied_prs:
            continue
        merged_at = pull.get("merged_at")
        if not merged_at or parse_timestamp(merged_at) < parse_timestamp(
            tracking_started_at
        ):
            continue
        if (pull.get("base") or {}).get("ref") not in {None, "develop"}:
            continue

        metadata, errors = parse_pr_metadata(pull.get("body"))
        if metadata:
            unknown_designs = sorted(
                set(metadata["figma_numbers"]) - set(design_by_number)
            )
            unknown_apis = sorted(set(metadata["api_work_ids"]) - set(api_by_id))
            if unknown_designs:
                errors.append(
                    "등록되지 않은 Figma 번호: " + ", ".join(unknown_designs)
                )
            if unknown_apis:
                errors.append("등록되지 않은 API 작업 ID: " + ", ".join(unknown_apis))

        if errors or metadata is None:
            review_items.append(
                {
                    "kind": "pr_metadata",
                    "pr_number": number,
                    "title": pull.get("title", ""),
                    "url": pull.get("html_url"),
                    "merged_at": merged_at,
                    "reasons": errors,
                }
            )
            continue

        related_issues = _related_issue_numbers(pull.get("body"))
        if metadata["work_type"] == "UI":
            for figma_number in metadata["figma_numbers"]:
                design = design_by_number[figma_number]
                for platform in metadata["platforms"]:
                    state = design["ui"][platform]
                    _append_unique(state["related_prs"], number)
                    for issue in related_issues:
                        _append_unique(state["related_issues"], issue)
                    state["merge_date"] = merged_at
                    state["notes"] = [metadata["completed_scope"]]
                    if metadata["completed"]:
                        state["status"] = "complete"
                        state["implemented_version"] = metadata["design_version"]
                    elif state["status"] != "complete":
                        state["status"] = "partial"

                if design.get("review_required"):
                    version_matches = (
                        metadata["design_version"]
                        and metadata["design_version"]
                        == design.get("current_design_version")
                    )
                    if version_matches and metadata["design_review"] in {
                        "implemented",
                        "no_changes_needed",
                    }:
                        design["review_required"] = False

        elif metadata["work_type"] == "API":
            for api_id in metadata["api_work_ids"]:
                task = api_by_id[api_id]
                for platform in metadata["platforms"]:
                    integration = task["integration"][platform]
                    integration["status"] = (
                        "complete" if metadata["completed"] else "partial"
                    )
                    integration["merge_date"] = merged_at
                    _append_unique(integration["related_prs"], number)
                    for issue in related_issues:
                        _append_unique(integration["related_issues"], issue)

        history.append(
            {
                "kind": "merge",
                "pr_number": number,
                "title": pull.get("title", ""),
                "url": pull.get("html_url"),
                "merged_at": merged_at,
                "work_type": metadata["work_type"],
                "platforms": metadata["platforms"],
                "figma_numbers": metadata["figma_numbers"],
                "api_work_ids": metadata["api_work_ids"],
                "completed_scope": metadata["completed_scope"],
                "completed": metadata["completed"],
            }
        )
        applied_prs.add(number)

    return review_items, history, sorted(applied_prs)


def calculate_progress(
    designs: list[dict[str, Any]], api_catalog: dict[str, Any]
) -> dict[str, Any]:
    ui: dict[str, Any] = {}
    total = len(designs)
    for platform in PLATFORM_NAMES:
        complete = sum(
            1
            for item in designs
            if item["ui"][platform]["status"] == "complete"
            and not item["review_required"]
        )
        partial = sum(
            1 for item in designs if item["ui"][platform]["status"] == "partial"
        )
        review = sum(
            1
            for item in designs
            if item["review_required"]
            or item["ui"][platform]["status"] == "needs_confirmation"
        )
        percent = round(complete * 100 / total, 1) if total else 0.0
        ui[platform] = {
            "state": "ready",
            "total": total,
            "complete": complete,
            "partial": partial,
            "review_required": review,
            "remaining": total - complete,
            "percent": percent,
            "remaining_percent": round(100 - percent, 1),
        }

    tasks = api_catalog.get("tasks", [])
    api: dict[str, Any] = {}
    for platform in PLATFORM_NAMES:
        if not tasks:
            api[platform] = {
                "state": "preparing",
                "total": None,
                "complete": None,
                "remaining": None,
                "percent": None,
                "remaining_percent": None,
            }
            continue
        applicable = [
            task for task in tasks if platform in task.get("integration", {})
        ]
        if not applicable:
            api[platform] = {
                "state": "preparing",
                "total": None,
                "complete": None,
                "remaining": None,
                "percent": None,
                "remaining_percent": None,
            }
            continue
        complete = sum(
            1
            for task in applicable
            if task["integration"][platform]["status"] == "complete"
        )
        task_total = len(applicable)
        percent = round(complete * 100 / task_total, 1) if task_total else 0.0
        api[platform] = {
            "state": "ready",
            "total": task_total,
            "complete": complete,
            "remaining": task_total - complete,
            "percent": percent,
            "remaining_percent": round(100 - percent, 1),
        }
    return {"ui": ui, "api": api}


def sync_design_api_status(
    designs: list[dict[str, Any]], api_catalog: dict[str, Any]
) -> None:
    tasks = api_catalog.get("tasks", [])
    for design in designs:
        for platform in PLATFORM_NAMES:
            states = [
                task["integration"][platform]["status"]
                for task in tasks
                if design["figma_number"] in task.get("figma_numbers", [])
                and platform in task.get("integration", {})
            ]
            if not states:
                design["api"][platform] = "not_registered"
            elif all(state == "complete" for state in states):
                design["api"][platform] = "complete"
            elif all(state == "not_started" for state in states):
                design["api"][platform] = "not_started"
            else:
                design["api"][platform] = "partial"


def _canonical_node(value: Any) -> Any:
    ignored = {"lastModified", "thumbnailUrl", "version"}
    if isinstance(value, dict):
        return {
            key: _canonical_node(item)
            for key, item in sorted(value.items())
            if key not in ignored
        }
    if isinstance(value, list):
        return [_canonical_node(item) for item in value]
    return value


def _figma_request(path: str, token: str) -> Any:
    request = urllib.request.Request(
        f"https://api.figma.com{path}",
        headers={"X-Figma-Token": token, "User-Agent": "tail-friends-project-status"},
    )
    with urllib.request.urlopen(request, timeout=60) as response:
        return json.load(response)


def _select_figma_version(
    file_key: str, token: str, requested_version: str | None
) -> dict[str, Any]:
    payload = _figma_request(f"/v1/files/{file_key}/versions?page_size=50", token)
    versions = payload.get("versions", [])
    if requested_version:
        match = next(
            (item for item in versions if str(item.get("id")) == requested_version),
            None,
        )
        if not match:
            raise StatusError(f"Figma 버전 {requested_version}을 찾을 수 없습니다.")
        return match
    named = [item for item in versions if str(item.get("label") or "").strip()]
    if not named:
        raise StatusError("Figma 이름 붙인 버전이 없습니다.")
    return max(named, key=lambda item: item.get("created_at") or "")


def _fetch_figma_hashes(
    file_key: str, version_id: str, node_ids: list[str], token: str
) -> dict[str, str]:
    hashes: dict[str, str] = {}
    for start in range(0, len(node_ids), 20):
        batch = node_ids[start : start + 20]
        query = urllib.parse.urlencode(
            {"ids": ",".join(batch), "version": version_id}
        )
        payload = _figma_request(f"/v1/files/{file_key}/nodes?{query}", token)
        nodes = payload.get("nodes", {})
        for node_id in batch:
            document = (nodes.get(node_id) or {}).get("document")
            if document is None:
                raise StatusError(f"Figma node {node_id} 데이터를 가져오지 못했습니다.")
            encoded = json.dumps(
                _canonical_node(document),
                ensure_ascii=False,
                sort_keys=True,
                separators=(",", ":"),
            ).encode("utf-8")
            hashes[node_id] = hashlib.sha256(encoded).hexdigest()
    return hashes


def sync_figma(
    designs: list[dict[str, Any]],
    previous_figma: dict[str, Any],
    token: str,
    requested_version: str | None,
    accept_baseline: bool,
) -> tuple[dict[str, Any], list[str]]:
    file_key = read_json(STATUS_ROOT / "config.json")["figma"]["file_key"]
    version = _select_figma_version(file_key, token, requested_version)
    version_id = str(version["id"])
    hashes = _fetch_figma_hashes(
        file_key, version_id, [item["node_id"] for item in designs], token
    )
    previous_hashes = previous_figma.get("node_hashes") or {}
    baseline = previous_figma.get("baseline_version")
    figma = copy.deepcopy(previous_figma)
    figma.update(
        {
            "schema_version": 1,
            "current_version": {
                "id": version_id,
                "label": version.get("label") or "",
                "created_at": version.get("created_at"),
            },
            "last_checked_at": utc_now(),
        }
    )

    if not baseline or not previous_hashes:
        if not accept_baseline:
            figma.update(
                {
                    "sync_status": "baseline_required",
                    "changed_designs": [],
                    "message": "첫 동기화 결과입니다. 수동 실행에서 기준 버전 승인이 필요합니다.",
                }
            )
            return figma, []
        figma.update(
            {
                "baseline_version": figma["current_version"],
                "node_hashes": hashes,
                "current_node_hashes": hashes,
                "sync_status": "synced",
                "changed_designs": [],
                "message": "Figma 기준 버전을 저장했습니다.",
            }
        )
        for design in designs:
            design["current_design_version"] = version_id
        return figma, []

    comparison_hashes = previous_figma.get("current_node_hashes") or previous_hashes
    changed_nodes = sorted(
        node_id
        for node_id, current_hash in hashes.items()
        if comparison_hashes.get(node_id) != current_hash
    )
    changed_numbers: list[str] = []
    for design in designs:
        design["current_design_version"] = version_id
        if design["node_id"] in changed_nodes:
            design["review_required"] = True
            changed_numbers.append(design["figma_number"])

    figma.update(
        {
            "current_node_hashes": hashes,
            "sync_status": "synced",
            "changed_designs": changed_numbers,
            "message": (
                f"{len(changed_numbers)}개 디자인 변경을 확인했습니다."
                if changed_numbers
                else "추적 중인 디자인 변경이 없습니다."
            ),
        }
    )
    return figma, changed_numbers


def promote_reviewed_figma_nodes(
    designs: list[dict[str, Any]], figma: dict[str, Any]
) -> None:
    baseline_hashes = figma.get("node_hashes") or {}
    current_hashes = figma.get("current_node_hashes") or {}
    if not baseline_hashes or not current_hashes:
        return
    current_version = (figma.get("current_version") or {}).get("id")
    for design in designs:
        node_id = design["node_id"]
        if (
            not design.get("review_required")
            and node_id in current_hashes
            and baseline_hashes.get(node_id) != current_hashes[node_id]
        ):
            baseline_hashes[node_id] = current_hashes[node_id]
            if current_version:
                design["current_design_version"] = current_version
    figma["node_hashes"] = baseline_hashes
    if not any(design.get("review_required") for design in designs):
        figma["baseline_version"] = figma.get("current_version")


def _xml_escape(value: Any) -> str:
    return html.escape("" if value is None else str(value), quote=False)


def _column_name(index: int) -> str:
    result = ""
    while index:
        index, remainder = divmod(index - 1, 26)
        result = chr(65 + remainder) + result
    return result


def _worksheet(rows: list[list[Any]]) -> str:
    xml_rows: list[str] = []
    for row_index, row in enumerate(rows, start=1):
        cells: list[str] = []
        for column_index, value in enumerate(row, start=1):
            reference = f"{_column_name(column_index)}{row_index}"
            cells.append(
                f'<c r="{reference}" t="inlineStr"><is><t>{_xml_escape(value)}</t></is></c>'
            )
        xml_rows.append(f'<row r="{row_index}">{"".join(cells)}</row>')
    return (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        f'<sheetData>{"".join(xml_rows)}</sheetData></worksheet>'
    )


def write_xlsx(path: Path, status: dict[str, Any]) -> None:
    design_rows: list[list[Any]] = [
        [
            "Figma 번호",
            "이름",
            "Node ID",
            "Android UI",
            "iOS UI",
            "Android API",
            "iOS API",
            "재검토 필요",
            "관련 PR",
            "Merge 날짜",
            "Figma 링크",
        ]
    ]
    for design in status["designs"]:
        prs = sorted(
            set(design["ui"]["android"]["related_prs"])
            | set(design["ui"]["ios"]["related_prs"])
        )
        merge_dates = [
            design["ui"][platform].get("merge_date")
            for platform in PLATFORM_NAMES
            if design["ui"][platform].get("merge_date")
        ]
        design_rows.append(
            [
                design["figma_number"],
                design["name"],
                design["node_id"],
                design["ui"]["android"]["status"],
                design["ui"]["ios"]["status"],
                design["api"]["android"],
                design["api"]["ios"],
                "Y" if design["review_required"] else "N",
                ", ".join(f"#{number}" for number in prs),
                max(merge_dates) if merge_dates else "",
                design["figma_url"],
            ]
        )

    api_rows: list[list[Any]] = [
        [
            "API 작업 ID",
            "메서드",
            "경로",
            "Figma 번호",
            "Android 연동",
            "iOS 연동",
            "관련 PR",
        ]
    ]
    for task in status["api_tasks"]:
        prs = sorted(
            set(task["integration"]["android"]["related_prs"])
            | set(task["integration"]["ios"]["related_prs"])
        )
        api_rows.append(
            [
                task["id"],
                task["method"],
                task["path"],
                ", ".join(task["figma_numbers"]),
                task["integration"]["android"]["status"],
                task["integration"]["ios"]["status"],
                ", ".join(f"#{number}" for number in prs),
            ]
        )

    summary_rows = [["구분", "완료", "전체", "진행률"]]
    for kind in ("ui", "api"):
        for platform in PLATFORM_NAMES:
            item = status["progress"][kind][platform]
            summary_rows.append(
                [
                    f"{PLATFORM_NAMES[platform]} {kind.upper()}",
                    item["complete"] if item["state"] == "ready" else "집계 준비 중",
                    item["total"] if item["state"] == "ready" else "집계 준비 중",
                    f'{item["percent"]}%' if item["state"] == "ready" else "집계 준비 중",
                ]
            )

    sheets = [
        ("Summary", summary_rows),
        ("Designs", design_rows),
        ("API Tasks", api_rows),
    ]
    workbook_sheets = "".join(
        f'<sheet name="{name}" sheetId="{index}" r:id="rId{index}"/>'
        for index, (name, _) in enumerate(sheets, start=1)
    )
    workbook = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        f"<sheets>{workbook_sheets}</sheets></workbook>"
    )
    workbook_rels = "".join(
        f'<Relationship Id="rId{index}" '
        'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" '
        f'Target="worksheets/sheet{index}.xml"/>'
        for index in range(1, len(sheets) + 1)
    )
    content_overrides = "".join(
        f'<Override PartName="/xl/worksheets/sheet{index}.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
        for index in range(1, len(sheets) + 1)
    )

    path.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as archive:
        archive.writestr(
            "[Content_Types].xml",
            '<?xml version="1.0" encoding="UTF-8"?>'
            '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
            '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
            '<Default Extension="xml" ContentType="application/xml"/>'
            '<Override PartName="/xl/workbook.xml" '
            'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
            f"{content_overrides}</Types>",
        )
        archive.writestr(
            "_rels/.rels",
            '<?xml version="1.0" encoding="UTF-8"?>'
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            '<Relationship Id="rId1" '
            'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" '
            'Target="xl/workbook.xml"/></Relationships>',
        )
        archive.writestr("xl/workbook.xml", workbook)
        archive.writestr(
            "xl/_rels/workbook.xml.rels",
            '<?xml version="1.0" encoding="UTF-8"?>'
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            f"{workbook_rels}</Relationships>",
        )
        for index, (_, rows) in enumerate(sheets, start=1):
            archive.writestr(f"xl/worksheets/sheet{index}.xml", _worksheet(rows))


def build_notification(
    event_name: str | None,
    event: dict[str, Any],
    previous: dict[str, Any] | None,
    status: dict[str, Any],
    figma_changes: list[str],
) -> dict[str, Any]:
    notification: dict[str, Any] = {"kind": "none"}
    previous_prs = set((previous or {}).get("applied_prs", []))

    if event_name == "pull_request_target":
        pull = event.get("pull_request") or {}
        number = int(pull.get("number") or event.get("number") or 0)
        if not pull.get("merged") or pull.get("base", {}).get("ref") != "develop":
            return notification
        review = next(
            (
                item
                for item in status["review_items"]
                if item.get("pr_number") == number
            ),
            None,
        )
        if review:
            return {
                "kind": "metadata-review",
                "pr_number": number,
                "title": pull.get("title"),
                "url": pull.get("html_url"),
                "reasons": review["reasons"],
            }
        if number not in previous_prs and number in status["applied_prs"]:
            history = next(
                (
                    item
                    for item in reversed(status["history"])
                    if item.get("pr_number") == number
                ),
                {},
            )
            return {
                "kind": "merge",
                "pr_number": number,
                "title": pull.get("title"),
                "url": pull.get("html_url"),
                "scope": history.get("completed_scope", ""),
                "figma_numbers": history.get("figma_numbers", []),
                "api_work_ids": history.get("api_work_ids", []),
            }

    if figma_changes:
        version = status["figma"].get("current_version") or {}
        previous_version = ((previous or {}).get("figma") or {}).get(
            "current_version"
        ) or {}
        if version.get("id") != previous_version.get("id"):
            changed_set = set(figma_changes)
            details: list[str] = []
            for design in status["designs"]:
                if design["figma_number"] not in changed_set:
                    continue
                related_prs = sorted(
                    set(design["ui"]["android"].get("related_prs", []))
                    | set(design["ui"]["ios"].get("related_prs", []))
                )
                previous_prs = (
                    " · 기존 PR " + ", ".join(f"#{number}" for number in related_prs)
                    if related_prs
                    else ""
                )
                details.append(
                    f'{design["figma_number"]} {design["name"]}{previous_prs}'
                )
            return {
                "kind": "figma-change",
                "version": version,
                "figma_numbers": figma_changes,
                "details": details,
                "figma_url": "https://www.figma.com/design/FpS23pMGjJtXRj0AYVMSDK/",
            }
    return notification


def build(args: argparse.Namespace) -> None:
    config = read_json(STATUS_ROOT / "config.json")
    registry = read_json(DATA_ROOT / "designs.json")
    api_catalog = read_json(DATA_ROOT / "api-tasks.json")
    figma_seed = read_json(DATA_ROOT / "figma-state.json")
    designs = copy.deepcopy(registry["designs"])
    api_tasks = copy.deepcopy(api_catalog)

    previous = None
    if args.previous_status and Path(args.previous_status).is_file():
        previous = read_json(Path(args.previous_status))
        merge_figma_state_from_previous(designs, previous)

    if args.github_fixture:
        pulls = read_json(Path(args.github_fixture))["pull_requests"]
    else:
        token = os.environ.get("GITHUB_TOKEN", "").strip()
        if not token:
            raise StatusError("GITHUB_TOKEN이 없어 Merge 이력을 조회할 수 없습니다.")
        pulls = fetch_merged_pull_requests(args.repository, token)

    review_items, history, applied_prs = apply_merged_prs(
        designs,
        api_tasks,
        pulls,
        config["tracking_started_at"],
    )
    sync_design_api_status(designs, api_tasks)

    previous_figma = copy.deepcopy(
        (previous or {}).get("figma") or figma_seed
    )
    promote_reviewed_figma_nodes(designs, previous_figma)
    figma_changes: list[str] = []
    if args.sync_figma:
        token = os.environ.get("FIGMA_ACCESS_TOKEN", "").strip()
        if not token:
            raise StatusError("FIGMA_ACCESS_TOKEN이 없어 Figma를 동기화할 수 없습니다.")
        figma, figma_changes = sync_figma(
            designs,
            previous_figma,
            token,
            args.figma_version_id,
            args.accept_figma_baseline,
        )
    else:
        figma = previous_figma

    seeded_history: list[dict[str, Any]] = [
        item
        for item in (previous or {}).get("history", [])
        if item.get("kind") == "figma-change"
    ]
    for design in designs:
        for platform in PLATFORM_NAMES:
            state = design["ui"][platform]
            for number in state.get("related_prs", []):
                if number in {20, 22, 24, 29}:
                    seeded_history.append(
                        {
                            "kind": "merge",
                            "pr_number": number,
                            "title": f'{design["full_name"]} UI 초기 완료 이력',
                            "url": f"https://github.com/tail-friends/tail-app/pull/{number}",
                            "merged_at": state.get("merge_date"),
                            "work_type": "UI",
                            "platforms": [platform],
                            "figma_numbers": [design["figma_number"]],
                            "api_work_ids": [],
                            "completed_scope": state.get("notes", [""])[0],
                            "completed": state["status"] == "complete",
                        }
                    )
    if figma_changes:
        version = figma.get("current_version") or {}
        seeded_history.append(
            {
                "kind": "figma-change",
                "title": f'Figma 버전 변경 · {version.get("label") or version.get("id")}',
                "url": "https://www.figma.com/design/FpS23pMGjJtXRj0AYVMSDK/",
                "merged_at": figma.get("last_checked_at"),
                "version_id": version.get("id"),
                "figma_numbers": figma_changes,
                "completed_scope": "재검토 필요: " + ", ".join(figma_changes),
            }
        )
    unique_history = {
        (
            item.get("kind"),
            item.get("pr_number"),
            item.get("version_id"),
            tuple(item.get("figma_numbers", [])),
        ): item
        for item in seeded_history + history
    }
    all_history = sorted(
        unique_history.values(), key=lambda item: item.get("merged_at") or "", reverse=True
    )[:50]

    event = read_json(Path(args.event_path)) if args.event_path else {}
    status = {
        "schema_version": 1,
        "generated_at": utc_now(),
        "repository": args.repository,
        "tracked_base_branch": "develop",
        "status_page_url": None,
        "figma": figma,
        "progress": calculate_progress(designs, api_tasks),
        "designs": designs,
        "api_catalog_status": api_tasks.get("catalog_status", "preparing"),
        "api_tasks": api_tasks.get("tasks", []),
        "review_items": review_items,
        "history": all_history,
        "applied_prs": applied_prs,
    }
    notification = build_notification(
        args.event_name, event, previous, status, figma_changes
    )

    output = Path(args.output)
    resolved_output = output.resolve()
    protected_paths = {ROOT.resolve(), STATUS_ROOT.resolve(), SITE_ROOT.resolve()}
    if resolved_output in protected_paths:
        raise StatusError("출력 경로로 저장소 루트나 원본 현황 경로를 사용할 수 없습니다.")
    if output.exists():
        shutil.rmtree(output)
    shutil.copytree(SITE_ROOT, output)
    write_json(output / "data" / "status.json", status)
    write_json(output / "data" / "notification.json", notification)
    write_xlsx(output / "tail-friends-status.xlsx", status)
    print(json.dumps({"progress": status["progress"], "notification": notification}, ensure_ascii=False))


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser()
    subparsers = result.add_subparsers(dest="command", required=True)
    build_parser = subparsers.add_parser("build")
    build_parser.add_argument("--repository", required=True)
    build_parser.add_argument("--output", required=True)
    build_parser.add_argument("--github-fixture")
    build_parser.add_argument("--previous-status")
    build_parser.add_argument("--event-path")
    build_parser.add_argument("--event-name")
    build_parser.add_argument("--sync-figma", action="store_true")
    build_parser.add_argument("--figma-version-id")
    build_parser.add_argument("--accept-figma-baseline", action="store_true")
    build_parser.set_defaults(handler=build)
    return result


def main() -> int:
    args = parser().parse_args()
    try:
        args.handler(args)
    except (StatusError, urllib.error.URLError, json.JSONDecodeError) as error:
        print(f"::error::{error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
