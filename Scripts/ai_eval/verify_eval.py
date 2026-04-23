#!/usr/bin/env python3
"""
Verify every canonical Q&A against the authoritative Vim manual AND
the kindaVim support corpus, on multiple quality axes, using OpenAI.

Follows the efficiency playbook in docs/llm-api-efficiency.md:
- Stable system prompt so prompt caching kicks in (Vim manual +
  support corpus + format rules never change per call).
- Batches 8 Q&As per call → ~25 calls for 200 Q&As.
- Local content-hash cache under .cache/verify_eval/ so re-runs skip
  already-verified entries.
- Uses gpt-5.4 (full tier) — this is a VALIDATION pass, not
  screening. We're about to trust these verdicts as ground-truth
  for a 200-Q&A canonical corpus. Subtle Vim semantics (dw vs de,
  text-object nuance, register model) justify the strongest model
  we can point at the task. With caching the cost delta is a few
  dollars for the whole run.

Usage:
    export OPENAI_API_KEY=sk-...
    python3 Scripts/ai_eval/verify_eval.py              # full corpus
    python3 Scripts/ai_eval/verify_eval.py delete-word  # one topic

Outputs:
- Per-Q&A verdicts → .cache/verify_eval/<topic>/<hash>.json
- Aggregated report → docs/eval-reports/<YYYY-MM-DD>.md (committed)
- Exit 0 if every load-bearing axis is pass/warning, 1 otherwise.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
import time
from dataclasses import dataclass
from datetime import date, datetime
from pathlib import Path

# Stdout needs to be unbuffered when piped (e.g. through Claude's
# bash tool) — otherwise progress lines don't appear until the
# buffer fills or the process exits. Reconfigure line-buffering on
# startup and back it up with flush=True on every print.
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(line_buffering=True)


def log(msg: str) -> None:
    """Timestamped, always-flushed progress line."""
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}", flush=True)

REPO_ROOT = Path(__file__).resolve().parents[2]
HELP_DIR = REPO_ROOT / "Sources/KindaVimTutor/Resources/kindavim-help"
VIM_REF_DIR = REPO_ROOT / "Sources/KindaVimTutor/Resources/vim-reference"
SUPPORT_FILE = REPO_ROOT / "Sources/KindaVimTutor/Resources/kindavim-support.txt"
CACHE_DIR = REPO_ROOT / ".cache/verify_eval"
REPORT_DIR = REPO_ROOT / "docs/eval-reports"

LOAD_BEARING_AXES = {
    "vim_accuracy",
    "kindavim_accuracy",
    "terminalvim_accuracy",
    "unsupported_consistency",
}

ALL_AXES = [
    "vim_accuracy",
    "kindavim_accuracy",
    "terminalvim_accuracy",
    "unsupported_consistency",
    "token_conventions",
    "verb_choice",
    "related_quality",
    "xref_validity",
    "conciseness",
]


@dataclass
class QAItem:
    topic_id: str
    topic_title: str
    topic_status: str
    question: str
    answer: str
    unsupported: bool
    terminal_vim: str | None
    related: str | None
    faster: str | None

    def cache_key(self) -> str:
        payload = json.dumps(
            {
                "t": self.topic_id,
                "q": self.question,
                "a": self.answer,
                "u": self.unsupported,
                "tv": self.terminal_vim,
                "r": self.related,
                "f": self.faster,
            },
            sort_keys=True,
        ).encode("utf-8")
        return hashlib.sha256(payload).hexdigest()[:16]


def load_vim_reference() -> str:
    parts = []
    for name in ("motion", "change", "index"):
        path = VIM_REF_DIR / f"{name}.txt"
        if path.exists():
            parts.append(f"## {name}.txt\n\n{path.read_text()}\n")
    return "\n".join(parts)


def load_support_corpus() -> str:
    return SUPPORT_FILE.read_text() if SUPPORT_FILE.exists() else ""


def load_topics(topic_filter: str | None) -> list[QAItem]:
    items: list[QAItem] = []
    for path in sorted(HELP_DIR.glob("*.txt")):
        topic_id = path.stem
        if topic_filter and topic_id != topic_filter:
            continue
        text = path.read_text()
        meta = parse_metadata(text)
        status = meta.get("status", "supported").strip()
        title = meta.get("title", topic_id).strip()
        for qa in extract_qa(text):
            items.append(QAItem(
                topic_id=topic_id,
                topic_title=title,
                topic_status=status,
                question=qa["question"],
                answer=qa["answer"],
                unsupported=qa.get("unsupported", False),
                terminal_vim=qa.get("terminal_vim"),
                related=qa.get("related"),
                faster=qa.get("faster"),
            ))
    return items


def parse_metadata(text: str) -> dict:
    meta = {}
    for line in text.splitlines():
        if not line.strip():
            break
        m = re.match(r"([a-z_][a-z_0-9]*)\s*:\s*(.*)$", line, re.IGNORECASE)
        if m:
            meta[m.group(1).lower()] = m.group(2)
    return meta


def extract_qa(text: str) -> list[dict]:
    match = re.search(
        r"##\s*Canonical\s*QA\s*\n(.+?)(?=\n##\s|\Z)",
        text, flags=re.DOTALL | re.IGNORECASE,
    )
    if not match:
        return []
    block = match.group(1)
    entries: list[dict] = []
    current: dict = {}
    active = None

    def flush():
        nonlocal current
        if current.get("question"):
            entries.append(current)
        current = {}

    for raw in block.splitlines():
        stripped = raw.strip()
        if stripped.startswith("Q:"):
            flush()
            current = {"question": stripped[2:].strip()}
            active = "question"
        elif stripped.startswith("A:"):
            current["answer"] = stripped[2:].strip()
            active = "answer"
        elif stripped.lower().startswith("related:"):
            current["related"] = stripped[len("related:"):].strip()
            active = "related"
        elif stripped.lower().startswith("faster:"):
            current["faster"] = stripped[len("faster:"):].strip()
            active = "faster"
        elif stripped.lower().startswith("unsupported:"):
            val = stripped[len("unsupported:"):].strip().lower()
            current["unsupported"] = val in ("yes", "true", "1")
            active = None
        elif stripped.lower().startswith("terminalvim:"):
            current["terminal_vim"] = stripped[len("terminalvim:"):].strip()
            active = "terminal_vim"
        elif stripped and active in ("answer", "terminal_vim", "related", "faster"):
            current[active] = (current.get(active, "") + " " + stripped).strip()
    flush()
    return entries


SYSTEM_PROMPT_TEMPLATE = """\
You are a strict fact-checker reviewing canonical Q&A entries for a
kindaVim tutor app. Each Q&A is one of two shapes:

- **Supported** (`isUnsupported: false`): the answer describes a
  command kindaVim implements. It should accurately describe BOTH
  stock Vim behavior (per the Vim reference) AND kindaVim's specific
  behavior (per the kindaVim support list).

- **Unsupported** (`isUnsupported: true`): the answer must state
  that kindaVim doesn't support the feature. The separate
  `terminalVim` field must accurately describe how stock Vim does it.

Format conventions the author follows:
- Keys wrapped in backticks: `dw`, `Esc`, `ci"`.
- Modes in double-braces: {{normal}}, {{insert}}, {{visual}}.
- "Press" for a single keypress, "Type" for multi-char sequences.
- Answers 1-3 sentences per item.

Evaluate each Q&A on these axes, returning one of `pass`, `warning`,
or `fail` per axis (use `n/a` where noted):

1. vim_accuracy: every factual claim about stock Vim matches the
   Vim reference below.
2. kindavim_accuracy: supported answers match the support corpus;
   unsupported answers correctly state non-support.
3. terminalvim_accuracy: ONLY when isUnsupported=true — the
   terminalVim field accurately describes stock Vim. Return "n/a"
   for supported entries.
4. unsupported_consistency: the isUnsupported flag aligns with what
   the answer actually claims.
5. token_conventions: keys backtick-wrapped and modes double-braced.
6. verb_choice: "Press" only for single-key, "Type" for multi-char.
7. related_quality: Related commands don't duplicate commands in
   the answer and summaries are accurate.
8. xref_validity: every command in Related actually appears in the
   support corpus (either supported or unsupported).
9. conciseness: 1-3 sentences (warning for 4-5, fail for 6+).

---

# Vim reference (authoritative)

{vim_reference}

---

# kindaVim support corpus (authoritative)

{support_corpus}
"""


def build_batch_user_message(items: list[QAItem]) -> str:
    payload = {
        "items": [
            {
                "id": i,
                "topic_id": qa.topic_id,
                "topic_status": qa.topic_status,
                "question": qa.question,
                "answer": qa.answer,
                "isUnsupported": qa.unsupported,
                "terminalVim": qa.terminal_vim,
                "related": qa.related,
            }
            for i, qa in enumerate(items)
        ],
        "instructions": (
            "Return JSON: {\"verdicts\": [...]} with one object per item "
            "containing keys: id (int, matches input), "
            + ", ".join(f"{axis} (pass|warning|fail|n/a)" for axis in ALL_AXES)
            + ", issues (array of short strings), notes (one sentence). "
            "Be strict — flagging a supported command as unsupported (or "
            "vice-versa) is a fail on kindavim_accuracy."
        ),
    }
    return json.dumps(payload, ensure_ascii=False)


def verify_batch(client, model: str, items: list[QAItem], system_prompt: str) -> list[dict]:
    start = time.monotonic()
    log(f"  → calling {model} ({len(items)} items)...")
    response = client.chat.completions.create(
        model=model,
        response_format={"type": "json_object"},
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": build_batch_user_message(items)},
        ],
    )
    elapsed = time.monotonic() - start
    content = response.choices[0].message.content or "{}"
    usage = response.usage
    cached = getattr(
        getattr(usage, "prompt_tokens_details", None),
        "cached_tokens",
        0,
    )
    log(f"  ← {elapsed:.1f}s | prompt={usage.prompt_tokens} "
        f"cached={cached} output={usage.completion_tokens}")
    try:
        parsed = json.loads(content)
    except json.JSONDecodeError:
        log(f"  WARNING: response not valid JSON: {content[:200]}")
        return [{"error": "invalid JSON response"} for _ in items]
    verdicts = parsed.get("verdicts", [])
    by_id = {v.get("id"): v for v in verdicts if isinstance(v, dict)}
    # Quick per-item summary so progress is visible at sub-batch granularity.
    pass_count = sum(
        1 for v in verdicts
        if isinstance(v, dict)
        and not any(str(v.get(ax, "")).lower() in ("fail", "warning")
                    for ax in LOAD_BEARING_AXES)
    )
    flagged = len(verdicts) - pass_count
    log(f"    verdicts: {pass_count} clean, {flagged} flagged")
    results = []
    for i, qa in enumerate(items):
        v = dict(by_id.get(i) or {"error": "no verdict returned"})
        v["_question"] = qa.question
        v["_topic_id"] = qa.topic_id
        results.append(v)
    return results


def cached_result(qa: QAItem) -> dict | None:
    path = CACHE_DIR / qa.topic_id / f"{qa.cache_key()}.json"
    if not path.exists():
        return None
    try:
        return json.loads(path.read_text())
    except json.JSONDecodeError:
        return None


def save_result(qa: QAItem, result: dict) -> None:
    topic_dir = CACHE_DIR / qa.topic_id
    topic_dir.mkdir(parents=True, exist_ok=True)
    (topic_dir / f"{qa.cache_key()}.json").write_text(
        json.dumps(result, indent=2, ensure_ascii=False)
    )


def write_partial_report(items: list[QAItem], fresh: list[dict],
                         cached: list[tuple[QAItem, dict]], total_processed: int) -> None:
    """Drops a running report to disk while the run is in progress.
    Lets the user see partial results if they interrupt the script.
    """
    to_verify_items = [qa for qa in items if all(qa.cache_key() != c[0].cache_key() for c in cached)]
    fresh_by = {qa.cache_key(): r for qa, r in zip(to_verify_items, fresh)}
    cached_by = {qa.cache_key(): r for qa, r in cached}
    partial_items = []
    partial_results = []
    for qa in items:
        r = fresh_by.get(qa.cache_key()) or cached_by.get(qa.cache_key())
        if r is not None:
            partial_items.append(qa)
            partial_results.append(r)
    if not partial_items:
        return
    report_md, _ = render_report(partial_items, partial_results)
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    today = date.today().isoformat()
    (REPORT_DIR / f"{today}-partial.md").write_text(
        f"_Partial report — {total_processed}/{len(items)} processed._\n\n" + report_md
    )


def render_report(items: list[QAItem], results: list[dict]) -> tuple[str, dict]:
    axis_counts = {
        axis: {"pass": 0, "warning": 0, "fail": 0, "n/a": 0, "other": 0}
        for axis in ALL_AXES
    }
    per_topic: dict[str, dict] = {}
    flagged: list[dict] = []

    for qa, result in zip(items, results):
        topic = per_topic.setdefault(
            qa.topic_id,
            {"title": qa.topic_title, "status": qa.topic_status,
             "total": 0, "flagged": 0, "entries": []},
        )
        topic["total"] += 1
        summary = {}
        has_issue = False
        for axis in ALL_AXES:
            v = str(result.get(axis, "other")).lower()
            if v not in axis_counts[axis]:
                v = "other"
            axis_counts[axis][v] += 1
            summary[axis] = v
            if v in ("warning", "fail"):
                has_issue = True
        if has_issue:
            topic["flagged"] += 1
            flagged.append({
                "topic_id": qa.topic_id,
                "question": qa.question,
                "verdicts": summary,
                "issues": result.get("issues", []),
                "notes": result.get("notes", ""),
            })
        topic["entries"].append({
            "question": qa.question,
            "verdicts": summary,
            "issues": result.get("issues", []),
        })

    lines = [f"# Canonical Q&A eval — {date.today().isoformat()}", ""]
    lines.append(f"**Total Q&As:** {len(items)}")
    lines.append(f"**Flagged (any warning or fail):** {len(flagged)}")
    lines.append("")
    lines.append("## Axis summary")
    lines.append("")
    lines.append("| Axis | pass | warning | fail | n/a |")
    lines.append("|---|---:|---:|---:|---:|")
    for axis in ALL_AXES:
        c = axis_counts[axis]
        lines.append(f"| {axis} | {c['pass']} | {c['warning']} | {c['fail']} | {c['n/a']} |")
    lines.append("")
    lines.append("## Flagged entries")
    lines.append("")
    if not flagged:
        lines.append("_None._")
    for entry in flagged:
        lines.append(f"### `{entry['topic_id']}` — {entry['question']}")
        lines.append("")
        for issue in entry["issues"]:
            lines.append(f"- {issue}")
        if entry["issues"]:
            lines.append("")
        fails = [ax for ax, v in entry["verdicts"].items() if v == "fail"]
        warns = [ax for ax, v in entry["verdicts"].items() if v == "warning"]
        if fails:
            lines.append(f"**Failing:** {', '.join(fails)}")
        if warns:
            lines.append(f"**Warning:** {', '.join(warns)}")
        if entry["notes"]:
            lines.append(f"_{entry['notes']}_")
        lines.append("")

    lines.append("## Per-topic flagged counts")
    lines.append("")
    for topic_id in sorted(per_topic):
        t = per_topic[topic_id]
        lines.append(f"- `{topic_id}` ({t['status']}): {t['flagged']}/{t['total']} flagged")

    return "\n".join(lines), {
        "date": date.today().isoformat(),
        "total": len(items),
        "flagged": len(flagged),
        "axis_counts": axis_counts,
        "per_topic": per_topic,
        "flagged_entries": flagged,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("topic_id", nargs="?", default=None)
    parser.add_argument("--model", default="gpt-5.4")
    parser.add_argument("--batch-size", type=int, default=8)
    parser.add_argument("--no-cache", action="store_true")
    args = parser.parse_args()

    try:
        from openai import OpenAI  # type: ignore
    except ImportError:
        sys.exit("pip install openai")

    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        sys.exit("OPENAI_API_KEY env var is required")

    items = load_topics(args.topic_id)
    if not items:
        sys.exit("No canonical Q&As found.")
    log(f"Loaded {len(items)} Q&As across "
        f"{len({i.topic_id for i in items})} topics.")
    log(f"Model: {args.model} | batch size: {args.batch_size}")

    system_prompt = SYSTEM_PROMPT_TEMPLATE.format(
        vim_reference=load_vim_reference(),
        support_corpus=load_support_corpus(),
    )

    cached: list[tuple[QAItem, dict]] = []
    to_verify: list[QAItem] = []
    if args.no_cache:
        to_verify = list(items)
    else:
        for qa in items:
            prior = cached_result(qa)
            if prior:
                cached.append((qa, prior))
            else:
                to_verify.append(qa)
    log(f"{len(cached)} cached, {len(to_verify)} need verification.")

    client = OpenAI(api_key=api_key)
    total_batches = (len(to_verify) + args.batch_size - 1) // args.batch_size
    run_start = time.monotonic()
    fresh: list[dict] = []
    for start in range(0, len(to_verify), args.batch_size):
        batch = to_verify[start:start + args.batch_size]
        n = start // args.batch_size + 1
        elapsed = time.monotonic() - run_start
        if n > 1:
            avg = elapsed / (n - 1)
            remaining = avg * (total_batches - n + 1)
            eta = f" | elapsed {elapsed:.0f}s | ~{remaining:.0f}s remaining"
        else:
            eta = ""
        log(f"Batch {n}/{total_batches} ({len(batch)} items){eta}")
        results = verify_batch(client, args.model, batch, system_prompt)
        # Persist each result immediately so interrupts preserve
        # work done so far — next run will pick these up from cache.
        for qa, r in zip(batch, results):
            save_result(qa, r)
        fresh.extend(results)

        # Drop a partial report to disk every 5 batches so
        # progress is visible even on interrupt.
        if n % 5 == 0 or n == total_batches:
            write_partial_report(items, fresh, cached, total_processed=start + len(batch))

    fresh_by = {qa.cache_key(): r for qa, r in zip(to_verify, fresh)}
    cached_by = {qa.cache_key(): r for qa, r in cached}
    ordered = [fresh_by.get(qa.cache_key()) or cached_by.get(qa.cache_key()) or {}
               for qa in items]

    report_md, report_json = render_report(items, ordered)
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    today = date.today().isoformat()
    (REPORT_DIR / f"{today}.md").write_text(report_md)
    (REPORT_DIR / f"{today}.json").write_text(
        json.dumps(report_json, indent=2, ensure_ascii=False)
    )
    log(f"Report: {REPORT_DIR / f'{today}.md'}")

    any_fail = any(
        str(r.get(axis, "")).lower() == "fail"
        for r in ordered
        for axis in LOAD_BEARING_AXES
    )
    return 1 if any_fail else 0


if __name__ == "__main__":
    sys.exit(main())
