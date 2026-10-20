"""Tests for skills/pm-forecast/scripts/forecast.py (stdlib unittest only)."""
from __future__ import annotations

import json
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCRIPT_DIR = ROOT / "skills" / "pm-forecast" / "scripts"
sys.path.insert(0, str(SCRIPT_DIR))

import forecast as fc  # noqa: E402  (path inserted above)

FIX = ROOT / "tests" / "fixtures" / "flat-root" / "context"
PROJECT = "recipe-fridge"
TODAY = date(2026, 10, 20)


class FixtureCopy:
    """Context manager: a scratch copy of the shared fixture (never edit the original)."""

    def __enter__(self) -> Path:
        self._tmp = tempfile.TemporaryDirectory()
        dest = Path(self._tmp.name) / "context"
        shutil.copytree(FIX, dest)
        return dest

    def __exit__(self, *exc) -> None:
        self._tmp.cleanup()


def set_deadline(context: Path, value: str) -> None:
    prd = context / "foundation" / PROJECT / "prd.md"
    text = prd.read_text(encoding="utf-8")
    prd.write_text(re.sub(r"hard_deadline: \d{4}-\d{2}-\d{2}", f"hard_deadline: {value}", text), encoding="utf-8")


class SpecTests(unittest.TestCase):
    def test_weekly_throughput_fixture(self):
        self.assertEqual(fc.weekly_throughput(fc.load_history(FIX), TODAY), [2, 1, 1])

    def test_remaining_fixture(self):
        roadmap = FIX / "foundation" / PROJECT / "roadmap.md"
        self.assertEqual(sorted(fc.remaining_items(roadmap)), ["meal-plan", "share-recipe", "shopping-list"])

    def test_constant_throughput_is_exact(self):
        self.assertEqual(set(fc.simulate([1, 1, 1], 3, 500, 1)), {3})

    def test_seed_reproducible(self):
        self.assertEqual(fc.simulate([0, 1, 2], 5, 200, 7), fc.simulate([0, 1, 2], 5, 200, 7))

    def test_percentile_nearest_rank(self):
        self.assertEqual(fc.percentile([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 85), 9)

    def test_insufficient_history(self):
        with FixtureCopy() as ctx:
            for folder in ("2026-10-01-recipe-match", "2026-10-06-save-favorites"):
                shutil.rmtree(ctx / "archive" / folder)
            result = fc.forecast(ctx, PROJECT, TODAY)
        self.assertEqual(result["status"], "insufficient-history")
        self.assertIsNone(result["dates"])
        self.assertIsNone(result["weeks"])
        self.assertEqual(result["deadline_risk"], "none")

    def test_deadline_risk(self):
        with FixtureCopy() as ctx:
            set_deadline(ctx, "2026-10-25")
            near = fc.forecast(ctx, PROJECT, TODAY)
            set_deadline(ctx, "2027-06-01")
            far = fc.forecast(ctx, PROJECT, TODAY)
        self.assertEqual(near["deadline_risk"], "p50-after-deadline")
        self.assertEqual(far["deadline_risk"], "none")


class ForecastResultTests(unittest.TestCase):
    def test_fixture_forecast_matches_hand_computed_distribution(self):
        # Throughput [2,1,1], 3 left: 2 weeks with p=5/9, 3 weeks with p=4/9 -> p50=2, p85=p95=3.
        result = fc.forecast(FIX, PROJECT, TODAY)
        self.assertEqual(result["status"], "ok")
        self.assertEqual(result["remaining"], 3)
        self.assertEqual(result["throughput"], [2, 1, 1])
        self.assertEqual(result["throughput_from"], "2026-09-28")  # Monday of the first counted week
        self.assertEqual(result["throughput_to"], "2026-10-18")  # Sunday before today's week
        self.assertEqual(result["weeks"], {"p50": 2, "p85": 3, "p95": 3})
        self.assertEqual(result["dates"], {"p50": "2026-11-03", "p85": "2026-11-10", "p95": "2026-11-10"})
        self.assertEqual(result["hard_deadline"], "2026-12-15")
        self.assertEqual(result["deadline_risk"], "none")
        self.assertEqual(result["skipped"], 0)

    def test_same_inputs_same_output(self):
        self.assertEqual(fc.forecast(FIX, PROJECT, TODAY), fc.forecast(FIX, PROJECT, TODAY))

    def test_p85_after_deadline(self):
        # p50 date 2026-11-03, p85 date 2026-11-10
        with FixtureCopy() as ctx:
            set_deadline(ctx, "2026-11-05")
            result = fc.forecast(ctx, PROJECT, TODAY)
        self.assertEqual(result["deadline_risk"], "p85-after-deadline")

    def test_no_prd_means_no_deadline(self):
        with FixtureCopy() as ctx:
            (ctx / "foundation" / PROJECT / "prd.md").unlink()
            result = fc.forecast(ctx, PROJECT, TODAY)
        self.assertIsNone(result["hard_deadline"])
        self.assertEqual(result["deadline_risk"], "none")

    def test_all_zero_throughput_is_insufficient(self):
        # three completions, all long before the 12-week window
        with FixtureCopy() as ctx:
            for change in ctx.glob("archive/*/change.md"):
                text = change.read_text(encoding="utf-8")
                change.write_text(re.sub(r"archived_at: 2026-\d\d-\d\d", "archived_at: 2025-01-06", text), encoding="utf-8")
            result = fc.forecast(ctx, PROJECT, TODAY)
        self.assertEqual(result["status"], "insufficient-history")
        self.assertIsNone(result["weeks"])


class HistoryTests(unittest.TestCase):
    def test_iso_datetime_uses_first_ten_chars(self):
        history = fc.load_history(FIX)
        self.assertEqual(
            sorted((c.change_id, c.archived_at) for c in history),
            [
                ("auth-scaffold", date(2026, 9, 29)),
                ("fridge-inventory", date(2026, 10, 1)),
                ("recipe-match", date(2026, 10, 8)),
                ("save-favorites", date(2026, 10, 14)),
            ],
        )

    def test_null_absent_and_unparseable_are_skipped_not_crashing(self):
        with FixtureCopy() as ctx:
            base = ctx / "archive"
            cases = {
                "x-null": "archived_at: null",
                "x-empty": "archived_at:",
                "x-absent": "status: archived",
                "x-garbage": "archived_at: not-a-date",
                "x-bad-day": "archived_at: 2026-13-45T00:00:00Z",
            }
            for name, line in cases.items():
                folder = base / f"2026-01-01-{name}"
                folder.mkdir()
                (folder / "change.md").write_text(f"---\nchange_id: {name}\n{line}\n---\n", encoding="utf-8")
            (base / "2026-01-01-no-change-file").mkdir()
            history, skipped = fc.load_history_with_skipped(ctx)
            self.assertEqual(len(history), 4)
            self.assertEqual(skipped, 6)  # five bad dates + one folder without change.md
            self.assertEqual(len(fc.load_history(ctx)), 4)
            self.assertEqual(fc.forecast(ctx, PROJECT, TODAY)["skipped"], 6)

    def test_missing_archive_dir_is_empty_history(self):
        with tempfile.TemporaryDirectory() as tmp:
            self.assertEqual(fc.load_history(Path(tmp)), [])

    def test_quoted_values_and_crlf(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp) / "archive" / "a"
            folder.mkdir(parents=True)
            (folder / "change.md").write_bytes(b'---\r\nchange_id: "a"\r\narchived_at: "2026-09-29T15:10:00Z"\r\n---\r\n')
            history = fc.load_history(Path(tmp))
        self.assertEqual(history, [fc.Completed("a", date(2026, 9, 29))])


class FrontmatterTests(unittest.TestCase):
    def test_flat_keys_only_between_first_two_markers(self):
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp) / "f.md"
            p.write_text("---\na: 1\nb: 'two'\nnested:\n  c: 3\n---\nd: 4\n---\ne: 5\n", encoding="utf-8")
            self.assertEqual(fc.read_frontmatter(p), {"a": "1", "b": "two", "nested": ""})

    def test_no_frontmatter_or_missing_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp) / "f.md"
            p.write_text("# just text\n", encoding="utf-8")
            self.assertEqual(fc.read_frontmatter(p), {})
            self.assertEqual(fc.read_frontmatter(Path(tmp) / "absent.md"), {})


class HardDeadlineTests(unittest.TestCase):
    def _prd(self, tmp: str, frontmatter: str, body: str = "") -> Path:
        p = Path(tmp) / "prd.md"
        p.write_text(f"---\n{frontmatter}---\n\n{body}", encoding="utf-8")
        return p

    def test_inline_form(self):
        self.assertEqual(fc.read_hard_deadline(FIX / "foundation" / PROJECT / "prd.md"), date(2026, 12, 15))

    def test_nested_form(self):
        with tempfile.TemporaryDirectory() as tmp:
            p = self._prd(tmp, "project: x\ntimeline_budget:\n  hard_deadline: 2027-03-31\n  note: y\n")
            self.assertEqual(fc.read_hard_deadline(p), date(2027, 3, 31))

    def test_absent_null_or_invalid_is_none(self):
        with tempfile.TemporaryDirectory() as tmp:
            for fm in ("project: x\n", "timeline_budget: { hard_deadline: null }\n",
                       "timeline_budget: { hard_deadline: 2026-13-40 }\n", "# hard_deadline: 2026-12-15\n"):
                self.assertIsNone(fc.read_hard_deadline(self._prd(tmp, fm)), fm)
            self.assertIsNone(fc.read_hard_deadline(Path(tmp) / "missing.md"))

    def test_only_frontmatter_counts(self):
        with tempfile.TemporaryDirectory() as tmp:
            p = self._prd(tmp, "project: x\n", "The hard_deadline: 2026-12-15 is mentioned in prose.\n")
            self.assertIsNone(fc.read_hard_deadline(p))


class WeeklyThroughputTests(unittest.TestCase):
    def C(self, *days):
        return [fc.Completed(f"c{i}", d) for i, d in enumerate(days)]

    def test_zero_weeks_included_and_current_week_excluded(self):
        # Mon 2026-10-19 is today's week -> not counted. Weeks: 9-28, 10-05, 10-12.
        hist = self.C(date(2026, 9, 29), date(2026, 10, 14), date(2026, 10, 20))
        self.assertEqual(fc.weekly_throughput(hist, TODAY), [1, 0, 1])

    def test_week_boundaries_monday_to_sunday(self):
        hist = self.C(date(2026, 10, 4), date(2026, 10, 5), date(2026, 10, 11), date(2026, 10, 12))
        # Sun 10-04 -> week 9-28; Mon 10-05 & Sun 10-11 -> week 10-05; Mon 10-12 -> week 10-12
        self.assertEqual(fc.weekly_throughput(hist, TODAY), [1, 2, 1])

    def test_window_cuts_old_history(self):
        hist = self.C(date(2026, 1, 5), date(2026, 10, 14))
        self.assertEqual(fc.weekly_throughput(hist, TODAY, window_weeks=2), [0, 1])
        self.assertEqual(len(fc.weekly_throughput(hist, TODAY, window_weeks=12)), 12)

    def test_empty_or_only_current_week(self):
        self.assertEqual(fc.weekly_throughput([], TODAY), [])
        self.assertEqual(fc.weekly_throughput(self.C(date(2026, 10, 19)), TODAY), [])


class RoadmapTests(unittest.TestCase):
    def test_columns_located_by_name_not_position(self):
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp) / "roadmap.md"
            p.write_text(
                "# R\n\n## At a glance\n\n"
                "| Status | Notes | Change ID | ID |\n| --- | --- | --- | --- |\n"
                "| done | x | a | F-01 |\n| `blocked` | y | b | S-01 |\n| Proposed | z \\| w | c | S-02 |\n\n"
                "## Streams\n\n| Status | Change ID |\n| --- | --- |\n| ready | not-in-glance |\n",
                encoding="utf-8",
            )
            self.assertEqual(fc.remaining_items(p), ["b", "c"])

    def test_missing_section_or_column_raises(self):
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp) / "roadmap.md"
            p.write_text("# R\n\n## Slices\n", encoding="utf-8")
            with self.assertRaises(ValueError):
                fc.remaining_items(p)
            p.write_text("## At a glance\n\n| ID | Status |\n| - | - |\n| S-01 | ready |\n", encoding="utf-8")
            with self.assertRaises(ValueError):
                fc.remaining_items(p)

    def test_blocked_items_count_as_remaining(self):
        roadmap = FIX / "foundation" / PROJECT / "roadmap.md"
        self.assertIn("share-recipe", fc.remaining_items(roadmap))


class SimulationTests(unittest.TestCase):
    def test_zero_remaining_is_zero_weeks(self):
        self.assertEqual(set(fc.simulate([1], 0, 10, 1)), {0})

    def test_cap_at_520_weeks(self):
        self.assertEqual(set(fc.simulate([0, 0, 0], 1, 5, 1)), {520})

    def test_percentile_edges(self):
        self.assertEqual(fc.percentile([5], 50), 5)
        self.assertEqual(fc.percentile([3, 1, 2], 100), 3)
        self.assertEqual(fc.percentile([3, 1, 2], 1), 1)
        self.assertEqual(fc.percentile([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 50), 5)


class CliTests(unittest.TestCase):
    def run_cli(self, *args):
        return subprocess.run(
            [sys.executable, "-W", "error", str(SCRIPT_DIR / "forecast.py"), *args],
            capture_output=True, text=True, check=False,
        )

    def test_cli_json_matches_function(self):
        proc = self.run_cli("--context-root", str(FIX), "--project", PROJECT, "--today", "2026-10-20")
        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertEqual(proc.stderr, "")
        self.assertEqual(json.loads(proc.stdout), fc.forecast(FIX, PROJECT, TODAY))

    def test_cli_same_seed_identical_output(self):
        args = ("--context-root", str(FIX), "--project", PROJECT, "--today", "2026-10-20", "--runs", "500", "--seed", "3")
        self.assertEqual(self.run_cli(*args).stdout, self.run_cli(*args).stdout)

    def test_cli_missing_roadmap_exits_nonzero(self):
        proc = self.run_cli("--context-root", str(FIX), "--project", "nope", "--today", "2026-10-20")
        self.assertEqual(proc.returncode, 2)
        self.assertIn("roadmap.md", proc.stderr)

    def test_cli_bad_today_exits_nonzero(self):
        proc = self.run_cli("--context-root", str(FIX), "--project", PROJECT, "--today", "yesterday")
        self.assertNotEqual(proc.returncode, 0)


if __name__ == "__main__":
    unittest.main()
