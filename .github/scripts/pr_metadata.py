#!/usr/bin/env python3
"""Infer PR tracking metadata from trusted registries; never execute PR content."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any

from project_status import (
    METADATA_PATTERN, PLATFORM_NAMES, active_metadata_blocks, parse_pr_metadata,
)

ROOT = Path(__file__).resolve().parents[2]
ALLOWED_BASES = {"develop", "main"}
OWNER = re.compile(r"<!-- tail-metadata-generated:([a-f0-9]{64}) -->\n?")
NOTE = re.compile(
    r"<!-- tail-metadata-note:start -->.*?<!-- tail-metadata-note:end -->",
    re.DOTALL,
)
CLOSING = re.compile(
    r"\b(?:close[sd]?|fix(?:e[sd])?|resolve[sd]?)\s+"
    r"(?:#(?P<local>\d+)\b|https://github\.com/(?P<repo>[\w.-]+/[\w.-]+)/issues/(?P<url>\d+)\b)",
    re.IGNORECASE,
)
FIGMA_NUMBER = re.compile(r"(?<![\w-])\d{2}(?:-\d+)?(?![\w:-])")
FIGMA_TITLE = re.compile(r"Figma\s*[`'\"“]*(\d{2}(?:-\d+)?)(?![\d:-])", re.I)


def digest(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def visible(body: str) -> str:
    """Ignore comments, fenced examples and tool-owned notices during inference."""
    body = re.sub(r"```.*?```|~~~.*?~~~", "", body, flags=re.S)
    return re.sub(r"<!--.*?-->", "", NOTE.sub("", body), flags=re.S)


def field(body: str, label: str) -> str:
    pattern = rf"^\s*(?:-\s*)?{re.escape(label)}\s*[:：]\s*(.*?)\s*$"
    match = re.search(pattern, visible(body), re.M | re.I)
    return match.group(1).strip().strip("` ") if match else ""


def issue_numbers(body: str, repository: str) -> list[int]:
    return sorted({
        int(match.group("local") or match.group("url"))
        for match in CLOSING.finditer(visible(body))
        if not match.group("repo") or match.group("repo").lower() == repository.lower()
    })


def platforms_for(files: list[str]) -> list[str]:
    return [name for prefix, name in [("android-app/", "android"), ("ios-app/", "ios")]
            if any(path.startswith(prefix) for path in files)]


def references(
    title: str, body: str, registry: dict[str, Any]
) -> tuple[set[str], bool]:
    """Only explicit Figma numbers/node URLs are evidence, not arbitrary numbers."""
    numbers = set(FIGMA_TITLE.findall(title))
    explicit = field(body, "Figma 번호")
    explicit_numbers = set(FIGMA_NUMBER.findall(explicit))
    nodes = {item["node_id"]: item["figma_number"] for item in registry["designs"]}
    unknown = False
    text = visible(body)
    for url in re.findall(r"https://(?:www\.)?figma\.com/design/[^\s<>`)]+", text):
        parts = urllib.parse.urlsplit(url.replace("&amp;", "&"))
        key = parts.path.split("/")[2]
        if key != registry["figma_file_key"]:
            unknown = True
            continue
        for node in urllib.parse.parse_qs(parts.query).get("node-id", []):
            number = nodes.get(node.replace("-", ":"))
            if number:
                numbers.add(number)
            else:
                unknown = True
    # Node identifiers explicitly supplied in a Figma issue/PR title.
    if "figma" in title.lower():
        for node in re.findall(r"\b\d+:\d+\b", title):
            if node in nodes:
                numbers.add(nodes[node])
    known = {item["figma_number"] for item in registry["designs"]}
    if explicit_numbers:
        # A deliberate target field takes precedence over reference links.
        numbers = explicit_numbers
    unknown = unknown or bool(numbers - known)
    return numbers & known, unknown


def infer(
    pull: dict[str, Any], files: list[str], issues: list[dict[str, Any]],
    registry: dict[str, Any], catalog: dict[str, Any],
) -> tuple[dict[str, Any], list[str]]:
    body = pull.get("body") or ""
    platforms = platforms_for(files)
    reasons: list[str] = []
    numbers, unknown = references(pull.get("title", ""), body, registry)
    issue_numbers_found: set[str] = set()
    for issue in issues:
        found, invalid = references(issue.get("title", ""), issue.get("body") or "", registry)
        issue_numbers_found.update(found)
        if not numbers:
            unknown |= invalid
    if not numbers:
        numbers = issue_numbers_found
    if unknown:
        reasons.append("레지스트리에 없는 Figma 번호·노드 또는 다른 파일 링크를 확인해 주세요.")

    tasks = {task["id"]: task for task in catalog["tasks"]}
    api_ids: set[str] = set()
    for text in [field(body, "API 작업 ID"), *(issue.get("title", "") + "\n" + field(issue.get("body") or "", "API 작업 ID") for issue in issues)]:
        api_ids.update(task_id for task_id in tasks
                       if re.search(rf"(?<![\w-]){re.escape(task_id)}(?![\w-])", text))
    explicit_api = field(body, "API 작업 ID")
    if explicit_api and explicit_api not in {"해당 없음", "없음", "미정", "-"}:
        supplied = {item.strip().strip("` ") for item in explicit_api.split(",")}
        if supplied - tasks.keys():
            reasons.append("등록되지 않은 API 작업 ID는 입력하지 않았습니다. 명세·레지스트리를 확인해 주세요.")

    app_files = [p.lower() for p in files if p.startswith(("android-app/", "ios-app/"))]
    ui = any(re.search(r"/(?:presentation|features)/|(?:view|screen)\.swift$", p) for p in app_files)
    api = bool(api_ids) or any(re.search(r"/(?:data|api|network|repositories|services)/.*\.(?:dart|swift)$", p) for p in app_files)
    # Titles are only classification hints; they never prove completion.
    titles = "\n".join([pull.get("title", ""), *(i.get("title", "") for i in issues)])
    api |= bool(re.search(r"API\s*(?:연동|통합|integration)", titles, re.I))
    ui |= bool(numbers and platforms and re.search(r"\bUI\b|퍼블리싱|화면", titles, re.I))
    selected_type = field(body, "작업 종류").upper()
    if selected_type in {"UI", "API", "OTHER"}:
        kind = selected_type
    elif ui and api:
        kind = "OTHER"
        reasons.append("UI/API 혼합 변경입니다. 집계할 작업 종류와 완료 범위를 명시해 주세요.")
    else:
        kind = "API" if api else "UI" if ui else "OTHER"
    if kind in {"UI", "API"} and not platforms:
        reasons.append("앱 변경 경로에서 플랫폼을 확인할 수 없습니다.")
        kind = "OTHER"
    if kind == "UI" and not numbers:
        reasons.append("UI 대상 Figma 번호를 Issue 또는 PR의 Figma 번호 항목에 명시해 주세요.")
        kind = "OTHER"
    if kind == "API" and not api_ids:
        reasons.append("확정된 API 작업 ID가 없습니다. API 명세·레지스트리 등록이 필요합니다.")
        kind = "OTHER"
    for api_id in api_ids:
        numbers.update(number for number in tasks[api_id].get("figma_numbers", [])
                       if number in {item["figma_number"] for item in registry["designs"]})

    scope = field(body, "완료 범위")
    confirmed = field(body, "완료 여부") in {"완료", "true"}
    evidence = field(body, "완료 근거")
    verified_sha = field(body, "완료 검증 커밋")
    only_ci_or_merge = bool(re.fullmatch(
        r"(?:CI\s*(?:성공|통과)|(?:PR\s*)?(?:Merge|머지)(?:\s*완료)?|tests? passed)[.! ]*",
        evidence, re.I,
    ))
    completed = bool(
        confirmed and scope and evidence and not only_ci_or_merge
        and verified_sha == pull.get("head", {}).get("sha")
        and re.fullmatch(r"[a-f0-9]{40}", verified_sha)
        and kind in {"UI", "API"} and not pull.get("draft") and not reasons
    )
    if not completed and (kind in {"UI", "API"} or ui or api or numbers):
        reasons.append("완료 여부·완료 범위·완료 근거·현재 HEAD의 완료 검증 커밋을 확인해 주세요. CI 성공·Merge는 완료 근거로 추정하지 않습니다.")
    if pull.get("draft"):
        reasons.append("Draft PR은 완료로 자동 처리하지 않습니다.")
    # Strip comment delimiters/newlines from user-controlled single-line fields.
    scope = " ".join(re.sub(r"[<>]", " ", scope).splitlines()).strip()[:1000]
    return {
        "figma_numbers": sorted(numbers), "work_type": kind, "platforms": platforms,
        "completed_scope": scope or "변경 파일 기반 자동 추정; 완료 범위 확인 필요",
        "completed": completed, "api_work_ids": sorted(api_ids),
        "design_version": None, "design_review": None,
    }, list(dict.fromkeys(reasons))


def valid_manual(metadata: dict[str, Any], pull: dict[str, Any], files: list[str],
                 issues: list[dict[str, Any]], registry: dict[str, Any], catalog: dict[str, Any]) -> bool:
    known = {item["figma_number"] for item in registry["designs"]}
    apis = {item["id"] for item in catalog["tasks"]}
    platforms = platforms_for(files)
    if set(metadata["figma_numbers"]) - known or set(metadata["api_work_ids"]) - apis:
        return False
    if metadata["work_type"] in {"UI", "API"}:
        if set(metadata["platforms"]) != set(platforms):
            return False
    numbers, _ = references(pull.get("title", ""), pull.get("body") or "", registry)
    if not numbers:
        for issue in issues:
            found, _ = references(issue.get("title", ""), issue.get("body") or "", registry)
            numbers.update(found)
    if numbers and metadata["work_type"] == "UI" and set(metadata["figma_numbers"]) != numbers:
        return False
    # OTHER is a deliberate opt-out only when it contains no UI/API targets.
    if metadata["work_type"] == "OTHER" and (metadata["figma_numbers"] or metadata["api_work_ids"]):
        return False
    return not (pull.get("draft") and metadata["completed"])


def render(metadata: dict[str, Any]) -> str:
    rows = {
        **metadata,
        "figma_numbers": ", ".join(metadata["figma_numbers"]),
        "platforms": ", ".join(PLATFORM_NAMES[p] for p in metadata["platforms"]),
        "completed": str(metadata["completed"]).lower(),
        "api_work_ids": ", ".join(metadata["api_work_ids"]),
    }
    return "<!-- tail-status\n" + "\n".join(f"{key}: {value or ''}" for key, value in rows.items()) + "\n-->"


def plan(pull: dict[str, Any], files: list[str], issues: list[dict[str, Any]],
         registry: dict[str, Any], catalog: dict[str, Any]) -> dict[str, Any]:
    original = pull.get("body") or ""
    if pull.get("base", {}).get("ref") not in ALLOWED_BASES or pull.get("state", "open") != "open":
        return {"body": original, "changed": False, "action": "skip", "reasons": []}
    scanned = re.sub(r"```.*?```|~~~.*?~~~", lambda m: " " * len(m.group()), original, flags=re.S)
    matches = active_metadata_blocks(original)
    if len(matches) > 1 or (re.search(r"<!--\s*tail-status\b", scanned, re.I) and not matches):
        return {"body": original, "changed": False, "action": "review",
                "reasons": ["중복·닫히지 않은 tail-status 블록을 수동으로 정리해 주세요. 본문은 보존했습니다."]}
    metadata, errors = parse_pr_metadata(matches[0].group() if matches else "")
    if matches:
        keys = [line.strip().split(":", 1)[0].lower() for line in matches[0].group(1).splitlines()
                if ":" in line]
        if len(keys) != len(set(keys)):
            return {"body": original, "changed": False, "action": "review",
                    "reasons": ["tail-status의 중복 키를 정리한 뒤 다시 실행해 주세요."]}
    owner = OWNER.search(original)
    managed = bool(owner and matches and owner.end() == matches[0].start()
                   and owner.group(1) == digest(matches[0].group()))
    # The old repository template was syntactically valid OTHER but empty, not an opt-out.
    placeholder = bool(metadata and not metadata["completed_scope"] and not metadata["figma_numbers"]
                       and not metadata["api_work_ids"] and not metadata["platforms"])
    if (not managed and not placeholder and metadata and not errors
            and valid_manual(metadata, pull, files, issues, registry, catalog)):
        return {"body": original, "changed": False, "action": "preserve", "reasons": [],
                "metadata": metadata}
    metadata, reasons = infer(pull, files, issues, registry, catalog)
    block = render(metadata)
    replacement = f"<!-- tail-metadata-generated:{digest(block)} -->\n{block}"
    body = original
    if matches:
        start = owner.start() if owner and owner.end() == matches[0].start() else matches[0].start()
        body = body[:start] + replacement + body[matches[0].end():]
    else:
        body += ("\n\n" if body else "") + replacement
    notice = ""
    if reasons:
        notice = ("<!-- tail-metadata-note:start -->\n"
                  "자동 메타데이터 확인 필요:\n" + "\n".join(f"- {reason}" for reason in reasons)
                  + "\n<!-- tail-metadata-note:end -->")
    if NOTE.search(body):
        body = NOTE.sub(lambda _: notice, body)
    elif notice:
        body += "\n\n" + notice
    if len(body) > 65000:
        return {"body": original, "changed": False, "action": "review",
                "reasons": ["본문 길이 제한에 가까워 자동 수정을 보류했습니다."]}
    return {"body": body, "changed": body != original, "action": "update" if body != original else "noop",
            "reasons": reasons, "metadata": metadata}


class GitHub:
    def __init__(self, repository: str, token: str):
        if not re.fullmatch(r"[\w.-]+/[\w.-]+", repository):
            raise ValueError("잘못된 저장소 이름입니다.")
        self.repository = repository
        self.token = token

    def request(self, path: str, *, payload: Any = None, method: str = "GET", etag: str = ""):
        if path != "/graphql" and not path.startswith(f"/repos/{self.repository}/"):
            raise ValueError("허용되지 않은 GitHub API 경로입니다.")
        headers = {"Authorization": f"Bearer {self.token}", "Accept": "application/vnd.github+json",
                   "X-GitHub-Api-Version": "2022-11-28", "User-Agent": "tail-pr-metadata"}
        if payload is not None:
            headers["Content-Type"] = "application/json"
        if etag:
            headers["If-Match"] = etag
        data = json.dumps(payload).encode("utf-8") if payload is not None else None
        request = urllib.request.Request("https://api.github.com" + path, data=data,
                                         headers=headers, method=method)
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.load(response), response.headers.get("ETag", "")

    def pull(self, number: int):
        return self.request(f"/repos/{self.repository}/pulls/{number}")

    def files(self, number: int) -> list[str]:
        files = []
        for page in range(1, 32):
            batch, _ = self.request(f"/repos/{self.repository}/pulls/{number}/files?per_page=100&page={page}")
            files.extend(item["filename"] for item in batch)
            if len(batch) < 100:
                return files
        raise ValueError("변경 파일 페이지 한도를 초과했습니다.")

    def issues(self, pull: dict[str, Any]) -> list[dict[str, Any]]:
        owner, name = self.repository.split("/")
        query = """query($owner:String!,$name:String!,$number:Int!,$cursor:String){
          repository(owner:$owner,name:$name){pullRequest(number:$number){
            closingIssuesReferences(first:100,after:$cursor){
              nodes{number title body repository{nameWithOwner}}
              pageInfo{hasNextPage endCursor}}}}}"""
        issues: dict[int, dict[str, Any]] = {}
        cursor = None
        for _ in range(20):
            data, _ = self.request("/graphql", method="POST", payload={
                "query": query, "variables": {"owner": owner, "name": name,
                "number": pull["number"], "cursor": cursor}})
            if data.get("errors"):
                raise ValueError("연결된 Issue 조회에 실패했습니다. 본문은 수정하지 않았습니다.")
            connection = data["data"]["repository"]["pullRequest"]["closingIssuesReferences"]
            for issue in connection["nodes"]:
                if issue["repository"]["nameWithOwner"].lower() == self.repository.lower():
                    issues[issue["number"]] = issue
            if not connection["pageInfo"]["hasNextPage"]:
                break
            cursor = connection["pageInfo"]["endCursor"]
        else:
            raise ValueError("Issue 페이지 한도를 초과했습니다.")
        for number in issue_numbers(pull.get("body") or "", self.repository):
            if number not in issues:
                issue, _ = self.request(f"/repos/{self.repository}/issues/{number}")
                if "pull_request" not in issue:
                    issues[number] = issue
        return list(issues.values())


def snapshot(pull: dict[str, Any]) -> tuple:
    return tuple(json.dumps(pull.get(key), sort_keys=True) for key in
                 ("body", "title", "head", "base", "draft", "state", "updated_at"))


def synchronize(client: GitHub, number: int, registry: dict, catalog: dict,
                *, dry_run: bool = True) -> dict:
    for _ in range(3):
        pull, etag = client.pull(number)
        if pull.get("base", {}).get("ref") not in ALLOWED_BASES or pull.get("state") != "open":
            return {"action": "skip", "changed": False, "reasons": []}
        files = client.files(number)
        if len(files) != pull.get("changed_files"):
            raise ValueError("전체 변경 파일을 확인할 수 없어 본문 수정을 보류했습니다.")
        result = plan(pull, files, client.issues(pull), registry, catalog)
        if dry_run or not result["changed"]:
            return result
        latest, _ = client.pull(number)
        if snapshot(latest) != snapshot(pull):
            continue
        try:
            client.request(f"/repos/{client.repository}/pulls/{number}",
                           method="PATCH", payload={"body": result["body"]}, etag=etag)
        except urllib.error.HTTPError as error:
            if error.code in {409, 412}:
                continue
            raise
        return result
    raise ValueError("PR이 동시에 수정되어 자동 갱신을 보류했습니다. 다시 실행해 주세요.")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repository", default=os.environ.get("GITHUB_REPOSITORY"))
    parser.add_argument("--pr-number", type=int)
    parser.add_argument("--fixture", type=Path, help="Offline PR/files/issues JSON")
    parser.add_argument("--output", type=Path, help="Write plan JSON locally")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--apply", action="store_true", help="Patch only the PR body")
    mode.add_argument("--dry-run", action="store_true", help="Read only (default)")
    args = parser.parse_args()
    registry = json.loads((ROOT / "project-status/data/designs.json").read_text(encoding="utf-8"))
    catalog = json.loads((ROOT / "project-status/data/api-tasks.json").read_text(encoding="utf-8"))
    if args.fixture:
        if args.apply:
            parser.error("fixture는 읽기 전용 검증에만 사용할 수 있습니다.")
        fixture = json.loads(args.fixture.read_text(encoding="utf-8"))
        result = plan(fixture["pull"], fixture["files"], fixture["issues"], registry, catalog)
    else:
        if not args.pr_number or args.pr_number <= 0 or args.repository != "tail-friends/tail-app":
            parser.error("tail-friends/tail-app의 양수 PR 번호가 필요합니다.")
        token = os.environ.get("GH_TOKEN")
        if not token:
            parser.error("GH_TOKEN이 필요합니다. fixture 또는 읽기 전용 토큰으로 검증하세요.")
        result = synchronize(GitHub(args.repository, token), args.pr_number, registry, catalog,
                             dry_run=not args.apply)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    # Do not echo untrusted PR content or tokens into Actions logs/commands.
    summary = f"메타데이터 처리: {result['action']} / 확인 항목 {len(result['reasons'])}개"
    print(summary)
    if os.environ.get("GITHUB_STEP_SUMMARY"):
        with open(os.environ["GITHUB_STEP_SUMMARY"], "a", encoding="utf-8") as output:
            output.write(summary + "\n\n" + "\n".join(f"- {reason}" for reason in result["reasons"]) + "\n")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except urllib.error.HTTPError as error:
        print(f"GitHub API 요청 실패 (HTTP {error.code}); 토큰·본문·응답은 출력하지 않습니다.", file=sys.stderr)
        raise SystemExit(1)
    except (ValueError, KeyError, OSError) as error:
        # Exceptions may include attacker-controlled content; never print raw values.
        print(f"메타데이터 갱신 실패 ({type(error).__name__}); 본문을 확인해 주세요.", file=sys.stderr)
        raise SystemExit(1)
