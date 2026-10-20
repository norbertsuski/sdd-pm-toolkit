#!/usr/bin/env python3
"""Monte Carlo throughput forecast for a project in a context root (stdlib only, Python 3.9+).

Reads finished changes from ``<context-root>/archive/*/change.md`` and the unfinished
items of ``<context-root>/foundation/<project>/roadmap.md``, simulates weekly
throughput by resampling the weeks that really happened, and prints JSON with the
p50 / p85 / p95 week counts, the matching dates and a deadline-risk flag.

It only reads. It never writes any file; the skill writes ``forecast.md``.

    python3 forecast.py --context-root <path> --project <slug> \
        [--today YYYY-MM-DD] [--runs N] [--seed N]
"""
from __future__ import annotations

import argparse
import json
import math
import random
import re
import sys
from datetime import date, timedelta
from pathlib import Path
from typing import NamedTuple

MAX_WEEKS = 520  # simulation cap: ten years
MIN_COMPLETIONS = 3
MIN_WEEKS = 3
PERCENTILES = (50, 85, 95)

_KEY_LINE = re.compile(r"^([A-Za-z0-9_-]+):[ \t]*(.*)$")
_DEADLINE = re.compile(r"^[^#\n]*?\bhard_deadline:\s*[\"']?(\d{4}-\d{2}-\d{2})", re.MULTILINE)


class Completed(NamedTuple):
    change_id: str
    archived_at: date


# --------------------------------------------------------------------------- reading


def _read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8-sig")
    except (OSError, UnicodeDecodeError):
        return ""


def _frontmatter_lines(text: str) -> list[str]:
    """Lines between the first two ``---`` markers; the first line must be a marker."""
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return []
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            return lines[1:i]
    return []


def _unquote(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        return value[1:-1]
    return value


def read_frontmatter(path: Path) -> dict[str, str]:
    """Flat ``key: value`` lines (no indentation) between the first two ``---`` lines."""
    result: dict[str, str] = {}
    for line in _frontmatter_lines(_read_text(path)):
        match = _KEY_LINE.match(line)
        if match:
            result[match.group(1)] = _unquote(match.group(2))
    return result


def read_hard_deadline(prd: Path) -> date | None:
    """``hard_deadline: YYYY-MM-DD`` inside the PRD frontmatter (inline or nested), else None."""
    block = "\n".join(_frontmatter_lines(_read_text(prd)))
    match = _DEADLINE.search(block)
    if not match:
        return None
    return _parse_iso_date(match.group(1))


def _parse_iso_date(value: str | None) -> date | None:
    """First 10 characters as YYYY-MM-DD (the archive step writes ISO datetimes); None if absent or invalid."""
    if not value:
        return None
    head = value.strip()[:10]
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", head):
        return None
    try:
        return date.fromisoformat(head)
    except ValueError:
        return None


def load_history_with_skipped(context_root: Path) -> tuple[list[Completed], int]:
    """Completed changes from ``archive/*/change.md`` plus the count of entries skipped.

    An entry is skipped when its ``archived_at`` is null, empty, absent or not a date,
    or when the folder has no readable ``change.md``. Nothing here raises.
    """
    history: list[Completed] = []
    skipped = 0
    archive = context_root / "archive"
    if not archive.is_dir():
        return history, skipped
    for folder in sorted(p for p in archive.iterdir() if p.is_dir()):
        change_md = folder / "change.md"
        archived = _parse_iso_date(read_frontmatter(change_md).get("archived_at")) if change_md.is_file() else None
        if archived is None:
            skipped += 1
            continue
        change_id = read_frontmatter(change_md).get("change_id") or folder.name
        history.append(Completed(change_id, archived))
    return history, skipped


def load_history(context_root: Path) -> list[Completed]:
    return load_history_with_skipped(context_root)[0]


def _split_row(line: str) -> list[str]:
    cells = re.split(r"(?<!\\)\|", line.strip())
    if cells and cells[0].strip() == "":
        cells = cells[1:]
    if cells and cells[-1].strip() == "":
        cells = cells[:-1]
    return [c.strip() for c in cells]


def remaining_items(roadmap: Path) -> list[str]:
    """Change IDs in the ``## At a glance`` table whose Status is not ``done``.

    Columns are found by header name (``Change ID``, ``Status``), not by position.
    Blocked and proposed items count as remaining. Raises ValueError if the section,
    the table or either column is missing.
    """
    text = _read_text(roadmap)
    section: list[str] = []
    in_section = False
    for line in text.splitlines():
        if line.strip() == "## At a glance":
            in_section = True
            continue
        if in_section and line.startswith("## "):
            break
        if in_section:
            section.append(line)
    if not in_section:
        raise ValueError(f"{roadmap}: no '## At a glance' section")
    rows = [_split_row(line) for line in section if line.lstrip().startswith("|")]
    if not rows:
        raise ValueError(f"{roadmap}: '## At a glance' has no table")
    header = [h.lower() for h in rows[0]]
    try:
        id_col, status_col = header.index("change id"), header.index("status")
    except ValueError:
        raise ValueError(f"{roadmap}: table needs 'Change ID' and 'Status' columns (found: {', '.join(rows[0])})") from None
    items: list[str] = []
    for cells in rows[1:]:
        if all(re.fullmatch(r":?-{2,}:?", c) for c in cells if c):
            continue  # separator row
        if len(cells) <= max(id_col, status_col):
            continue
        status = cells[status_col].strip("` ").lower()
        change_id = cells[id_col].strip("` ")
        if change_id and status != "done":
            items.append(change_id)
    return items


# ------------------------------------------------------------------------ simulation


def _monday(d: date) -> date:
    return d - timedelta(days=d.weekday())


def weekly_throughput(history: list[Completed], today: date, window_weeks: int = 12) -> list[int]:
    """Completions per ISO week (Mon-Sun), zero weeks included, oldest first.

    Runs from the week of the earliest completion (or ``window_weeks`` weeks before
    today's week, whichever is later) through the last complete week before today's week.
    """
    this_week = _monday(today)
    last = this_week - timedelta(weeks=1)
    if not history:
        return []
    first = max(_monday(min(c.archived_at for c in history)), this_week - timedelta(weeks=window_weeks))
    if first > last:
        return []
    counts = [0] * ((last - first).days // 7 + 1)
    for c in history:
        week = _monday(c.archived_at)
        if first <= week <= last:
            counts[(week - first).days // 7] += 1
    return counts


def simulate(throughput: list[int], remaining: int, runs: int, seed: int) -> list[int]:
    """Weeks needed to finish ``remaining`` items, per run (resampling past weeks)."""
    if not throughput:
        raise ValueError("throughput must not be empty")
    rng = random.Random(seed)
    results: list[int] = []
    for _ in range(runs):
        done = weeks = 0
        while done < remaining and weeks < MAX_WEEKS:
            done += rng.choice(throughput)
            weeks += 1
        results.append(weeks)
    return results


def percentile(samples: list[int], p: int) -> int:
    """Nearest rank: sorted samples, index ceil(p/100 * n) - 1."""
    ordered = sorted(samples)
    rank = max(1, -(-p * len(ordered) // 100))  # integer ceil, no float error
    return ordered[min(rank, len(ordered)) - 1]


# ---------------------------------------------------------------------------- forecast


def forecast(context_root: Path, project: str, today: date, runs: int = 2000, seed: int = 42) -> dict:
    project_dir = context_root / "foundation" / project
    remaining_ids = remaining_items(project_dir / "roadmap.md")
    history, skipped = load_history_with_skipped(context_root)
    throughput = weekly_throughput(history, today)
    deadline = read_hard_deadline(project_dir / "prd.md")

    problems = []
    if len(history) < MIN_COMPLETIONS:
        problems.append(f"{len(history)} finished changes with an archive date (need at least {MIN_COMPLETIONS})")
    if len(throughput) < MIN_WEEKS:
        problems.append(f"{len(throughput)} complete weeks of history (need at least {MIN_WEEKS})")
    elif sum(throughput) == 0:
        problems.append("no finished change in the last complete weeks")

    result: dict = {
        "project": project,
        "today": today.isoformat(),
        "runs": runs,
        "seed": seed,
        "completions": len(history),
        "skipped": skipped,
        "remaining": len(remaining_ids),
        "remaining_ids": remaining_ids,
        "throughput": throughput,
        "throughput_from": (_monday(today) - timedelta(weeks=len(throughput))).isoformat() if throughput else None,
        "throughput_to": (_monday(today) - timedelta(days=1)).isoformat() if throughput else None,
        "hard_deadline": deadline.isoformat() if deadline else None,
    }
    if problems:
        result.update(status="insufficient-history", reason="; ".join(problems),
                      weeks=None, dates=None, deadline_risk="none")
        return result

    samples = simulate(throughput, len(remaining_ids), runs, seed)
    weeks = {f"p{p}": percentile(samples, p) for p in PERCENTILES}
    dates = {k: today + timedelta(days=7 * w) for k, w in weeks.items()}
    if deadline is None:
        risk = "none"
    elif dates["p50"] > deadline:
        risk = "p50-after-deadline"
    elif dates["p85"] > deadline:
        risk = "p85-after-deadline"
    else:
        risk = "none"
    result.update(status="ok", reason=None, weeks=weeks,
                  dates={k: d.isoformat() for k, d in dates.items()}, deadline_risk=risk)
    return result


# --------------------------------------------------------------------------------- CLI


def _iso_date(value: str) -> date:
    try:
        return date.fromisoformat(value)
    except ValueError:
        raise argparse.ArgumentTypeError(f"not a YYYY-MM-DD date: {value!r}") from None


def _positive_int(value: str) -> int:
    n = int(value)
    if n < 1:
        raise argparse.ArgumentTypeError("must be at least 1")
    return n


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Monte Carlo throughput forecast (read-only, prints JSON).")
    parser.add_argument("--context-root", required=True, type=Path)
    parser.add_argument("--project", required=True)
    parser.add_argument("--today", type=_iso_date, default=None, help="YYYY-MM-DD (default: today)")
    parser.add_argument("--runs", type=_positive_int, default=2000)
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args(argv)
    roadmap = args.context_root / "foundation" / args.project / "roadmap.md"
    if not roadmap.is_file():
        print(f"error: {roadmap} not found (roadmap.md is required)", file=sys.stderr)
        return 2
    try:
        result = forecast(args.context_root, args.project, args.today or date.today(), args.runs, args.seed)
    except ValueError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
