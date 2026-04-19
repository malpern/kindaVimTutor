# In-app coaching — future direction

**Status**: design sketch, not a plan with dates.
**Date**: 2026-04-19
**Stance**: ship small wins in-sandbox first; approach kindaVim's maintainer with a narrow signal request *after* we've proven the coaching pedagogy works.

---

## The vision in one line

The tutor should become the thing that takes Vim motions from "I know them in a drill" to "I use them in Slack, Mail, and Xcode without thinking." Transfer into real apps, not another sandbox.

## Why this direction

Most Vim-learning products stall because they stay in a sandbox too long. The student finishes the drills, opens their real editor, and pattern-matches with arrow keys again. kindaVim is uniquely positioned to close that gap because it already *is* the layer that makes Vim motions work in every macOS text field. A coaching product built on top of kindaVim has a clean platform story: kindaVim does the motions, we teach the transfer.

## Core principles

1. **Real apps are the stage, the tutor is the coach.** The user never types inside our window for real-app lessons; they type in Slack. We observe and respond.
2. **Commands first, text never (if possible).** Grade what a student *did* (the Vim command they invoked, the timing, the mode), not *what they typed*. Privacy is the kindaVim platform's greatest asset; don't spend it unless forced.
3. **Goal-based, not step-based.** Tell the student what to accomplish. Accept any correct solution. Surface better ones *after*.
4. **Correct only after the fact.** Celebrate mid-command if useful ("you flipped to NORMAL ✓"); never correct mid-command. Feedback on mistakes happens *after* the command fires.
5. **Failure is instructive.** kindaVim doesn't always work the same across apps. Real-app lessons should lean into this — "that didn't work here; try this fallback" is a teaching moment nothing else provides.

## Why we are NOT building our own Accessibility observer

Strong temptation: use `AXObserver` ourselves to watch every app's text fields. Reject this. Four reasons:

1. **Duplicates kindaVim's work.** kindaVim already has AX permission, already interprets keystrokes, already tracks mode. Layering a second AX-using process on top of it is brittle and expensive.
2. **User-trust cost doubles.** Two "allow accessibility" permission prompts, not one. Every denial is a lost user.
3. **Per-app brittleness is endless.** Electron apps, Catalyst apps, WebViews, SecureTextFields each need special-case handling. kindaVim already eats this complexity internally.
4. **Wrong abstraction.** Raw AX events force us to re-derive Vim semantics from scratch. The interesting signal is "the user executed `daw` at time T" — which is a concept only the layer that parses commands can emit.

The right path is to consume what kindaVim already knows.

## The minimum viable signal ask

One new file kindaVim would write, mirroring the existing `environment.json` pattern:

**`~/Library/Application Support/kindaVim/events.ndjson`** — append-only, newline-delimited JSON. One line per parsed command. Gated behind an opt-in preference (model: `enableKarabinerElementsIntegration`, off by default).

Example line:

```json
{ "t": "2026-04-19T10:23:15.123Z",
  "mode": "normal",
  "cmd": "d", "motion": "aw", "count": 1,
  "app": "com.tinyspeck.slackmacgap",
  "field": "textarea",
  "dur_ms": 380,
  "keystrokes": 3 }
```

Field-by-field rationale:

| Field | What it enables | Notes |
|---|---|---|
| `t` | Timing, fluency metrics | ISO 8601 local time |
| `mode` | Context for the command | Already computed |
| `cmd` / `motion` / `count` | Post-action coaching (*"you used `dw`, try `daw`"*) | This is the whole point |
| `app` | Per-app curriculum + fallback teaching | Bundle ID only — no content |
| `field` | Distinguishing compose box vs search vs password | Coarse enum; not the AX tree |
| `dur_ms` | Hesitation detection, fluency weakness maps | Cheap derivation |
| `keystrokes` | Efficiency grading (*you used 4 keys; optimal is 3*) | Literal count |

No text content. No full AX tree. Just command semantics kindaVim has already parsed.

## Why we do NOT ask for text content or the AX tree

Asked explicitly — should we also request the actual text around each command, or the focused element's AX subtree? Answer: no, at least not in the first ask.

1. **Privacy cost is asymmetric.** Even with opt-in, streaming user text (from Slack DMs, Notes, Mail drafts, password fields, autofill) to a third-party coaching tool is a qualitatively larger surface than streaming command semantics. One bad incident torches the user-trust compact kindaVim is built on — and the *maintainer* is the one exposed.
2. **Political cost to the relationship.** Command events are a natural extension of the file-based IPC kindaVim already shipped (`environment.json`). Text is not an extension; it's new, scarier plumbing. The smaller the ask, the higher the yes-rate.
3. **80% of coaching doesn't need it.** Command correctness, efficiency grading, timing, fluency maps, post-action suggestions, fallback training when commands no-op — all of these are command-shape problems, not text-shape problems.

### What we give up without text

- **Target-specific lessons.** "Delete the word 'fox'" — can only become "delete any word using `daw`." Mitigate with user-chosen targets; arguably better pedagogy anyway.
- **Outcome verification.** We confirm `daw` fired; we can't confirm which word vanished. Acceptable — we trust the student's own targeting.
- **Typo detection in Insert mode.** Not Vim-teaching anyway.

### If command events prove insufficient: the narrow escalation

Not text. Not tree. A **command-scoped edit shape**:

```json
{ "cmd": "daw",
  "delta": { "removed": 4, "added": 0,
              "from_col": 10, "to_col": 14 } }
```

"4 characters disappeared in this range" — the *shape* of the edit, no bytes. Unlocks:

- "your `daw` removed 4 characters — that's about a word, nice"
- "your `daw` removed 0 characters — motion didn't apply in this field"
- Shape-based correctness grading with no content exposure

Still a bigger ask than command events alone. Make it *only after* shipping command-event coaching and identifying specific pedagogical gaps that require it.

## What coaching actually looks like

### Tutor window is the coach; real app is the stage

Split the screen: tutor window on one side showing current task + progress, real app on the other side where the student actually types. The tutor observes `events.ndjson`; it never intercepts keys.

### Lesson anatomy

Each lesson is a script of **tasks**. A task has four parts:

1. **Prompt** — what to accomplish, plus which Vim tool we expect. Shown in tutor.
2. **Observation window** — the coach listens for matching events.
3. **Validation** — a matching event arrived, or a close-but-not event (e.g. `dw` instead of `daw`), or nothing for N seconds.
4. **Feedback** — short response, auto-advance.

### Feedback timing

- **Before** — restate task. Always.
- **During** — *positive only*. ("Mode flipped to NORMAL ✓"). Never corrective.
- **After** — the moment for grading. The student just finished; they're receptive.

### Validation without text

The event stream gives us `cmd + app + mode + timing`. That lets us grade:
- "Did they run `daw`?" ✓
- "Was it in Slack's compose box?" ✓
- "Under 2 seconds?" ✓
- "Did they delete 'fox' specifically?" ✗ — we can't see text, so lessons are written to the constraint.

### Sketch of a Slack lesson (5 minutes, 8 tasks)

1. **Setup** — open Slack, paste a sample sentence into any draft.
2. Enter Normal mode (`Esc`).
3. Jump to a word (`w` or `f<letter>`).
4. Delete it (`daw`). Close-but-wrong handling: *"That was `dw`. Try `daw` — 'delete **a** word' includes the space."*
5. Jump to end of line (`$`).
6. Delete to end of line (`D`). Accept `d$` as equivalent.
7. Replace final character (`r!`).
8. Back to Insert; type ` — nice!`.

**Wrap screen**: *"8 commands, 18 keystrokes, 42 seconds. Personal fluency: `daw` fast ✓ · `f` still slow (2.1s hesitation) · `$` unused this session."*

### Non-negotiable UX rules

1. User never focuses the tutor window to advance. Auto-advance on matching event.
2. Clear "observing" indicator (menu bar icon, pulsing header).
3. Always-visible **Pause / Stop**. Observation is suspended in one click.
4. Commands unrelated to the current task are never graded. User can Cmd-K through Slack mid-lesson; tutor stays silent.
5. Skip is always available on every task. Some Slack versions, some fields, some moods — nobody gets stuck.

### Failure as the killer feature

In real apps, `ci(` sometimes no-ops. Our coach handles this:

> *"kindaVim couldn't find parens around the cursor here — that's a Slack quirk. Try this fallback: `vi(` to select first, then `c` to change. Try it now."*

This is the single thing the real-app tutor does that nothing else can. It only becomes possible with `events.ndjson` exposing no-op outcomes.

## Sequencing

Do *not* block the coaching roadmap on the maintainer. Ship the sandbox-side pieces first, then approach godbout with a working product that would benefit from the signal — much stronger pitch than "we might build something cool if you add this."

**Phase A — sandbox coaching (no external dependencies, weeks)**

1. Post-action coaching on existing drills. Tag each exercise with an "optimal keystroke count" (or compute from the cursor path). After completion: *"You did it in 7 keystrokes. Idiomatic is `d3w` — 3 keystrokes."* Biggest single pedagogical lift.
2. Fluency insights view mining existing `DrillSession` files. *"Fast on `w`, slow on `f` (1.4s hesitation)."* Motivational + teaching signal in one.
3. Mental-model HUD inside the drill editor. Live-parse partial commands: `d` → "delete", `d` + `i` → "delete inside", `d` + `i` + `(` → "delete inside parens." Makes the verb-object-motion grammar visible.

**Phase B — approach godbout (only after Phase A proves the loop)**

Open a proposal on `godbout/kindaVim.blahblah` referencing the existing `environment.json` integration. Describe `events.ndjson` as a natural extension. Show the Phase A product as motivation. Keep the ask minimum (command events only, opt-in).

**Phase C — real-app coaching prototype (only if Phase B lands)**

1. Pick ONE app (TextEdit) to prove the UX of tutor-window-observes-real-app auto-advance. Validate *"does it feel magical or confusing?"*
2. One complete Slack lesson as the second validation surface.
3. Fallback training when commands no-op.

**Phase D — later**

- Cross-app navigation curriculum (Finder, Mail, browser tracks)
- Live coaching mode (passive observation of real work with opt-in nudges — the UX problem is substantial; prototype carefully)
- Workflow challenges (multi-step chains)
- Delta-shape escalation if Phase C surfaces a specific gap

## What we're deliberately not pursuing

- **Leaderboards.** A learning tutor shouldn't encourage comparison to strangers.
- **Our own AX observation layer.** Tarpit; see above.
- **Text-content streaming** on speculation. See above.
- **Background "coach me during real work" mode** as an early bet. The UX problem is larger than the technical one; defer until a careful prototype exists.

## Open questions

- Does the `events.ndjson` proposal get a yes from godbout? Unknown until we ask. Ship Phase A first to have leverage.
- Is the tutor-window-beside-real-app UX actually magical, or just confusing? Only one way to find out — the TextEdit prototype.
- Does per-command `delta` shape ever become necessary? Depends on what Phase C surfaces.
- Can we realistically teach anything useful in Electron-heavy apps (Slack, Discord, VS Code)? Some motions don't work reliably there; the *fallback* teaching angle partially answers this, but it's the hardest real-world case.

## The one-line recap

Small signal ask, big pedagogical payoff, no privacy debt — if we can pull it off. Prove the loop in-sandbox first, then go ask.
