# AI eval / authoring pipeline

Two-stage offline pipeline for authoring canonical Q&A that ships
alongside help topics. Runtime chat retrieves these instead of
invoking the on-device 3B model for common questions.

## Why two models

Claude (Anthropic) drafts the Q&A. OpenAI independently verifies each
answer against the authoritative Vim reference. Disagreements between
the two smart models surface before a human reviewer, catching
per-model bias that either one might let through alone.

## Workflow

1. **Generate** — Claude drafts Q&A pairs grounded in the topic file +
   `motion.txt` / `change.txt` / `index.txt`.

       export ANTHROPIC_API_KEY=sk-ant-…
       python3 generate_eval.py delete-word > /tmp/delete-word-qa.txt

2. **Review & paste** — Open the output, paste into the topic file
   under a `## Canonical QA` section.

3. **Verify** — OpenAI cross-checks each entry against the Vim
   reference. Prints per-entry verdicts and exits non-zero if any
   entry is flagged.

       export OPENAI_API_KEY=sk-…
       python3 verify_eval.py delete-word

4. **Human review** — A person reads flagged entries, edits anything
   the verifier caught, re-runs the verifier until clean.

5. **Commit** — Ship the updated `.txt` file. Runtime chat picks it
   up via `KindaVimHelpCorpus` + `CanonicalAnswerLookup`.

## Dependencies

    pip install anthropic openai

## Token efficiency

Before adding new bulk-LLM scripts here — or anywhere else in this
repo — read [`docs/llm-api-efficiency.md`](../../docs/llm-api-efficiency.md).
The baseline mistake is sending the same reference material on every
call; at 200 items that's $10+ wasted. The playbook (stable cacheable
prefix + batched requests + local content-hash cache + mini model
tier) cuts a full verification run to ~$0.20.

## File layout

- `generate_eval.py`: Claude-powered Q&A drafter.
- `verify_eval.py`: OpenAI-powered fact-check pass.
- Runtime loader: `Sources/KindaVimTutor/Help/KindaVimHelpCorpus.swift`
  parses the `## Canonical QA` section into `[CanonicalQA]`.
- Runtime retrieval: `Sources/KindaVimTutor/AI/CanonicalAnswerLookup.swift`.

## What counts as a match at runtime

Token-overlap Jaccard against canonical questions, threshold 0.55.
Current-topic matches get a +0.08 nudge so a user viewing a specific
manual page gets preferred answers for ambiguous phrasing.
Matches below threshold fall through to the on-device model.

## Adding a new topic

1. Author the topic `.txt` with title / tags / sections.
2. Run `generate_eval.py <topic-id>` to draft Q&A.
3. Paste into the topic file under `## Canonical QA`.
4. Run `verify_eval.py <topic-id>` and address any flags.
5. Commit.
