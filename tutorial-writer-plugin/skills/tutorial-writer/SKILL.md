---
name: tutorial-writer
description: Produce or revise a long-form technical tutorial in the house style — feature-named chapters, user-first prose, single-file HTML with chalkboard code, progressive illustrations, and ambient microinteractions. Use when the user asks to write a tutorial, walkthrough, or guide for a project.
---

# tutorial-writer skill

This skill orchestrates the tutorial system documented in
`tutorial-writer-plugin/docs/tutorial-system/`. Use it whenever the user
wants to produce a tutorial — from scratch or as a revision of an existing
draft.

All paths in this skill are relative to the **host project's root** and
assume the plugin directory is copied in at `tutorial-writer-plugin/` (the
default name). If the plugin was copied under a different name or into a
subdirectory, substitute accordingly.

## When to use

Trigger this skill when the user says any of:
- "Write a tutorial for [project]"
- "Document this app as a walkthrough"
- "Make a kindaVim-style tutorial for X"
- "Can you revise the tutorial I have?"
- "Bring this draft into our house style"

Do **not** use this skill for short-form content (README, API doc, blog
post). This is for long-form, multi-chapter tutorials.

## Playbook

### Step 1 — Read the system

Before doing anything else, read in order:

1. `tutorial-writer-plugin/docs/tutorial-system/principles.md`
2. `tutorial-writer-plugin/docs/tutorial-system/style-guide.md`
3. `tutorial-writer-plugin/docs/tutorial-system/tutorial-blueprint.md`
4. `tutorial-writer-plugin/docs/tutorial-system/explanation-patterns.md`
5. `tutorial-writer-plugin/docs/tutorial-system/implementation-patterns.md`

If an exemplar tutorial is available in the host project (e.g., at
`docs/tutorial.html` from a previous run), skim it once — a working
reference beats a description.

### Step 2 — Branch: new vs revision

**If the user is producing a new tutorial:**
- Open `tutorial-writer-plugin/docs/tutorial-system/generation-prompt.md`
- Confirm each input with the user: topic, artifact, audience, chapter
  count, five ingredients, illustration metaphor, demo video URL.
- Work through the procedure in that file step by step.

**If the user is revising a draft:**
- Open `tutorial-writer-plugin/docs/tutorial-system/revision-prompt.md`
- Run the four-phase audit-and-fix procedure described there.

### Step 3 — Write the promise first

Before any chapter content:
- Produce the hero subtitle (≤60 words).
- List the five ingredients.
- Get sign-off from the user before writing further.

The subtitle is the document's hardest, most valuable sentence. Polish
it until you could read it aloud and have it land.

### Step 4 — Outline

Feature-named chapter titles. One sentence per chapter describing what
capability the reader adds. Present to user, accept feedback, iterate.

### Step 5 — Build chapters

In order, for each chapter:
1. Goal-panel sentence
2. Opener (one of three patterns from `style-guide.md`)
3. Body with user → decision → code rhythm
4. Checkpoint

Alternate prose and code. Use "wrong way first" for any chapter that
extracts an abstraction. Insert pedagogical SVG diagrams before dense
code. Max two `aside.concept` callouts per chapter, max one
`<blockquote>`.

### Step 6 — Illustrations

If a nano-banana or equivalent image generator is available:
- Generate one illustration per chapter.
- Progressive fidelity (abstract → detailed).
- Rename outputs with stable filenames: `bulls/bull-01-<stage>.webp`
  through `bulls/bull-N-<stage>.webp` (after running through cwebp — see
  section P of `implementation-patterns.md`).

If no image generator available, ship without illustrations — do NOT use
placeholder images.

### Step 7 — Screenshots (UI topics only)

If the tutorial's artifact has a UI:
1. Propose a launch-argument harness for the app.
2. Emit `Scripts/capture-screenshots.sh` + `Scripts/crop-png.swift`.
3. Run the harness to generate screenshots.
4. Embed the most pedagogically useful ones (cropped close-ups preferred
   over full-window shots where isolation helps).

### Step 8 — Cheatsheet and resources

At the end:
- Cheatsheet: 5 numbered principles + 2-column annotations grid.
- Resources: plain bulleted list with video/article icons, no blurbs.

### Step 9 — Assemble the HTML

Emit a single `docs/tutorial.html` (in the host project) following the
blueprint exactly. Copy CSS + JS sections from the exemplar; adapt class
names and colors as needed. Include:
- Shiki highlighting with the chalkboard theme
- Copy buttons, glossary tooltips, external-link annotator
- Sticky chapter nav
- Drop caps, small caps, hanging punctuation, text-wrap, orphans/widows

### Step 10 — Ship-blocking technical fixes

Before reviewing the writing, make sure these are in place. Each is small
but cumulatively they're the difference between a shippable tutorial and
a draft:

1. **SEO + social metadata.** `<meta name="description">`, Open Graph
   tags (`og:title`, `og:description`, `og:image`, `og:url`, `og:type`),
   Twitter Card tags, canonical URL, JSON-LD `TechArticle` structured
   data. Populate with real values.
2. **Favicon.** A 32×32 PNG linked via `<link rel="icon">` and
   `<link rel="apple-touch-icon">`.
3. **`loading="lazy"`** on every `<img>` below the fold.
4. **Optimize illustrations** — `sips -Z 840` then `cwebp -q 82`. ~40×
   smaller than raw PNG.
5. **Remove dev-only `<meta http-equiv="Cache-Control">` tags.**
6. **Wrap content in `<main><article class="page">`.**
7. **Mobile touch polish.** 44pt touch targets on `@media (max-width: 720px)`;
   `bottom: calc(Npx + env(safe-area-inset-bottom))` on fixed UI.

See `tutorial-writer-plugin/docs/tutorial-system/implementation-patterns.md`
→ sections M through S for the exact snippets.

### Step 11 — Content review

Run the draft through
`tutorial-writer-plugin/docs/tutorial-system/review-checklist.md`. Fix
every item that doesn't pass before shipping. Typical writing failures:
- Mechanical paragraphs after code blocks → rewrite to user-first.
- Missing checkpoints → add them.
- Concept-named chapters → rename to feature-named.
- Too many `aside.concept` callouts in one chapter → trim to 2 max.

### Step 12 — Hand off

Report to the user with:
- Word count, reading time estimate, chapter count.
- Specific things that were interesting or hard.
- Any outstanding TODOs (unoptimized bull images, missing demo video,
  etc.).
- Commit and push if on a git repo.

## Principles to enforce

- **Features, not concepts.** If you catch yourself naming a chapter
  "Understanding X" or "Mastering Y," stop and rename.
- **User → decision → code.** Every post-code paragraph should start by
  grounding the reader in user experience, not by describing the code.
- **Cut, don't add.** Quality correlates with brevity.
- **Ambient, not loud.** Microinteractions stay invisible until asked
  for. Single-file + zero-build + dashed-underline affordances.
- **Ship one thing per chapter.** The artifact gains one capability per
  chapter. The chapter is named for that capability.

## Anti-patterns to refuse

- Concept-named chapters ("Understanding @Observable")
- Bullet-list recaps at the end of chapters
- "As you can see…" / "Let me explain…" / "In this section…"
- Emojis in body prose
- Inline API dumps without user-grounding
- Placeholder content ("TODO: fill in later")
