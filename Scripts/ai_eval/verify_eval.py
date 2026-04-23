#!/usr/bin/env python3
"""
Verify canonical Q&A pairs against the authoritative Vim reference
using OpenAI. Independent second-model check catches hallucinations
the authoring model (Claude) might have produced.

Reads a topic file that already has a `## Canonical QA` section,
pulls each Q/A pair, and asks GPT-4-class to flag any claims not
supported by the Vim reference. Prints a structured report.

Usage:
    OPENAI_API_KEY=... python3 verify_eval.py delete-word

Environment:
    OPENAI_API_KEY: required

Exit codes:
    0: all entries verified clean
    1: one or more entries flagged — review before shipping
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path
from textwrap import dedent

REPO_ROOT = Path(__file__).resolve().parents[2]
HELP_DIR = REPO_ROOT / "Sources/KindaVimTutor/Resources/kindavim-help"
VIM_REF_DIR = REPO_ROOT / "Sources/KindaVimTutor/Resources/vim-reference"


def load_vim_reference() -> str:
    parts = []
    for name in ("motion", "change", "index"):
        path = VIM_REF_DIR / f"{name}.txt"
        if path.exists():
            parts.append(f"## {name}.txt\n\n{path.read_text()}\n")
    return "\n".join(parts)


def load_topic(topic_id: str) -> str:
    path = HELP_DIR / f"{topic_id}.txt"
    if not path.exists():
        sys.exit(f"No topic file at {path}")
    return path.read_text()


def extract_qa(topic_text: str) -> list[dict]:
    """Pull Q/A pairs out of the `## Canonical QA` section."""
    match = re.search(
        r"##\s*Canonical\s*QA\s*\n(.+?)(?=\n##\s|\Z)",
        topic_text, flags=re.DOTALL | re.IGNORECASE,
    )
    if not match:
        return []
    block = match.group(1)

    entries = []
    current = {}
    for line in block.splitlines():
        stripped = line.strip()
        if stripped.startswith("Q:"):
            if current.get("question"):
                entries.append(current)
            current = {"question": stripped[2:].strip()}
        elif stripped.startswith("A:"):
            current["answer"] = stripped[2:].strip()
        elif stripped.lower().startswith("related:"):
            current["related"] = stripped[8:].strip()
        elif stripped.lower().startswith("faster:"):
            current["faster"] = stripped[7:].strip()
        elif stripped and current.get("answer") is not None:
            # Continuation of answer body
            current["answer"] = (current.get("answer", "") + " " + stripped).strip()
    if current.get("question"):
        entries.append(current)
    return entries


def verify_one(client, model: str, entry: dict, vim_ref: str) -> dict:
    prompt = dedent(f"""
        You are a strict fact-checker reviewing a kindaVim tutor answer
        against the official Vim reference. Your job is to identify
        any claim in the answer that is NOT directly supported by the
        reference, or that contradicts it.

        Respond in JSON with keys:
        - verdict: "pass" | "warning" | "fail"
        - issues: array of strings (empty if verdict=pass)
        - notes: short reasoning

        Use "pass" if every factual claim is supported.
        Use "warning" if the answer is roughly correct but imprecise.
        Use "fail" if any claim is wrong or fabricated.

        ## Answer under review
        Q: {entry['question']}
        A: {entry['answer']}

        ## Authoritative Vim reference
        {vim_ref[:80000]}
        """).strip()

    response = client.chat.completions.create(
        model=model,
        response_format={"type": "json_object"},
        messages=[{"role": "user", "content": prompt}],
    )
    content = response.choices[0].message.content
    return json.loads(content or "{}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("topic_id")
    parser.add_argument("--model", default="gpt-4.1",
                        help="OpenAI model id (default: gpt-4.1)")
    args = parser.parse_args()

    try:
        from openai import OpenAI  # type: ignore
    except ImportError:
        sys.exit("pip install openai")

    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        sys.exit("OPENAI_API_KEY env var is required")

    topic_text = load_topic(args.topic_id)
    entries = extract_qa(topic_text)
    if not entries:
        sys.exit(f"No canonical QA found in {args.topic_id}")

    vim_ref = load_vim_reference()
    client = OpenAI(api_key=api_key)

    failed = 0
    for i, entry in enumerate(entries, 1):
        print(f"\n[{i}] Q: {entry['question']}")
        result = verify_one(client, args.model, entry, vim_ref)
        verdict = result.get("verdict", "unknown")
        print(f"    verdict: {verdict}")
        if result.get("issues"):
            for issue in result["issues"]:
                print(f"      - {issue}")
        if result.get("notes"):
            print(f"    notes: {result['notes']}")
        if verdict in ("fail", "warning"):
            failed += 1

    print()
    if failed:
        print(f"Flagged {failed}/{len(entries)} entries — review before shipping.")
        return 1
    print(f"All {len(entries)} entries verified clean.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
