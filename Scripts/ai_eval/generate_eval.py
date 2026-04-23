#!/usr/bin/env python3
"""
Generate canonical Q&A pairs for a kindaVim help topic.

Reads a topic file from Sources/KindaVimTutor/Resources/kindavim-help/,
asks Anthropic's Claude to produce ~5 high-quality Q&A pairs grounded
in the topic content and the bundled Vim reference, prints the
resulting block in the canonical .txt format ready to paste.

A second pass (verify_eval.py) cross-checks each generated answer
against the Vim reference using OpenAI and flags hallucinations
before human review.

Usage:
    ANTHROPIC_API_KEY=... python3 generate_eval.py delete-word

Environment:
    ANTHROPIC_API_KEY: required

Output: prints `## Canonical QA\n...` block to stdout. Redirect to
a file, then diff against the existing topic file and paste the
verified entries into place.
"""

from __future__ import annotations

import argparse
import os
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


def build_prompt(topic_text: str, vim_ref: str) -> str:
    return dedent(f"""
        You are authoring canonical Q&A pairs for a kindaVim tutor
        app. Generate 4–6 question/answer pairs a real user would
        plausibly ask about this topic. Answers must be concrete and
        grounded strictly in the Vim reference below — do not invent
        flags, commands, or behaviors.

        ## Format rules
        Use these tokens so the host app can style output:
        - `backtick-wrap` keys: `dw`, `3dw`, `Esc`.
        - `{{{{normal}}}}`, `{{{{insert}}}}`, `{{{{visual}}}}` for Vim modes.

        Verb choice:
        - "Press" for a single keypress.
        - "Type" for multi-character sequences.

        Comparison questions MUST define each term before stating the
        difference. Related-command lists MUST exclude the command
        taught in the answer itself.

        ## Output format
        Emit exactly this format for each pair, separated by a blank line:

            Q: <question>
            A: <1–3 sentence answer using the token conventions>
            Related: cmd1 — short summary; cmd2 — short summary
            Faster: <optional, 1 sentence with a genuinely faster approach; omit the line if none>

        ## Topic under review
        {topic_text}

        ## Vim reference (authoritative)
        {vim_ref}
        """).strip()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("topic_id", help="Topic file stem, e.g. 'delete-word'")
    parser.add_argument("--model", default="claude-sonnet-4-6",
                        help="Anthropic model id (default: claude-sonnet-4-6)")
    args = parser.parse_args()

    try:
        import anthropic  # type: ignore
    except ImportError:
        sys.exit("pip install anthropic")

    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        sys.exit("ANTHROPIC_API_KEY env var is required")

    topic_text = load_topic(args.topic_id)
    vim_ref = load_vim_reference()
    prompt = build_prompt(topic_text, vim_ref)

    client = anthropic.Anthropic(api_key=api_key)
    response = client.messages.create(
        model=args.model,
        max_tokens=2000,
        messages=[{"role": "user", "content": prompt}],
    )
    out = "\n".join(block.text for block in response.content if block.type == "text")

    print("## Canonical QA")
    print()
    print(out.strip())
    return 0


if __name__ == "__main__":
    sys.exit(main())
