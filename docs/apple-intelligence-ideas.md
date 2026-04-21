# Apple Intelligence — backlog

A sketch of what the Foundation Models framework could unlock inside
kindaVim Tutor, and the constraints to design around before picking
anything up. Written as a backlog doc, not a plan — nothing here is
committed.

## What we'd get for free

Foundation Models (macOS 26 / iOS 26) ships a ~3B-parameter on-device
LLM accessible via a pure-Swift API. Relative to our current "no AI"
baseline:

- No API key, no account provisioning
- No per-token cost
- No network round-trip — inference happens on-device
- Private by default (text never leaves the machine)
- Rate-limited only by the user's hardware

The model is smaller and less capable than a frontier model. It's
good at short, focused, single-turn tasks; it's not good at long
reasoning, code generation, or open-ended multi-turn dialogue.

## Hard constraints

- **macOS 26 only.** Any feature we ship needs a non-AI code path
  for users on 25 and earlier. We can't make Apple Intelligence a
  required dependency.
- **User opt-in.** Apple Intelligence has to be turned on in
  System Settings. The framework exposes a check — we must handle
  the "not enabled" case gracefully (explain + deep-link to
  Settings, fall back to static content).
- **Hardware floor.** Apple Silicon only, and memory-bound (model
  weights live in unified memory). M1 with 8 GB is the stated
  minimum. Older Intel Macs are out.
- **Content filter.** The model refuses some prompts. Every call
  needs a fallback string.
- **Latency.** First inference is slow (model warm-up), subsequent
  calls are faster but still measured in seconds on small Macs. Not
  suitable for anything blocking a keystroke.
- **No guarantees about determinism.** Same prompt can yield
  different output. Anything user-facing should be cacheable or
  acceptable-if-varied.

## Natural fits

Ordered by "obvious win" → "interesting but speculative."

### 1. Generate Notes / Mail drill seed bodies
Instead of authoring static seed text per drill ("The DOG ran
fast\nThe CAT slept late\n…"), generate a fresh three-line seed that
matches the drill's completion predicates. Keeps drills feeling
fresh on repeat attempts and removes the risk of students memorising
targets.

Cost: one inference per drill start. Already happens against a slow
surface (Notes / Mail AppleScript round-trip), so adding ~1–2 s on
top is tolerable.

Risk: content filter trips, produces seed that doesn't actually
contain the target word, or produces profanity. Need verification
step ("does output contain required token?") with static fallback.

### 2. Per-drill feedback after completion
On the drill completion screen, generate a one-sentence personalised
coach note: "You used `hjkl` 14 times where `w` would have taken 3
keystrokes — try `w` on line 2 next time." Input: rep timings,
keystroke counts, current motion being taught. Output: plain-prose
encouragement + one specific suggestion.

Cost: one inference per drill completion (a handful of seconds on
the completion screen is fine; no one's waiting on keystrokes).

Risk: model hallucinates a suggestion that's wrong for the motion
in play. Need a tight prompt with the motion's actual vocabulary
listed.

### 3. Rephrase hints when students miss a rep repeatedly
When a student hits the same rep with insert-mode keystrokes three
times, swap the static hint for a model-generated rephrase tuned to
what they just did. "You're still typing letters into the document
— press Escape first, then `dw`."

Cost: one inference per failing rep, gated on an activity threshold
so we don't fire on every keystroke.

Risk: hint contradicts what we actually teach. Mitigation: pass the
lesson's motion vocabulary in as system prompt; refuse to apply
output that doesn't reference those motions.

### 4. Summarise a week of practice
On the stats screen, generate a one-paragraph weekly summary:
"You drilled 4 times this week, spent 18 minutes total, made fastest
progress on `d$`, struggled most with `cw`. Try Ch3 lesson 4 to
reinforce." Input: progress store + session logs.

Cost: one inference per stats screen view. Cache per-day.

Risk: summary invents numbers. Fix by passing aggregates verbatim
and asking the model only to narrativise — not compute.

### 5. Generate drill variations on demand
"I want 5 more `cw` drills on medical vocabulary." User picks a
theme, we generate seed bodies + predicates matching the theme. Lets
the app grow organically without a content pipeline.

Cost: 5 inferences up front (batchable). Not on a hot path.

Risk: highest of the five. Need to validate predicates actually
evaluate against the generated seed, probably in an automated
verification step.

## What doesn't fit

- **Real-time typing feedback.** Inference latency is too high.
  Keep this on rule-based logic (insert-mode activity counter,
  selection-change detection).
- **Teaching the motions themselves.** Static content is accurate,
  proofread, and doesn't drift. The model has no special authority
  on Vim semantics and can confidently misstate them.
- **Code generation for drills.** 3B parameters isn't enough for
  reliable code synthesis, and we don't need it.

## If we do this

Suggested sequence:

1. **Availability probe.** Add a helper that reports "Apple
   Intelligence: not supported / not enabled / ready" and surfaces
   it behind a feature flag.
2. **Pick one fit** — feedback after completion is the safest
   first shot because it's clearly additive (no drill breaks if it
   fails) and the input/output shape is tightly scoped.
3. **Fallback string for every prompt.** Never let the model's
   refusal block the UI.
4. **Cache aggressively.** Same inputs → same output is acceptable
   and saves cycles.
5. **Telemetry.** Log "prompt fired / refused / empty / useful"
   so we can measure whether the feature is earning its complexity.

## Open questions

- Does the framework expose streaming output? If yes, we can show
  partial generation in the UI instead of a spinner.
- Can we pin the model version so behavior doesn't silently change
  across OS updates?
- What's the policy on re-inference during Low Power Mode? Might
  need to disable the feature on battery.
