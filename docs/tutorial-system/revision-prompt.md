# Revision Prompt

Paste this prompt (with your draft) to an agent for a targeted revision
pass. Use it when you have an existing tutorial that needs to be brought
into this system's style, OR when a draft in-system is rough around the
edges.

---

You are revising an existing tutorial to match the system documented in
`docs/tutorial-system/`. Do not restructure unless the checklist demands
it. Prefer surgical edits to wholesale rewrites.

## Read first

1. `principles.md` — especially "User → decision → code" and "Features,
   not concepts."
2. `style-guide.md` — rewrite examples and the "don't" list.
3. `review-checklist.md` — every checklist item is a potential edit.

## Procedure

### Phase 1: audit

Run the tutorial through `review-checklist.md`. Produce a list of failures
in the form:

> **[section, chapter, or paragraph]** — [what's wrong] → [proposed fix]

Group the failures by severity:
- **Critical**: mis-named chapters (concept-named vs feature-named),
  absent checkpoints, missing cheatsheet/resources, broken promise.
- **Major**: voice issues ("simply", "in this chapter…"), itemized code
  re-explanations, too-many-callouts chapter, code without prose
  grounding, terse mechanical paragraphs after code blocks.
- **Minor**: typography misses (balance on the title, missing hanging
  punctuation, no drop cap), forgotten alt text, image not lazy-loaded.

### Phase 2: fix critical + major

For each critical issue, propose the rewrite and apply it after
confirmation. Don't silently re-title chapters or change structure.

For major voice/pedagogy issues, apply the user → decision → code pattern
to the offending paragraphs. Rewrite verbatim examples:

| Before | After |
|---|---|
| "A vertical stack with four lines…" | "Here's what the user sees when they open a lesson: a quiet chapter label overhead…" |
| "SwiftUI's List with .listStyle(.sidebar) is the native macOS sidebar." | "Every lesson in the tutor has to be pickable. On macOS the canonical 'list of things to pick from' has one shape — the left-hand sidebar you see in Mail, Finder, Xcode." |
| "You don't need a database." | "At the end of a drill the user has done something real — typed, retyped, earned a rep. If we lose that when they quit, the tutor feels dismissive." |

Pattern: rewrite to start with what the user experiences, not what the
API does.

### Phase 3: tighten

- Cut every sentence that doesn't advance the narrative, introduce a
  decision, or set up a code block.
- Condense itemized code explanations to one or two salient points.
- Shorten checkpoints to one italic sentence.
- Verify the subtitle promises the ingredients the final chapter delivers.

### Phase 4: product polish

Check every feature from `implementation-patterns.md`:
- Shiki syntax highlighting loads and matches the chalkboard theme?
- Copy buttons present on every `<pre>`?
- Glossary tooltips include all repeated Swift (or domain) terms?
- External links have the auto-annotation + no `↗` prefix?
- Sticky chapter nav present?
- Animated title (if present) uses CSS animation for blink, not JS?

### Phase 5: ship-readiness

- Run `review-checklist.md` again. Every box checked.
- Regenerate screenshots if the artifact's UI changed.
- Remove dev-only cache-control meta tags.
- Add SEO/OG tags if they weren't there before.
- Commit with a commit message describing what you tightened.

## Do not

- Do not add new chapters without user approval.
- Do not rewrite text that already matches the style.
- Do not delete working code examples to make prose fit.
- Do not convert concept callouts into inline prose without checking —
  sometimes the callout IS the right answer (the exemplar has 1–2 per
  chapter on purpose).

## Do

- Prefer deletion to addition. Most tutorial quality issues are caused by
  too many words, not too few.
- Match the exemplar's voice: dry, warm, direct.
- Keep the cheatsheet and resources untouched unless they're failing the
  checklist.
- When unsure, ask the author which of two rewrites lands better — the
  author's taste beats the agent's guess.
