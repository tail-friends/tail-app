from __future__ import annotations

import copy
import json
import os
import shutil
import subprocess
import sys
import tempfile
import textwrap
import unittest
from pathlib import Path
from unittest.mock import Mock, patch

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / ".github/scripts"))
import pr_metadata as metadata
import project_status


def load(path):
    return json.loads((ROOT / path).read_text(encoding="utf-8"))


class MetadataCase(unittest.TestCase):
    def setUp(self):
        self.registry = load("project-status/data/designs.json")
        self.catalog = load("project-status/data/api-tasks.json")
        self.fixture = load(".github/scripts/tests/fixtures/metadata-pr-42.json")

    def plan(self, fixture=None):
        fixture = fixture or self.fixture
        return metadata.plan(fixture["pull"], fixture["files"], fixture["issues"],
                             self.registry, self.catalog)

    def remove_block(self, fixture=None):
        fixture = fixture or self.fixture
        fixture["pull"]["body"] = metadata.METADATA_PATTERN.sub("", fixture["pull"]["body"])
        return fixture


class MetadataTests(MetadataCase):
    def test_empty_fields_do_not_consume_the_next_line(self):
        for newline in ["\n", "\r\n"]:
            body = newline.join(["- Figma 번호:", "- 작업 종류: OTHER", "- API 작업 ID:", "## 작업 개요"])
            self.assertEqual("", metadata.field(body, "Figma 번호"))
            self.assertEqual("", metadata.field(body, "API 작업 ID"))
            self.assertEqual("OTHER", metadata.field(body, "작업 종류"))

    def test_empty_api_field_in_template_does_not_report_an_unknown_api(self):
        self.fixture["pull"].update(title="자동화 개선", body=(ROOT / ".github/pull_request_template.md").read_text(encoding="utf-8"))
        self.fixture.update(files=[".github/scripts/pr_metadata.py"], issues=[])
        result = self.plan()
        self.assertEqual("OTHER", result["metadata"]["work_type"])
        self.assertEqual([], result["reasons"])

    def test_live_pr42_manual_android_consent_metadata_is_preserved_byte_for_byte(self):
        result = self.plan()
        self.assertEqual("preserve", result["action"])
        self.assertFalse(result["changed"])
        self.assertEqual(self.fixture["pull"]["body"], result["body"])
        self.assertEqual(["01-1"], result["metadata"]["figma_numbers"])
        self.assertEqual(["android"], result["metadata"]["platforms"])
        self.assertTrue(result["metadata"]["completed"])

    def test_live_pr38_manual_ios_draft_metadata_is_preserved_byte_for_byte(self):
        fixture = load(".github/scripts/tests/fixtures/metadata-pr-38.json")
        result = self.plan(fixture)
        self.assertEqual("preserve", result["action"])
        self.assertEqual(fixture["pull"]["body"], result["body"])
        self.assertEqual(["02"], result["metadata"]["figma_numbers"])
        self.assertEqual(["ios"], result["metadata"]["platforms"])
        self.assertFalse(result["metadata"]["completed"])

    def test_both_real_examples_are_inferred_when_metadata_is_absent(self):
        for number, figma, platform in [(42, "01-1", "android"), (38, "02", "ios")]:
            fixture = self.remove_block(load(f".github/scripts/tests/fixtures/metadata-pr-{number}.json"))
            result = self.plan(fixture)
            self.assertEqual("UI", result["metadata"]["work_type"])
            self.assertEqual([figma], result["metadata"]["figma_numbers"])
            self.assertEqual([platform], result["metadata"]["platforms"])
            self.assertFalse(result["metadata"]["completed"])
            parsed, errors = project_status.parse_pr_metadata(result["body"])
            self.assertEqual([], errors)
            self.assertEqual(result["metadata"]["completed"], parsed["completed"])

    def test_linked_issue_and_node_url_infer_target_without_a_figma_pr_title(self):
        self.fixture["pull"].update(title="입력 화면 변경", body="Closes #40")
        result = self.plan()
        self.assertEqual(["01-1"], result["metadata"]["figma_numbers"])
        self.assertEqual(["android"], result["metadata"]["platforms"])

    def test_subscreen_number_is_not_truncated_to_parent(self):
        self.fixture["pull"].update(title="Figma 03-4 종 선택 UI", body="")
        self.fixture["issues"] = []
        self.assertEqual(["03-4"], self.plan()["metadata"]["figma_numbers"])

    def test_explicit_pr_target_overrides_reference_links_and_broader_issue(self):
        self.fixture["pull"].update(title="Figma 03 개체 등록", body=(
            "- Figma 번호: 03-4\n참고: https://www.figma.com/design/FpS23pMGjJtXRj0AYVMSDK/?node-id=15-410"))
        self.assertEqual(["03-4"], self.plan()["metadata"]["figma_numbers"])

    def test_unknown_number_and_other_file_are_not_invented(self):
        self.fixture["pull"].update(title="Figma 99 화면", body="- Figma 번호: 99\nhttps://www.figma.com/design/other/Frame?node-id=33-4032")
        self.fixture["issues"] = []
        result = self.plan()
        self.assertEqual([], result["metadata"]["figma_numbers"])
        self.assertFalse(result["metadata"]["completed"])
        self.assertTrue(any("레지스트리" in reason for reason in result["reasons"]))

    def test_dimensions_issue_numbers_and_excluded_scope_do_not_infer_targets(self):
        self.fixture["pull"].update(title="CI #42 390×844", body="Closes #40\n- 대상: 02\n```\nFigma 03\n```\n<!-- Figma 04 -->")
        self.fixture["issues"] = []
        result = self.plan()
        self.assertEqual([], result["metadata"]["figma_numbers"])
        self.assertEqual("OTHER", result["metadata"]["work_type"])

    def test_wrong_known_manual_target_and_platform_are_corrected(self):
        body = self.fixture["pull"]["body"]
        self.fixture["pull"]["body"] = body.replace("figma_numbers: 01-1", "figma_numbers: 02").replace("platforms: Android", "platforms: iOS")
        result = self.plan()
        self.assertTrue(result["changed"])
        self.assertEqual(["01-1"], result["metadata"]["figma_numbers"])
        self.assertEqual(["android"], result["metadata"]["platforms"])
        self.assertFalse(result["metadata"]["completed"])

    def test_unknown_manual_id_is_replaced_without_losing_explanation(self):
        self.fixture["pull"]["body"] = self.fixture["pull"]["body"].replace("figma_numbers: 01-1", "figma_numbers: 99")
        self.assertIn("## 변경 사항", self.plan()["body"])
        self.assertNotIn("figma_numbers: 99", self.plan()["body"])

    def test_old_empty_template_is_filled(self):
        self.fixture["pull"]["body"] = "Closes #40\n<!-- tail-status\nwork_type: OTHER\ncompleted: false\n-->"
        result = self.plan()
        self.assertEqual("update", result["action"])
        self.assertEqual(["01-1"], result["metadata"]["figma_numbers"])

    def test_docs_only_is_other_not_a_platform_or_completion_guess(self):
        self.fixture.update(files=["docs/readme.md"], issues=[])
        self.fixture["pull"].update(title="문서 정리", body="테스트 통과, PR Merge 완료")
        result = self.plan()
        self.assertEqual("OTHER", result["metadata"]["work_type"])
        self.assertEqual([], result["metadata"]["platforms"])
        self.assertFalse(result["metadata"]["completed"])

    def test_api_tasks_are_never_invented_when_catalog_is_empty(self):
        self.fixture.update(files=["android-app/lib/api/client.dart"], issues=[])
        self.fixture["pull"].update(title="API 연동", body="- API 작업 ID: API-NOT-REGISTERED\n- 완료 여부: 완료")
        result = self.plan()
        self.assertEqual([], result["metadata"]["api_work_ids"])
        self.assertEqual("OTHER", result["metadata"]["work_type"])
        self.assertFalse(result["metadata"]["completed"])

    def test_registered_api_uses_exact_catalog_id_and_independent_kind(self):
        self.catalog["tasks"] = [{"id": "API-PET-TEST", "figma_numbers": ["03"]}]
        self.fixture.update(files=["android-app/lib/data/client.dart"], issues=[])
        self.fixture["pull"].update(title="API 연동", body="- API 작업 ID: API-PET-TEST")
        result = self.plan()
        self.assertEqual("API", result["metadata"]["work_type"])
        self.assertEqual(["API-PET-TEST"], result["metadata"]["api_work_ids"])
        self.assertEqual(["03"], result["metadata"]["figma_numbers"])
        self.assertFalse(result["metadata"]["completed"])

    def test_mixed_ui_api_requires_explicit_choice(self):
        self.remove_block()
        self.fixture["pull"]["body"] = self.fixture["pull"]["body"].replace("작업 종류: UI", "작업 종류:")
        self.fixture["files"].append("android-app/lib/data/client.dart")
        result = self.plan()
        self.assertEqual("OTHER", result["metadata"]["work_type"])
        self.assertFalse(result["metadata"]["completed"])
        self.assertTrue(any("혼합" in reason for reason in result["reasons"]))

    def test_ci_merge_and_issue_goals_do_not_promote_completion(self):
        self.remove_block()
        self.fixture["pull"].update(merged=True, merged_at="2026-10-26", checks="success")
        self.fixture["pull"]["body"] += "\n- 완료 여부: 완료\nCI 성공"
        self.assertFalse(self.plan()["metadata"]["completed"])

    def confirm(self):
        self.remove_block()
        self.fixture["pull"]["body"] += (
            "\n- 완료 근거: 동의 항목 체크와 필수 항목 차단을 실제 화면·테스트로 확인\n"
            f"- 완료 검증 커밋: {self.fixture['pull']['head']['sha']}\n"
        )
        self.fixture["pull"]["body"] = self.fixture["pull"]["body"].replace("완료 여부: UI 구현·검증 완료", "완료 여부: 완료")

    def test_explicit_scope_evidence_and_current_commit_can_confirm_completion(self):
        self.confirm()
        self.assertTrue(self.plan()["metadata"]["completed"])

    def test_ci_or_merge_alone_is_not_completion_evidence(self):
        self.confirm()
        for reason in ["CI 성공", "PR Merge", "tests passed"]:
            original = self.fixture["pull"]["body"]
            self.fixture["pull"]["body"] = original.replace(
                "동의 항목 체크와 필수 항목 차단을 실제 화면·테스트로 확인", reason)
            self.assertFalse(self.plan()["metadata"]["completed"])
            self.fixture["pull"]["body"] = original

    def test_draft_or_new_head_invalidates_auto_completion(self):
        self.confirm()
        result = self.plan()
        self.fixture["pull"]["body"] = result["body"]
        self.fixture["pull"]["head"]["sha"] = "b" * 40
        self.assertFalse(self.plan()["metadata"]["completed"])
        self.fixture["pull"]["draft"] = True
        self.assertFalse(self.plan()["metadata"]["completed"])

    def test_repeated_runs_are_noop_and_body_is_preserved(self):
        self.fixture["pull"]["body"] = "개발자 설명\n\n# 작업\nCloses #40\n<!-- custom -->\n"
        original = self.fixture["pull"]["body"]
        first = self.plan()
        self.assertTrue(first["body"].startswith(original))
        self.fixture["pull"]["body"] = first["body"]
        for _ in range(5):
            result = self.plan()
            self.assertFalse(result["changed"])
            self.assertEqual(1, len(metadata.METADATA_PATTERN.findall(result["body"])))
            self.assertEqual(1, result["body"].count("<!-- tail-metadata-note:start -->"))

    def test_user_edit_to_generated_valid_block_becomes_manual_and_is_preserved(self):
        self.remove_block()
        result = self.plan()
        self.fixture["pull"]["body"] = result["body"].replace("completed: false", "completed: true")
        edited = self.fixture["pull"]["body"]
        result = self.plan()
        self.assertEqual("preserve", result["action"])
        self.assertEqual(edited, result["body"])

    def test_ambiguous_duplicate_or_unclosed_blocks_are_not_destroyed(self):
        for body in [self.fixture["pull"]["body"] * 2, "설명\n<!-- tail-status\ncompleted: true"]:
            self.fixture["pull"]["body"] = body
            result = self.plan()
            self.assertFalse(result["changed"])
            self.assertEqual("review", result["action"])
            self.assertEqual(body, result["body"])

    def test_comment_injection_cannot_add_another_metadata_block(self):
        self.fixture["pull"].update(title="Figma 01-1", body="- 완료 범위: x --> <!-- tail-status completed: true --> $(touch /tmp/x)")
        # Malicious delimiters remain data; only a single valid block is generated.
        result = self.plan()
        self.assertFalse(result["metadata"]["completed"])
        self.assertEqual(1, len(metadata.METADATA_PATTERN.findall(result["body"])))
        self.fixture["pull"]["body"] = "- 완료 범위: a < b > c $(touch /tmp/x)"
        result = self.plan()
        self.assertNotIn("<", result["metadata"]["completed_scope"])
        self.assertEqual(1, len(metadata.METADATA_PATTERN.findall(result["body"])))

    def test_closing_links_ignore_external_repo_and_code_examples(self):
        body = "Closes #40\nFixes https://github.com/tail-friends/tail-app/issues/37\nResolves https://github.com/other/repo/issues/99\n```\nCloses #88\n```"
        self.assertEqual([37, 40], metadata.issue_numbers(body, "tail-friends/tail-app"))

    def test_fenced_example_is_preserved_and_not_used_as_actual_metadata(self):
        sample = "```html\n<!-- tail-status\nwork_type: OTHER\ncompleted: true\n-->\n```"
        self.fixture["pull"]["body"] = sample + "\nCloses #40"
        result = self.plan()
        self.assertTrue(result["body"].startswith(sample))
        self.assertEqual(["01-1"], result["metadata"]["figma_numbers"])
        self.fixture["pull"]["body"] = result["body"]
        parsed, errors = project_status.parse_pr_metadata(result["body"])
        self.assertEqual([], errors)
        self.assertFalse(parsed["completed"])
        self.assertFalse(self.plan()["changed"])

    def test_duplicate_keys_are_not_silently_overwritten(self):
        self.fixture["pull"]["body"] = self.fixture["pull"]["body"].replace(
            "completed: true", "completed: false\ncompleted: true")
        result = self.plan()
        self.assertEqual("review", result["action"])
        self.assertFalse(result["changed"])


class SynchronizeTests(MetadataCase):
    def client(self):
        self.remove_block()
        client = Mock(spec=metadata.GitHub)
        client.repository = "tail-friends/tail-app"
        client.pull.return_value = (copy.deepcopy(self.fixture["pull"]), '"etag"')
        client.files.return_value = self.fixture["files"]
        client.issues.return_value = self.fixture["issues"]
        return client

    def test_dry_run_makes_no_write_request(self):
        client = self.client()
        metadata.synchronize(client, 42, self.registry, self.catalog)
        client.request.assert_not_called()

    def test_apply_patches_only_body_with_conditional_header(self):
        client = self.client()
        metadata.synchronize(client, 42, self.registry, self.catalog, dry_run=False)
        args, kwargs = client.request.call_args
        self.assertEqual(("/repos/tail-friends/tail-app/pulls/42",), args)
        self.assertEqual("PATCH", kwargs["method"])
        self.assertEqual({"body"}, set(kwargs["payload"]))
        self.assertEqual('"etag"', kwargs["etag"])

    def test_simultaneous_human_edit_is_reloaded_before_write(self):
        client = self.client()
        old = copy.deepcopy(self.fixture["pull"])
        latest = copy.deepcopy(old)
        latest["body"] += "\n사용자의 추가 설명"
        client.pull.side_effect = [(old, "old"), (latest, "new"), (latest, "new"), (latest, "new")]
        metadata.synchronize(client, 42, self.registry, self.catalog, dry_run=False)
        self.assertIn("사용자의 추가 설명", client.request.call_args.kwargs["payload"]["body"])
        self.assertEqual(1, client.request.call_count)

    def test_unsupported_base_and_closed_pr_do_not_read_or_write_files(self):
        for changes in [{"base": {"ref": "release"}}, {"state": "closed"}]:
            client = self.client()
            pull = copy.deepcopy(self.fixture["pull"])
            pull.update(changes)
            client.pull.return_value = pull, ""
            self.assertEqual("skip", metadata.synchronize(client, 42, self.registry, self.catalog, dry_run=False)["action"])
            client.files.assert_not_called()
            client.request.assert_not_called()

    def test_incomplete_file_list_cannot_patch_metadata(self):
        client = self.client()
        client.files.return_value = []
        with self.assertRaises(ValueError):
            metadata.synchronize(client, 42, self.registry, self.catalog, dry_run=False)
        client.request.assert_not_called()

    def test_repeated_concurrent_edits_fail_without_overwriting(self):
        client = self.client()
        old = copy.deepcopy(self.fixture["pull"])
        latest = copy.deepcopy(old)
        latest["body"] += "\n사용자 편집"
        client.pull.side_effect = [(old, ""), (latest, "")] * 3
        with self.assertRaises(ValueError):
            metadata.synchronize(client, 42, self.registry, self.catalog, dry_run=False)
        client.request.assert_not_called()


class TransportTests(unittest.TestCase):
    def test_write_payload_is_json_and_cannot_target_another_repository(self):
        client = metadata.GitHub("tail-friends/tail-app", "test-only")
        response = Mock()
        response.read.return_value = b'{}'
        response.headers.get.return_value = ""
        context = Mock()
        context.__enter__ = Mock(return_value=response)
        context.__exit__ = Mock(return_value=False)
        with patch.object(metadata.urllib.request, "urlopen", return_value=context) as urlopen:
            body = '설명 $(not-a-command) `literal`'
            client.request("/repos/tail-friends/tail-app/pulls/42", method="PATCH", payload={"body": body})
            request = urlopen.call_args.args[0]
            self.assertEqual("application/json", request.get_header("Content-type"))
            self.assertEqual({"body": body}, json.loads(request.data))
            with self.assertRaises(ValueError):
                client.request("/repos/other/repo/pulls/42", method="PATCH", payload={"body": body})
            self.assertEqual(1, urlopen.call_count)

    def test_files_are_paginated_not_truncated_to_first_page(self):
        client = metadata.GitHub("tail-friends/tail-app", "test-only")
        with patch.object(client, "request", side_effect=[
            ([{"filename": f"file-{i}"} for i in range(100)], ""),
            ([{"filename": "android-app/lib/presentation/screen.dart"}], ""),
        ]) as request:
            self.assertEqual(101, len(client.files(42)))
            self.assertIn("page=2", request.call_args.args[0])

    def test_linked_issues_include_graphql_and_same_repo_closing_fallback(self):
        client = metadata.GitHub("tail-friends/tail-app", "test-only")
        connection = {"data": {"repository": {"pullRequest": {"closingIssuesReferences": {
            "nodes": [
                {"number": 37, "title": "Figma 02", "body": "", "repository": {"nameWithOwner": "tail-friends/tail-app"}},
                {"number": 99, "repository": {"nameWithOwner": "other/repo"}},
            ], "pageInfo": {"hasNextPage": False, "endCursor": None},
        }}}}}
        with patch.object(client, "request", side_effect=[
            (connection, ""), ({"number": 40, "title": "Figma 01-1", "body": ""}, ""),
        ]) as request:
            issues = client.issues({"number": 42, "body": "Closes #40"})
            self.assertEqual([37, 40], [issue["number"] for issue in issues])
            self.assertEqual("POST", request.call_args_list[0].kwargs["method"])
            self.assertTrue(request.call_args_list[0].kwargs["payload"]["query"].startswith("query("))

    def test_graphql_error_stops_without_a_write(self):
        client = metadata.GitHub("tail-friends/tail-app", "test-only")
        with patch.object(client, "request", return_value=({"errors": [{"message": "denied"}]}, "")) as request:
            with self.assertRaises(ValueError):
                client.issues({"number": 42, "body": "Closes #40"})
            self.assertEqual(1, request.call_count)

    def test_workflow_executes_only_default_branch_without_external_secrets(self):
        workflow = (ROOT / ".github/workflows/project-status-metadata.yml").read_text(encoding="utf-8")
        self.assertIn("ref: refs/heads/${{ github.event.repository.default_branch }}", workflow)
        self.assertIn("persist-credentials: false", workflow)
        self.assertNotIn("pull_request.head", workflow)
        self.assertNotIn("secrets.", workflow)
        self.assertNotIn("github.event.pull_request.body", workflow)
        self.assertIn("cancel-in-progress: false", workflow)

    def test_metadata_updates_do_not_subscribe_to_or_send_external_notifications(self):
        workflow = (ROOT / ".github/workflows/project-status-metadata.yml").read_text(encoding="utf-8")
        discord = (ROOT / ".github/workflows/discord-notify.yml").read_text(encoding="utf-8")
        status = (ROOT / ".github/workflows/project-status.yml").read_text(encoding="utf-8")
        self.assertNotIn("discord-notify.sh", workflow)
        self.assertNotIn("deploy-pages", workflow)
        self.assertNotIn("repository_dispatch:", workflow)
        self.assertNotIn("edited", discord.split("permissions:", 1)[0])
        self.assertIn("types: [closed]", status.split("workflow_dispatch:", 1)[0])


class DeploymentReadinessTests(unittest.TestCase):
    def run_guard(self, *, missing=None, old_parser=False, broken_json=False, broken_module=False):
        workflow = (ROOT / ".github/workflows/project-status-metadata.yml").read_text(encoding="utf-8")
        step = workflow.split("      - name: Check trusted metadata deployment\n", 1)[1].split("\n      - name:", 1)[0]
        code = textwrap.dedent(step.split("          python - <<'PY'\n", 1)[1].rsplit("          PY", 1)[0])
        required = [
            ".github/scripts/pr_metadata.py", ".github/scripts/project_status.py",
            "project-status/data/designs.json", "project-status/data/api-tasks.json",
        ]
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for path in required:
                target = root / path
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT / path, target)
            if missing:
                (root / missing).unlink()
            if old_parser:
                parser = root / ".github/scripts/project_status.py"
                parser.write_text(parser.read_text(encoding="utf-8").replace(
                    "def active_metadata_blocks(", "def _not_yet_deployed("), encoding="utf-8")
            if broken_json:
                (root / "project-status/data/designs.json").write_text("{", encoding="utf-8")
            if broken_module:
                (root / ".github/scripts/pr_metadata.py").write_text("invalid Python !!!", encoding="utf-8")
            output = root / "outputs.txt"
            summary = root / "summary.md"
            env = {**os.environ, "GITHUB_OUTPUT": str(output),
                   "GITHUB_STEP_SUMMARY": str(summary), "PYTHONDONTWRITEBYTECODE": "1"}
            env.pop("GH_TOKEN", None)
            env.pop("GITHUB_TOKEN", None)
            result = subprocess.run([sys.executable, "-c", code], cwd=root, env=env,
                                    capture_output=True, text=True, encoding="utf-8", timeout=15)
            self.assertEqual(0, result.returncode, result.stderr)
            self.assertEqual("", result.stderr)
            return output.read_text(encoding="utf-8"), summary.read_text(encoding="utf-8") if summary.exists() else ""

    def test_each_missing_dependency_skips_safely_without_a_token(self):
        for path in [".github/scripts/pr_metadata.py", ".github/scripts/project_status.py",
                     "project-status/data/designs.json", "project-status/data/api-tasks.json"]:
            with self.subTest(path=path):
                output, summary = self.run_guard(missing=path)
                self.assertEqual("ready=false\n", output)
                self.assertIn("skipping PR body updates", summary)

    def test_older_shared_parser_is_a_deployment_wait_not_an_import_failure(self):
        output, summary = self.run_guard(old_parser=True)
        self.assertEqual("ready=false\n", output)
        self.assertIn("Deploy the workflow, scripts and registries together", summary)

    def test_invalid_registry_json_skips_safely(self):
        output, _ = self.run_guard(broken_json=True)
        self.assertEqual("ready=false\n", output)

    def test_incompatible_module_skips_without_printing_exception_contents(self):
        output, summary = self.run_guard(broken_module=True)
        self.assertEqual("ready=false\n", output)
        self.assertNotIn("invalid Python", summary)

    def test_complete_deployment_is_ready_without_an_api_call_or_token(self):
        output, summary = self.run_guard()
        self.assertEqual("ready=true\n", output)
        self.assertEqual("", summary)

    def test_only_ready_deployment_can_run_the_token_bearing_step(self):
        workflow = (ROOT / ".github/workflows/project-status-metadata.yml").read_text(encoding="utf-8")
        guard, execution = workflow.split("      - name: Generate or preserve tracking metadata", 1)
        self.assertNotIn("GH_TOKEN:", guard)
        self.assertIn("if: steps.deployment.outputs.ready == 'true'", execution)
        self.assertIn("GH_TOKEN: ${{ github.token }}", execution)


if __name__ == "__main__":
    unittest.main()
