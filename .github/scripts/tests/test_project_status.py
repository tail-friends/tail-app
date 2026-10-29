from __future__ import annotations

import copy
import importlib.util
import json
import tempfile
import unittest
import zipfile
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[3]
SCRIPT = ROOT / ".github" / "scripts" / "project_status.py"
SPEC = importlib.util.spec_from_file_location("project_status", SCRIPT)
assert SPEC and SPEC.loader
project_status = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(project_status)


def load_registry():
    return json.loads(
        (ROOT / "project-status" / "data" / "designs.json").read_text(
            encoding="utf-8"
        )
    )["designs"]


def merged_pr(number: int, body: str | None, *, base: str = "develop"):
    return {
        "number": number,
        "title": f"PR {number}",
        "body": body,
        "html_url": f"https://github.com/tail-friends/tail-app/pull/{number}",
        "merged_at": "2026-10-26T10:00:00Z",
        "base": {"ref": base},
        "head": {"sha": "c" * 40},
    }


VALID_UI_BODY = """Closes #100
완료 여부: 완료
완료 범위: 기본 화면과 선택 상호작용
완료 근거: Figma 시각 비교와 UI 상호작용 테스트 완료
완료 검증 커밋: cccccccccccccccccccccccccccccccccccccccc
<!-- tail-status
figma_numbers: 04
work_type: UI
platforms: Android
completed_scope: 프로필 기본 화면
completed: true
api_work_ids:
design_version: version-2
design_review: implemented
-->
"""


class RegistryTests(unittest.TestCase):
    def test_registry_tracks_exactly_89_designs_and_seed_history(self):
        designs = load_registry()
        self.assertEqual(89, len(designs))
        by_number = {item["figma_number"]: item for item in designs}
        self.assertEqual("complete", by_number["01"]["ui"]["android"]["status"])
        self.assertEqual("complete", by_number["02"]["ui"]["android"]["status"])
        self.assertEqual("complete", by_number["03"]["ui"]["android"]["status"])
        self.assertEqual("partial", by_number["03-0"]["ui"]["android"]["status"])
        self.assertEqual("partial", by_number["03-5"]["ui"]["android"]["status"])
        species_picker = by_number["03-4"]["ui"]["android"]
        self.assertEqual("complete", species_picker["status"])
        self.assertEqual([28], species_picker["related_issues"])
        self.assertEqual([29], species_picker["related_prs"])
        self.assertEqual("2026-10-25T15:18:04Z", species_picker["merge_date"])

    def test_initial_progress_counts_only_confirmed_completion(self):
        progress = project_status.calculate_progress(
            load_registry(), {"catalog_status": "preparing", "tasks": []}
        )
        self.assertEqual(4, progress["ui"]["android"]["complete"])
        self.assertEqual(89, progress["ui"]["android"]["total"])
        self.assertEqual(4.5, progress["ui"]["android"]["percent"])
        self.assertEqual(0, progress["ui"]["ios"]["complete"])
        self.assertEqual("preparing", progress["api"]["android"]["state"])
        self.assertIsNone(progress["api"]["android"]["percent"])

    def test_design_api_status_is_derived_from_registered_tasks(self):
        designs = load_registry()
        catalog = {
            "tasks": [
                {
                    "id": "API-PET-001",
                    "figma_numbers": ["03"],
                    "integration": {
                        "android": {
                            "status": "complete",
                            "related_prs": [],
                            "related_issues": [],
                        },
                        "ios": {
                            "status": "not_started",
                            "related_prs": [],
                            "related_issues": [],
                        },
                    },
                }
            ]
        }
        project_status.sync_design_api_status(designs, catalog)
        registration = next(
            item for item in designs if item["figma_number"] == "03"
        )
        self.assertEqual("complete", registration["api"]["android"])
        self.assertEqual("not_started", registration["api"]["ios"])
        login = next(item for item in designs if item["figma_number"] == "01")
        self.assertEqual("not_registered", login["api"]["android"])

    def test_api_progress_is_independent_from_ui_progress(self):
        designs = load_registry()
        catalog = {
            "catalog_status": "ready",
            "tasks": [
                {
                    "id": "API-PET-001",
                    "figma_numbers": ["03"],
                    "integration": {
                        "android": {"status": "complete"},
                        "ios": {"status": "not_started"},
                    },
                }
            ],
        }
        progress = project_status.calculate_progress(designs, catalog)
        self.assertEqual(4, progress["ui"]["android"]["complete"])
        self.assertEqual(1, progress["api"]["android"]["complete"])
        self.assertEqual(100.0, progress["api"]["android"]["percent"])
        self.assertEqual(0, progress["api"]["ios"]["complete"])
        self.assertEqual(0.0, progress["api"]["ios"]["percent"])


class PullRequestMetadataTests(unittest.TestCase):
    def test_repository_template_delegates_metadata_to_automation(self):
        template = (ROOT / ".github" / "pull_request_template.md").read_text(
            encoding="utf-8"
        )
        metadata, errors = project_status.parse_pr_metadata(template)
        self.assertIsNone(metadata)
        self.assertEqual(["tail-status 메타데이터 블록이 없습니다."], errors)
        self.assertIn("완료 여부: 확인 필요", template)
        self.assertIn("완료 검증 커밋:", template)

    def test_valid_metadata_is_parsed_without_title_inference(self):
        metadata, errors = project_status.parse_pr_metadata(VALID_UI_BODY)
        self.assertEqual([], errors)
        self.assertEqual(["04"], metadata["figma_numbers"])
        self.assertEqual(["android"], metadata["platforms"])
        self.assertTrue(metadata["completed"])

    def test_missing_or_invalid_metadata_goes_to_review(self):
        designs = load_registry()
        pulls = [
            merged_pr(40, None),
            merged_pr(41, VALID_UI_BODY.replace("04", "99", 1)),
        ]
        review, history, applied = project_status.apply_merged_prs(
            designs,
            {"tasks": []},
            pulls,
            "2026-10-26T00:00:00+09:00",
        )
        self.assertEqual([40, 41], [item["pr_number"] for item in review])
        self.assertEqual([], history)
        self.assertNotIn(40, applied)
        self.assertNotIn(41, applied)

    def test_only_develop_merge_is_applied_once(self):
        designs = load_registry()
        pulls = [
            merged_pr(42, VALID_UI_BODY, base="main"),
            merged_pr(43, VALID_UI_BODY),
            merged_pr(43, VALID_UI_BODY),
        ]
        review, history, applied = project_status.apply_merged_prs(
            designs,
            {"tasks": []},
            pulls,
            "2026-10-26T00:00:00+09:00",
        )
        self.assertEqual([], review)
        self.assertEqual(1, len(history))
        self.assertEqual(1, applied.count(43))
        design = next(item for item in designs if item["figma_number"] == "04")
        self.assertEqual("complete", design["ui"]["android"]["status"])


class FigmaTests(unittest.TestCase):
    def test_changed_node_preserves_completion_and_api_state(self):
        designs = load_registry()
        target = next(item for item in designs if item["figma_number"] == "01")
        node_id = target["node_id"]
        original_api = copy.deepcopy(target["api"])
        previous = {
            "baseline_version": {"id": "version-1"},
            "current_version": {"id": "version-1"},
            "node_hashes": {item["node_id"]: "same" for item in designs},
            "current_node_hashes": {item["node_id"]: "same" for item in designs},
        }
        new_hashes = {item["node_id"]: "same" for item in designs}
        new_hashes[node_id] = "changed"
        with mock.patch.object(
            project_status,
            "_select_figma_version",
            return_value={"id": "version-2", "label": "MVP v2", "created_at": "now"},
        ), mock.patch.object(
            project_status, "_fetch_figma_hashes", return_value=new_hashes
        ):
            state, changed = project_status.sync_figma(
                designs, previous, "token", None, False
            )

        self.assertEqual(["01"], changed)
        self.assertTrue(target["review_required"])
        self.assertEqual("complete", target["ui"]["android"]["status"])
        self.assertEqual(original_api, target["api"])
        self.assertEqual("version-1", state["baseline_version"]["id"])
        progress = project_status.calculate_progress(
            designs, {"catalog_status": "preparing", "tasks": []}
        )
        self.assertEqual(3, progress["ui"]["android"]["complete"])
        self.assertEqual(3.4, progress["ui"]["android"]["percent"])

    def test_review_completion_restores_progress_and_promotes_node_baseline(self):
        designs = load_registry()
        target = next(item for item in designs if item["figma_number"] == "01")
        node_id = target["node_id"]
        previous = {
            "baseline_version": {"id": "version-1"},
            "current_version": {"id": "version-1"},
            "node_hashes": {item["node_id"]: "same" for item in designs},
            "current_node_hashes": {item["node_id"]: "same" for item in designs},
        }
        changed_hashes = {item["node_id"]: "same" for item in designs}
        changed_hashes[node_id] = "changed"
        with mock.patch.object(
            project_status,
            "_select_figma_version",
            return_value={"id": "version-2", "label": "MVP v2", "created_at": "now"},
        ), mock.patch.object(
            project_status, "_fetch_figma_hashes", return_value=changed_hashes
        ):
            figma, _ = project_status.sync_figma(
                designs, previous, "token", None, False
            )

        review_body = """Closes #51
완료 여부: 완료
완료 범위: 디자인 변경 검토
완료 근거: Figma 변경 시각 비교와 UI 회귀 테스트 완료
완료 검증 커밋: cccccccccccccccccccccccccccccccccccccccc
<!-- tail-status
figma_numbers: 01
work_type: UI
platforms: Android
completed_scope: Figma MVP v2 변경 검토 완료
completed: true
api_work_ids:
design_version: version-2
design_review: no_changes_needed
-->
"""
        review_items, _, applied = project_status.apply_merged_prs(
            designs,
            {"tasks": []},
            [merged_pr(50, review_body)],
            "2026-10-26T00:00:00+09:00",
        )
        project_status.promote_reviewed_figma_nodes(designs, figma)
        progress = project_status.calculate_progress(
            designs, {"catalog_status": "preparing", "tasks": []}
        )

        self.assertEqual([], review_items)
        self.assertIn(50, applied)
        self.assertFalse(target["review_required"])
        self.assertEqual([20, 50], target["ui"]["android"]["related_prs"])
        self.assertEqual("changed", figma["node_hashes"][node_id])
        self.assertEqual("version-2", figma["baseline_version"]["id"])
        self.assertEqual(4, progress["ui"]["android"]["complete"])
        self.assertEqual(4.5, progress["ui"]["android"]["percent"])

    def test_next_sync_reports_only_nodes_changed_since_last_checked_version(self):
        designs = load_registry()
        first = next(item for item in designs if item["figma_number"] == "01")
        second = next(item for item in designs if item["figma_number"] == "02")
        first["review_required"] = True
        baseline_hashes = {item["node_id"]: "base" for item in designs}
        current_hashes = copy.deepcopy(baseline_hashes)
        current_hashes[first["node_id"]] = "pending-review"
        next_hashes = copy.deepcopy(current_hashes)
        next_hashes[second["node_id"]] = "new-change"
        previous = {
            "baseline_version": {"id": "version-1"},
            "current_version": {"id": "version-2"},
            "node_hashes": baseline_hashes,
            "current_node_hashes": current_hashes,
        }
        with mock.patch.object(
            project_status,
            "_select_figma_version",
            return_value={"id": "version-3", "label": "MVP v3", "created_at": "now"},
        ), mock.patch.object(
            project_status, "_fetch_figma_hashes", return_value=next_hashes
        ):
            state, changed = project_status.sync_figma(
                designs, previous, "token", None, False
            )

        self.assertEqual(["02"], changed)
        self.assertTrue(first["review_required"])
        self.assertTrue(second["review_required"])
        self.assertEqual("base", state["node_hashes"][first["node_id"]])

    def test_figma_notification_includes_existing_completion_pr(self):
        designs = load_registry()
        status = {
            "figma": {
                "current_version": {"id": "version-2", "label": "MVP v2"}
            },
            "designs": designs,
            "review_items": [],
            "history": [],
            "applied_prs": [],
        }
        notification = project_status.build_notification(
            "repository_dispatch",
            {},
            {"figma": {"current_version": {"id": "version-1"}}},
            status,
            ["01"],
        )
        self.assertEqual("figma-change", notification["kind"])
        self.assertEqual(["01 로그인 · 기존 PR #20"], notification["details"])


class ExportTests(unittest.TestCase):
    def test_xlsx_is_a_valid_open_xml_zip(self):
        designs = load_registry()
        status = {
            "designs": designs,
            "api_tasks": [],
            "progress": project_status.calculate_progress(
                designs, {"catalog_status": "preparing", "tasks": []}
            ),
        }
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "status.xlsx"
            project_status.write_xlsx(path, status)
            self.assertTrue(zipfile.is_zipfile(path))
            with zipfile.ZipFile(path) as archive:
                self.assertIn("xl/workbook.xml", archive.namelist())
                self.assertIn("xl/worksheets/sheet1.xml", archive.namelist())


if __name__ == "__main__":
    unittest.main()
