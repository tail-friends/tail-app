"""Existing Discord message generation only; network calls are forbidden."""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]


@unittest.skipUnless(shutil.which("bash") and shutil.which("jq"), "Bash and jq required")
class DiscordDryRunTests(unittest.TestCase):
    def run_message(self, kind, **changes):
        env = {**os.environ, "DRY_RUN":"1", "DISCORD_WEBHOOK_URL":"",
               "PR_TITLE":"UI preview $(exit 99)", "PR_NUMBER":"100", "PR_BASE":"develop",
               "PR_URL":"https://github.com/tail-friends/tail-app/pull/100", "PR_AUTHOR":"author",
               "PR_BODY":"## Summary\nUI only, no API", "PR_REVIEWERS":"reviewer author",
               "PR_MERGED_BY":"reviewer", "REVIEW_AUTHOR":"reviewer", "REVIEW_BODY":"Review example",
               "DISCORD_USER_MAP":json.dumps({"author":"111111111111111111","reviewer":"222222222222222222"}),
               "DISCORD_APP_MENTIONS":"<@111111111111111111> <@222222222222222222>", **changes}
        shell = 'function curl() { echo "network forbidden" >&2; return 99; }; export -f curl; '
        if os.name == "nt":
            # Native Windows jq needs binary stdout for Bash command substitutions.
            shell += 'function jq() { command jq.exe -b "$@"; }; export -f jq; '
        shell += 'bash .github/scripts/discord-notify.sh "$1"'
        result = subprocess.run([shutil.which("bash"), "-c", shell, "--", kind], env=env,
                                cwd=ROOT, capture_output=True, text=True, encoding="utf-8")
        self.assertEqual(0, result.returncode, result.stderr)
        return json.loads(result.stdout)

    def test_existing_pr_notifications_and_reviewer_mentions(self):
        for kind in ("pr-opened", "review-requested", "pr-merged"):
            with self.subTest(kind=kind):
                payload = self.run_message(kind)
                self.assertIn("#100", payload["embeds"][0]["title"])
                self.assertEqual([], payload["allowed_mentions"]["parse"])
                if kind != "pr-merged":
                    self.assertIn("<@222222222222222222>", payload["content"])
                    self.assertNotIn("<@111111111111111111>", payload["content"])
        fallback = self.run_message("review-requested", PR_REVIEWERS="")
        self.assertIn("<@222222222222222222>", fallback["content"])
        self.assertNotIn("<@111111111111111111>", fallback["content"])

    def test_approve_and_changes_requested_mention_author(self):
        for state in ("approved", "changes_requested"):
            payload = self.run_message("review", REVIEW_STATE=state)
            self.assertIn("<@111111111111111111>", payload["content"])
            self.assertEqual(["111111111111111111"], payload["allowed_mentions"]["users"])

    def test_status_keeps_ui_and_api_progress_separate(self):
        ready = {"state":"ready","percent":6.7,"remaining_percent":93.3}
        data = {"progress":{"ui":{"android":ready,"ios":ready},
                            "api":{"android":{"state":"preparing"},"ios":{"state":"preparing"}}}}
        notification = {"kind":"merge","pr_number":100,"title":"UI example","scope":"Debug UI only",
                        "url":"https://github.com/tail-friends/tail-app/pull/100", "figma_numbers":["04"],"api_work_ids":[]}
        payload = self.run_message("project-status", STATUS_DATA_JSON=json.dumps(data),
                                  STATUS_NOTIFICATION_JSON=json.dumps(notification),
                                  STATUS_PAGE_URL="https://tail-friends.github.io/tail-app/")
        fields = {f["name"]:f["value"] for f in payload["embeds"][0]["fields"]}
        self.assertIn("6.7%", fields["Android UI"])
        self.assertIn("93.3%", fields["Android UI"])
        self.assertEqual("집계 준비 중", fields["Android API"])
        self.assertEqual("집계 준비 중", fields["iOS API"])
        self.assertIn("https://tail-friends.github.io/tail-app/",fields["전체 현황표"])


if __name__ == "__main__":
    unittest.main()
