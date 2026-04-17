# Tutorial System

A reusable system for producing long-form technical tutorials with the craft
level of the kindaVim Tutor walkthrough. Reverse-engineered from that single
document; generalized to any topic.

The system is opinionated. If you follow it, your tutorials will share a
specific voice (warm, direct, user-first), a specific structure (feature-named
chapters, not concept-named), and a specific product shape (single-file HTML,
ambient microinteractions, chalkboard code aesthetic).

## Files

| File | Purpose |
|---|---|
| `principles.md` | The pedagogical and aesthetic axioms the whole system rests on. Read first. |
| `style-guide.md` | Voice, tone, typography, sentence patterns, concrete rewrites. |
| `tutorial-blueprint.md` | The skeleton: hero → TOC → N chapters → cheatsheet → resources. |
| `explanation-patterns.md` | How to introduce, reinforce, and close out a concept. Includes "user → decision → code" and "wrong way first." |
| `implementation-patterns.md` | The concrete product features: bulls, screenshot harness, speak buttons, glossary tooltips, diagrams, syntax highlighting, hover video. Which are required vs recommended vs optional. |
| `workflow.md` | The end-to-end process. Step-by-step. |
| `review-checklist.md` | A QA checklist to audit any draft against the system. |
| `generation-prompt.md` | A prompt template for producing a new tutorial from scratch. |
| `revision-prompt.md` | A prompt template for revising/tightening an existing tutorial. |

## Operating principles in one paragraph

A tutorial is a feature-by-feature build, not a concept lecture. Each chapter
names what the reader *makes*, not what they learn — the concepts arrive in
ambient asides the moment the code needs them. The voice is direct and
situated in user experience ("the reader sees…"). The artifact is a single
HTML file, no build step, warm paper palette with chalkboard-dark code,
decorative illustrations that progress in fidelity across chapters, and
microinteractions (hover-videos, tap-tooltips, copy buttons, read-aloud) that
stay ambient — visible only when asked for.

## How to use this system

1. **For a new tutorial:** read `principles.md` → read `tutorial-blueprint.md`
   → fill out `generation-prompt.md` with your topic and hand to an agent.
2. **For an existing draft:** read `style-guide.md` → run it through
   `review-checklist.md` → use `revision-prompt.md` to patch.
3. **For an agent:** use the `tutorial-writer` skill in `.claude/skills/`
   which orchestrates all of the above.

## Portability

All paths are relative. Nothing depends on the kindaVim project. Copy the
`docs/tutorial-system/` directory to any repo and it works. Copy the
companion plugin at `tutorial-writer-plugin/` for Claude Code plugin-based
reuse.
