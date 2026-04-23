# LLM API efficiency — Anthropic & OpenAI

A checklist for any script in this repo that makes bulk LLM calls.
The baseline mistake is sending the same reference material on every
request — at 200 calls with a 30 KB context, that's 6 MB of redundant
input and ~$5–10 wasted. Layer the optimizations below to avoid it.

## TL;DR — default stack for bulk calls

1. **Stable system prompt** so prompt caching kicks in.
2. **Batch multiple items per call** — cuts call count and amortizes context.
3. **Local content-hash cache** — skip already-verified work on re-runs.
4. **Pick a mini model for screening** — escalate to the full model only for flagged items.
5. **Optional: Batch API** — another 50% off for non-interactive pipelines.

Stacking #1–#3 typically cuts cost 70–90% with minimal code.

## Core optimizations, ranked by ROI

### 1. Prompt caching (biggest win, almost free)

Both providers discount repeated prefixes. The rule is simple:
**move everything that doesn't change between calls into a stable
prefix, then put only the per-item variation at the end.**

**OpenAI — automatic** (as of Oct 2024)
No code change. Prefixes ≥ ~1,024 tokens are auto-cached for ~5 min
after first use. Cached tokens bill at 50% of the input rate.
- Put the reference material in the `system` message.
- Keep it byte-for-byte identical across requests — even a timestamp
  or request ID change inside the prefix defeats the cache.
- Verify via the `usage.prompt_tokens_details.cached_tokens` field in
  each response.

**Anthropic — explicit** (via `cache_control`)
Caching is opt-in. You mark specific blocks as cacheable:

```python
client.messages.create(
    model="claude-sonnet-4-6",
    system=[
        {
            "type": "text",
            "text": big_reference_text,
            "cache_control": {"type": "ephemeral"},
        },
    ],
    messages=[{"role": "user", "content": per_item_prompt}],
)
```

- Cache lives ~5 minutes.
- Minimum block size to cache: 1,024 tokens for Sonnet/Opus, 2,048
  for Haiku.
- Up to 4 `cache_control` breakpoints per request.
- Cached tokens bill at 10% of the input rate (vs OpenAI's 50%) —
  when you can use Anthropic for bulk fact-checking, it's cheaper per
  cached token.
- Verify via `usage.cache_read_input_tokens` in the response.

### 2. Batch multiple items per call

Send 5–10 items per request instead of one, asking for an array of
structured responses. Cuts call count ~10x.

Combined with caching, the context is transmitted ~20x fewer times
vs. one-call-per-item.

**Pattern (OpenAI structured output):**

```python
response = client.chat.completions.create(
    model="gpt-4.1-mini",
    response_format={"type": "json_object"},
    messages=[
        {"role": "system", "content": stable_reference_and_rules},
        {"role": "user", "content": json.dumps({
            "items": [
                {"id": 1, "question": "...", "answer": "..."},
                {"id": 2, "question": "...", "answer": "..."},
                # ...
            ],
            "instructions": "For each item, return {id, verdict, issues}.",
        })},
    ],
)
```

**Pattern (Anthropic tool-use for structured output):**

```python
tools = [{
    "name": "submit_verdicts",
    "input_schema": {
        "type": "object",
        "properties": {
            "verdicts": {
                "type": "array",
                "items": {"type": "object", "properties": {
                    "id": {"type": "integer"},
                    "verdict": {"type": "string"},
                    "issues": {"type": "array", "items": {"type": "string"}},
                }},
            },
        },
    },
}]
```

**Batch sizing:** too many items per call causes the model to drop
or mix up entries. 5–10 is a sweet spot; above 15 degrades reliably.

### 3. Local content-hash cache

For offline/idempotent work, cache results keyed on a hash of the
input. A single edit to one Q&A doesn't re-bill 199 verifications.

```python
import hashlib, json
from pathlib import Path

def cache_key(item: dict) -> str:
    return hashlib.sha256(json.dumps(item, sort_keys=True).encode()).hexdigest()[:16]

def verify(item: dict, cache_dir: Path) -> dict:
    cache_path = cache_dir / f"{cache_key(item)}.json"
    if cache_path.exists():
        return json.loads(cache_path.read_text())
    result = call_api(item)
    cache_path.write_text(json.dumps(result))
    return result
```

Put the cache under `.cache/<script-name>/` and add it to `.gitignore`.
Invalidate by deleting the cache directory.

### 4. Match model tier to task

- **Screening / first-pass triage of many items:** mini tier is
  plenty. `gpt-4.1-mini` or `claude-haiku-4-5` handle structured
  filtering well at ~5–10x less cost.
- **Validation / ground-truth / anything treated as authoritative:**
  full tier — `gpt-4.1` / `claude-sonnet-4-6` / `claude-opus-4-7`.
  If the model's verdict ships or gates a release, don't cheap out.
  Subtle domain semantics (Vim motion nuances, API behavior
  specifics) are where mini tiers drift. With caching, the full-tier
  run of 200 items is ~$1; not worth sacrificing accuracy to save
  it.
- **Generation requiring creativity, reasoning, or long context:**
  full tier.
- **Two-tier pattern:** screen cheaply, escalate `warning`/`fail`
  to the full model for confirmation. Only worth the complexity
  when the corpus is 5,000+ items.

Current rough pricing (per 1M tokens, Q2 2026):

| Model | Input | Output | Cached input |
|---|---|---|---|
| gpt-4.1-mini | $0.40 | $1.60 | $0.20 |
| gpt-4.1 | $2.00 | $8.00 | $1.00 |
| claude-haiku-4-5 | $1.00 | $5.00 | $0.10 |
| claude-sonnet-4-6 | $3.00 | $15.00 | $0.30 |
| claude-opus-4-7 | $15.00 | $75.00 | $1.50 |

Anthropic's cache discount (10%) is steeper than OpenAI's (50%),
making Claude appealing specifically for bulk work with heavy
context re-use.

### 5. Batch API (optional, async jobs)

**OpenAI `/v1/batches`** — submit jobs as JSONL, get results within
24h. 50% off baseline pricing. Stacks with caching. Good for
authoring pipelines, eval harnesses, report generation.

**Anthropic Message Batches** — same idea. Up to 100k messages per
batch. 24h turnaround. 50% off.

Use when latency doesn't matter. Skip for interactive tools.

### 6. Intelligent reference slicing (advanced)

Instead of sending the whole Vim manual, slice to sections relevant
to the current item. E.g. a question about `dw` needs the `d` operator
section + word motions — maybe 15 KB instead of 220 KB.

Only worth it when:
- The reference is huge (100 KB+).
- Relevance can be cheaply determined (keyword index, topic tags).
- Caching alone isn't enough.

Usually caching + batching gets us ~90% there without slicing.

## Anti-patterns to avoid

- **Interpolating timestamps, UUIDs, or counters inside the cached
  prefix** — defeats caching. Keep variable content OUT of the system
  message.
- **Using `gpt-4.1`/`opus` to filter thousands of mostly-fine
  items** — mini handles bulk screening. But don't invert the
  mistake: mini on high-stakes validation of a small corpus is
  penny-wise / pound-foolish. Match the tier to the consequence
  of a bad verdict.
- **Serializing items one-at-a-time when the task is idempotent** —
  batch wherever possible.
- **Skipping the local cache** — re-running a script during
  development with no cache means paying full price every iteration.
- **Putting the full Vim manual in the `user` message** — every user
  message is billed fresh. Reference material belongs in `system`.
- **Writing custom retry loops without checking `usage.cached_tokens`**
  — you can't tell if caching is working without reading that field.

## Cost math — back-of-envelope

200 Q&As, each needs fact-checking against a 30 KB reference:

- **Naive** (one-at-a-time, no cache, full model):
  `200 × 30 KB × gpt-4.1` ≈ $12
- **Cached + full model** (shared prefix):
  `1 full + 199 cached × gpt-4.1` ≈ $6
- **Cached + batched** (10/call, 20 calls):
  `1 full + 19 cached × gpt-4.1` ≈ $0.80
- **Cached + batched + mini model:**
  `1 full + 19 cached × gpt-4.1-mini` ≈ $0.20
- **Cached + batched + mini + local hash cache** (iterative edits):
  `~$0.01 per re-run`

The three cheapest tiers are 60x–1,200x under the naive baseline for
the same work.

## Checklist for your next bulk script

Before writing the first API call, answer these:

- [ ] Is there a stable reference block I can cache? → put in system message.
- [ ] Can multiple items share one call? → batch 5–10 per request.
- [ ] Is the work idempotent? → add a local content-hash cache.
- [ ] Does this need a full-size model? → default to mini tier.
- [ ] Is this an offline pipeline? → consider Batch API for 50% off.
- [ ] Am I reading `cached_tokens` / `cache_read_input_tokens` in
  the response to confirm caching is working?

If yes to all, you're at 1–5% of the naive cost with the same quality.

## References

- OpenAI prompt caching: <https://platform.openai.com/docs/guides/prompt-caching>
- OpenAI Batch API: <https://platform.openai.com/docs/guides/batch>
- Anthropic prompt caching: <https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching>
- Anthropic Message Batches: <https://docs.anthropic.com/en/docs/build-with-claude/batch-processing>
