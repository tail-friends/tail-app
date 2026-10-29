"""Independent completion, reconciliation and historical-state regression tests."""
from __future__ import annotations

import copy
import json
import sys
import tempfile
import unittest
from pathlib import Path

from test_project_status import ROOT, VALID_UI_BODY, load_registry, merged_pr, project_status as status
sys.path.insert(0, str(ROOT / ".github/scripts"))
import pr_metadata

START = "2026-10-26T00:00:00+09:00"
API_BODY = VALID_UI_BODY.replace("Figma 시각 비교와 UI 상호작용 테스트 완료",
                                 "등록된 API의 실제 요청·응답 연동 테스트 완료")


def target(designs):
    return next(d for d in designs if d["figma_number"] == "04")


def api_catalog():
    # Test-only API operation, never added to the production registry.
    return {"catalog_status": "ready", "tasks": [{
        "id": "API-FIXTURE", "method": "POST", "path": "/fixture-only",
        "figma_numbers": ["04"],
        "integration": {p: {"status": "not_started", "related_prs": [],
                            "related_issues": [], "merge_date": None} for p in status.PLATFORM_NAMES},
    }]}


class IndependentProgressTests(unittest.TestCase):
    def setUp(self):
        self.designs = load_registry()
        self.empty = {"catalog_status": "preparing", "tasks": []}

    def apply(self, body=VALID_UI_BODY, catalog=None, number=100):
        return status.apply_merged_prs(self.designs, catalog or self.empty,
                                      [merged_pr(number, body)], START)

    def test_ui_complete_without_api_specification(self):
        self.apply(VALID_UI_BODY + "\nAPI·DB·AI 연동과 실제 저장은 미구현입니다.")
        progress = status.calculate_progress(self.designs, self.empty)
        self.assertEqual(5, progress["ui"]["android"]["complete"])
        self.assertIsNone(progress["api"]["android"]["percent"])
        status.sync_design_api_status(self.designs, self.empty)
        self.assertEqual("not_registered", target(self.designs)["api"]["android"])

    def test_ui_completion_does_not_complete_registered_api(self):
        catalog = api_catalog()
        self.apply(catalog=catalog)
        status.sync_design_api_status(self.designs, catalog)
        self.assertEqual("complete", target(self.designs)["ui"]["android"]["status"])
        self.assertEqual("not_started", target(self.designs)["api"]["android"])
        self.assertEqual(0.0, status.calculate_progress(self.designs, catalog)["api"]["android"]["percent"])

    def test_api_completion_does_not_complete_ui_or_other_platform(self):
        catalog = api_catalog()
        body = API_BODY.replace("work_type: UI", "work_type: API").replace(
            "api_work_ids:", "api_work_ids: API-FIXTURE")
        self.apply(body, catalog)
        status.sync_design_api_status(self.designs, catalog)
        progress = status.calculate_progress(self.designs, catalog)
        self.assertEqual("not_started", target(self.designs)["ui"]["android"]["status"])
        self.assertEqual(4, progress["ui"]["android"]["complete"])
        self.assertEqual(100.0, progress["api"]["android"]["percent"])
        self.assertEqual(0.0, progress["api"]["ios"]["percent"])

    def test_unverified_metadata_true_cannot_complete_ui(self):
        bodies = [VALID_UI_BODY.replace("c" * 40, "b" * 40),
                  VALID_UI_BODY[VALID_UI_BODY.index("<!--"):],
                  VALID_UI_BODY.replace("완료 여부: 완료", "완료 여부: 확인 필요"),
                  VALID_UI_BODY.replace("Figma 시각 비교와 UI 상호작용 테스트 완료", "CI 성공"),
                  VALID_UI_BODY.replace("Figma 시각 비교와 UI 상호작용 테스트 완료", "Figma 비교 미실행, Widget 테스트 미검증")]
        for body in bodies:
            with self.subTest(body=body[:60]):
                self.designs = load_registry()
                review, _, _ = self.apply(body)
                self.assertEqual("partial", target(self.designs)["ui"]["android"]["status"])
                self.assertEqual("pr_completion", review[0]["kind"])

    def test_unmerged_main_or_unknown_base_cannot_complete(self):
        for changes in [{"merged_at": None}, {"base": {"ref": "main"}}, {"base": {}}]:
            pull = merged_pr(100, VALID_UI_BODY)
            pull.update(changes)
            status.apply_merged_prs(self.designs, self.empty, [pull], START)
        self.assertEqual("not_started", target(self.designs)["ui"]["android"]["status"])

    def test_previously_partial_pr_can_be_confirmed_without_editing_metadata_block(self):
        partial = VALID_UI_BODY.replace("completed: true", "completed: false").replace(
            "완료 여부: 완료", "완료 여부: 확인 필요")
        self.apply(partial)
        confirmed = partial.replace("완료 여부: 확인 필요", "완료 여부: 완료")
        for _ in range(3):
            review, history, applied = self.apply(confirmed)
            self.assertEqual([], review)
            self.assertEqual(1, applied.count(100))
            self.assertEqual(1, len(history))
            self.assertTrue(history[0]["completed"])
        state = target(self.designs)["ui"]["android"]
        self.assertEqual([100], state["related_prs"])
        self.assertEqual([100], state["related_issues"])
        self.assertEqual(1, len(state["completion_history"]))
        self.assertEqual("complete", state["status"])

    def test_later_partial_and_old_replay_preserve_completion_version_date_and_notes(self):
        self.apply()
        original = copy.deepcopy(target(self.designs)["ui"]["android"])
        partial = merged_pr(101, VALID_UI_BODY.replace("completed: true", "completed: false").replace(
            "완료 여부: 완료", "완료 여부: 확인 필요").replace("design_version: version-2", "design_version:"))
        partial["merged_at"] = "2026-10-28T12:00:00Z"
        status.apply_merged_prs(self.designs, self.empty, [partial], START)
        self.apply()
        state = target(self.designs)["ui"]["android"]
        self.assertEqual("complete", state["status"])
        self.assertEqual("version-2", state["implemented_version"])
        self.assertEqual(partial["merged_at"], state["merge_date"])
        self.assertEqual(original["completion_history"], state["completion_history"])

    def test_api_partial_replay_does_not_downgrade_completion(self):
        catalog = api_catalog()
        body = API_BODY.replace("work_type: UI", "work_type: API").replace(
            "api_work_ids:", "api_work_ids: API-FIXTURE")
        self.apply(body, catalog)
        self.apply(body.replace("완료 여부: 완료", "완료 여부: 확인 필요"), catalog)
        state = catalog["tasks"][0]["integration"]["android"]
        self.assertEqual("complete", state["status"])
        self.assertEqual([100], state["related_prs"])
        self.assertEqual(1, len(state["completion_history"]))

    def test_figma_review_not_cleared_by_partial_or_api_pr(self):
        design = target(self.designs)
        design.update(review_required=True, current_design_version="version-2")
        partial = VALID_UI_BODY.replace("완료 여부: 완료", "완료 여부: 확인 필요")
        self.apply(partial)
        self.assertTrue(design["review_required"])
        catalog = api_catalog()
        self.apply(API_BODY.replace("work_type: UI", "work_type: API").replace(
            "api_work_ids:", "api_work_ids: API-FIXTURE"), catalog)
        self.assertTrue(design["review_required"])

    def test_explicit_design_review_fields_reconcile_verified_false_metadata(self):
        design = target(self.designs)
        design.update(review_required=True, current_design_version="version-3")
        body = VALID_UI_BODY.replace("completed: true", "completed: false") + (
            "\n디자인 버전: version-3\n디자인 검토: no_changes_needed")
        review, _, _ = self.apply(body)
        self.assertEqual([], review)
        self.assertFalse(design["review_required"])
        self.assertEqual("version-3", design["ui"]["android"]["implemented_version"])

    def test_figma_change_excludes_ui_count_but_keeps_api_completion(self):
        catalog = api_catalog()
        self.apply()
        catalog["tasks"][0]["integration"]["android"]["status"] = "complete"
        target(self.designs)["review_required"] = True
        status.sync_design_api_status(self.designs, catalog)
        progress = status.calculate_progress(self.designs, catalog)
        self.assertEqual(4, progress["ui"]["android"]["complete"])
        self.assertEqual("complete", target(self.designs)["api"]["android"])
        self.assertEqual(100.0, progress["api"]["android"]["percent"])

    def test_previous_ui_api_history_and_new_api_tasks_are_preserved(self):
        self.apply()
        old_design = copy.deepcopy(target(self.designs))
        old_design.update(review_required=True, current_design_version="version-3")
        old_catalog = api_catalog()
        old_catalog["tasks"][0]["integration"]["android"].update(
            status="complete", related_prs=[200], related_issues=[199], merge_date="2026-10-28T11:00:00Z")
        previous = {"designs": [old_design], "api_tasks": old_catalog["tasks"]}
        designs, catalog = load_registry(), api_catalog()
        second = copy.deepcopy(catalog["tasks"][0])
        second["id"] = "API-SECOND-FIXTURE"
        catalog["tasks"].append(second)
        status.preserve_previous_progress(designs, catalog, previous)
        state = target(designs)["ui"]["android"]
        self.assertEqual(old_design["ui"]["android"], state)
        self.assertTrue(target(designs)["review_required"])
        self.assertEqual("version-3", target(designs)["current_design_version"])
        self.assertEqual("complete", catalog["tasks"][0]["integration"]["android"]["status"])
        self.assertEqual("not_started", catalog["tasks"][1]["integration"]["android"]["status"])
        empty = {"tasks": []}
        status.preserve_previous_progress(designs, empty, previous)
        self.assertEqual([], empty["tasks"])

    def test_live_seven_pr_snapshot_does_not_promote_unapproved_work(self):
        fixture = json.loads((ROOT / '.github/scripts/tests/fixtures/progress-prs-70.json').read_text(encoding='utf-8'))
        for _ in range(2):
            status.apply_merged_prs(self.designs, self.empty, fixture["pull_requests"], START)
        by_number = {d["figma_number"]: d for d in self.designs}
        self.assertEqual("complete", by_number["02-1"]["ui"]["android"]["status"])
        for figma, pr in [("02-0",52),("04",54),("03-1",60),("03-2",62),("04-1",65),("04-2",68)]:
            state = by_number[figma]["ui"]["android"]
            self.assertEqual("partial", state["status"])
            self.assertEqual([pr], state["related_prs"])
        self.assertEqual(5, status.calculate_progress(self.designs, self.empty)["ui"]["android"]["complete"])


class ScopedMetadataTests(unittest.TestCase):
    def plan(self, body, catalog=None, files=None):
        pull = merged_pr(100, body)
        pull.update(state="open", title="Figma 04 UI")
        return pr_metadata.plan(pull, files or ["android-app/lib/features/records/presentation/sheet.dart"], [],
                                {"designs": load_registry(), "figma_file_key":"FpS23pMGjJtXRj0AYVMSDK"}, catalog or {"tasks":[]})

    def test_scoped_ui_confirmation_ignores_unfinished_api_and_debug_only(self):
        body = (VALID_UI_BODY.split("<!--")[0].replace("완료 여부: 완료", "UI 퍼블리싱 완료 여부: 완료")
                + "\nFigma 번호: 04\n작업 종류: UI\nAPI 연동 완료 여부: 미완료\nAPI 작업 ID: API-NOT-REGISTERED\n"
                + "API·DB·AI는 미구현이며 Debug 미리보기만 구현했습니다.")
        result = self.plan(body)
        self.assertTrue(result["metadata"]["completed"])
        self.assertEqual([], result["metadata"]["api_work_ids"])
        self.assertEqual("UI", result["metadata"]["work_type"])

    def test_ui_declaration_cannot_complete_api(self):
        body = (VALID_UI_BODY.split("<!--")[0].replace("완료 여부: 완료", "UI 퍼블리싱 완료 여부: 완료")
                + "\n작업 종류: API\nAPI 작업 ID: API-FIXTURE\nAPI 연동 완료 여부: 미완료")
        result = self.plan(body, api_catalog(), ["android-app/lib/data/client.dart"])
        self.assertFalse(result["metadata"]["completed"])
        self.assertEqual("API", result["metadata"]["work_type"])

    def test_api_requires_integration_evidence_instead_of_ui_test_evidence(self):
        body = VALID_UI_BODY.split("<!--")[0] + "\n작업 종류: API\nAPI 작업 ID: API-FIXTURE"
        self.assertFalse(self.plan(body,api_catalog(),["android-app/lib/data/client.dart"])["metadata"]["completed"])
        body = body.replace("Figma 시각 비교와 UI 상호작용 테스트 완료", "등록된 API의 실제 요청·응답 연동 테스트 완료")
        self.assertTrue(self.plan(body,api_catalog(),["android-app/lib/data/client.dart"])["metadata"]["completed"])

    def test_specific_incomplete_overrides_legacy_complete(self):
        body = VALID_UI_BODY.split("<!--")[0] + "\nUI 퍼블리싱 완료 여부: 확인 필요\nFigma 번호: 04\n작업 종류: UI"
        self.assertFalse(self.plan(body)["metadata"]["completed"])

    def test_explicit_other_automation_does_not_request_app_completion(self):
        pull = merged_pr(100,"작업 종류: OTHER\n자동화 코드만 수정합니다.")
        pull.update(state="open",title="UI 퍼블리싱·API 연동 완료율 집계 개선")
        result = pr_metadata.plan(pull,[".github/scripts/project_status.py"],[],
                                  {"designs":load_registry(),"figma_file_key":"FpS23pMGjJtXRj0AYVMSDK"},{"tasks":[]})
        self.assertEqual("OTHER",result["metadata"]["work_type"])
        self.assertEqual([],result["reasons"])

    def test_manual_false_can_be_reconciled_after_explicit_verified_confirmation(self):
        body = VALID_UI_BODY.replace("completed: true", "completed: false")
        result = self.plan(body)
        self.assertEqual("update", result["action"])
        self.assertTrue(result["metadata"]["completed"])
        self.assertEqual("noop", self.plan(result["body"])["action"])

    def test_invalid_api_reference_is_removed_without_blocking_verified_ui(self):
        body = VALID_UI_BODY.replace("api_work_ids:", "api_work_ids: API-NOT-REGISTERED")
        result = self.plan(body)
        self.assertTrue(result["metadata"]["completed"])
        self.assertEqual([], result["metadata"]["api_work_ids"])

    def test_design_version_and_review_require_explicit_declarations(self):
        body = VALID_UI_BODY.split("<!--")[0] + "\nFigma 번호: 04\n작업 종류: UI"
        self.assertIsNone(self.plan(body)["metadata"]["design_version"])
        result = self.plan(body + "\n디자인 버전: version-3\n디자인 검토: no_changes_needed")
        self.assertEqual("version-3", result["metadata"]["design_version"])
        self.assertEqual("no_changes_needed", result["metadata"]["design_review"])
        self.assertTrue(result["metadata"]["completed"])
        self.assertFalse(self.plan(body + "\n디자인 검토: invented")["metadata"]["completed"])


class ReconciliationBuildTests(unittest.TestCase):
    def test_complete_history_survives_metadata_correction_across_multiple_builds(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            fixture = root / 'pulls.json'
            body = VALID_UI_BODY.replace("완료 여부: 완료", "완료 여부: 확인 필요")
            fixture.write_text(json.dumps({"pull_requests":[merged_pr(100,body)]}),encoding='utf-8')
            previous = root / 'previous.json'
            designs = load_registry()
            target(designs)["ui"]["android"].update(status="complete",related_prs=[100])
            previous.write_text(json.dumps({"designs":designs,"history":[
                {"kind":"merge","pr_number":100,"merged_at":"2026-10-26T10:00:00Z","completed":True,
                 "completed_scope":"previously approved UI"}],"applied_prs":[100]}),encoding='utf-8')
            for index in range(3):
                output = root / f'output-{index}'
                status.build(status.parser().parse_args(['build','--repository','tail-friends/tail-app',
                    '--output',str(output),'--github-fixture',str(fixture),'--previous-status',str(previous),'--dry-run']))
                state=json.loads((output/'data/status.json').read_text(encoding='utf-8'))
                entry=next(h for h in state['history'] if h.get('pr_number')==100)
                self.assertEqual('previously approved UI',entry['previous_completion']['completed_scope'])
                self.assertEqual('complete',target(state['designs'])['ui']['android']['status'])
                previous=output/'data/status.json'

    def test_repeated_build_preserves_history_versions_api_and_notification_dedup(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            fixture = root / 'pulls.json'
            pull = merged_pr(100, VALID_UI_BODY)
            fixture.write_text(json.dumps({"pull_requests":[pull,pull]}),encoding='utf-8')
            previous = root / 'previous.json'
            designs = load_registry()
            old = target(designs)
            old["ui"]["android"].update(status="complete", related_prs=[98],
                related_issues=[97], merge_date="2026-10-28T11:00:00Z", implemented_version="version-3",
                notes=["Debug 미리보기 UI 완료, API 미연동"])
            old.update(review_required=True, current_design_version="version-3")
            history = [{"kind":"merge", "pr_number":n, "merged_at":"2026-10-26T01:00:00Z", "completed":True} for n in range(1000,1060)]
            state = {"designs":designs,"api_tasks":[],"history":history,"applied_prs":[98],
                     "notification_events":["pr:98"],"figma":{"sync_status":"synced"},"review_items":[]}
            previous.write_text(json.dumps(state),encoding='utf-8')
            for index in range(2):
                output = root / f'output-{index}'
                args = status.parser().parse_args(['build','--repository','tail-friends/tail-app',
                    '--output',str(output),'--github-fixture',str(fixture),'--previous-status',str(previous),'--dry-run'])
                status.build(args)
                state = json.loads((output/'data/status.json').read_text(encoding='utf-8'))
                self.assertEqual("version-3", target(state['designs'])["ui"]["android"]["implemented_version"])
                self.assertTrue(target(state['designs'])["review_required"])
                self.assertEqual(1, len([h for h in state['history'] if h.get('pr_number')==100]))
                self.assertGreaterEqual(len(state['history']),61)
                self.assertIn("pr:98",state['notification_events'])
                self.assertIn(98,state['applied_prs'])
                self.assertEqual({'kind':'none'},json.loads((output/'data/notification.json').read_text(encoding='utf-8')))
                previous = output/'data/status.json'

    def test_repeat_merge_or_metadata_review_does_not_send_duplicate_notifications(self):
        pull = merged_pr(100, VALID_UI_BODY)
        pull['merged'] = True
        current = {'review_items':[{'pr_number':100,'reasons':['review']}], 'applied_prs':[100]}
        for previous in [{'applied_prs':[100]}, {'notification_events':['pr:100']}]:
            self.assertEqual({'kind':'none'},status.build_notification('pull_request_target',
                {'pull_request':pull},previous,current,[]))


if __name__ == '__main__':
    unittest.main()
