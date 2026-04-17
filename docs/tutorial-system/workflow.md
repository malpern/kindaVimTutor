# Workflow

The end-to-end process for producing a tutorial from scratch using this
system. Intended to be executable by a human or by an agent.

## 0. Inputs

Gather before you start:
- **Topic**: what is the artifact the reader will build?
- **Audience**: what do they already know? (Language fluency level,
  platform familiarity.)
- **Source material**: if a working codebase exists, have it open; if not,
  draft it first or interleave.
- **A product metaphor** for the illustration series (optional but
  recommended) — see `implementation-patterns.md` → "Progressive
  illustration."

## 0.5. Essentials branch (if a codebase exists)

If you're writing a tutorial *about* an existing codebase, strip it to
essentials first — on a branch.

**Before touching anything:** `git checkout -b Tutorial`. This must be
non-destructive. Main stays untouched; every simplification lives on the
branch.

Then walk the repo file by file and delete anything the tutorial won't
teach: unused code paths, stale feature flags, dead tests, "clever"
abstractions with a single implementation, commented-out blocks. Get it
compiling. Run the app end-to-end to confirm the stripped artifact still
works. Commit as a single `Strip to essentials for tutorial` commit.

Now every file in the repo is a file the tutorial will teach. See
`essentials-branch.md` for the full procedure and the rare cases where you
should skip this step.

## 1. Write the promise

Before any chapter content, write the hero subtitle. This is a ≤60 word
subtitle that names:
- The starting point ("Start from an empty file…")
- The endpoint (the artifact)
- The N things the reader will write along the way
- The meta-claim ("The N patterns nearly every X reuses")

Iterate this sentence until you can say it out loud and it lands. Every
chapter is downstream of this promise.

## 2. Outline the chapters

Draft titles only. Feature-named, not concept-named. Target 8–10 chapters;
pull in or split until the arc feels right.

For each chapter title write one sentence: what capability does the reader
add? This becomes the TOC blurb AND the goal-panel text.

## 3. Build the artifact (if you haven't)

Ideally: write the real code before the tutorial. The tutorial then
describes something that actually works. Anti-pattern: writing prose
first and synthesizing plausible code — invariably the code doesn't
compile.

If you must do them together: write each chapter's code first, get it
compiling, then narrate it.

## 4. Write chapter by chapter

For each chapter, in order:

### 4a. Skeleton

```html
<hr class="section-rule">

<section id="chN" class="chapter">
  <img class="bull" src="bulls/bull-NN-<stage>.png" alt="...">
  <p class="chapter-number">Chapter N</p>
  <h2>Feature name</h2>

  <div class="goal">
    <span class="goal-label">You'll build</span>
    <p>One sentence.</p>
  </div>

  <p class="chapter-opener">…</p>
</section>
```

### 4b. Opener

Use one of the three chapter-opening patterns (see `style-guide.md`):
lived observation, user-need, quietly contrarian claim. Drop cap applied
automatically via `chapter-opener` class.

### 4c. Body

Alternate prose and code. Apply the User → Decision → Code rhythm. For
chapters that introduce an extracted abstraction, start with the "What
happens if we don't" wrong-way-first pattern.

Before dense structural code: insert an SVG diagram.

Sprinkle at most two `aside.concept` callouts. Aim for at most one
`<blockquote>` pull quote.

### 4d. Close

A single `<div class="checkpoint">` — "Where we are" + one italic sentence.

## 5. Write the cheatsheet and resources

After all chapters are drafted, write the closing cheatsheet
(5 principles + annotations glossary) and the bulleted resources list.

The five principles should be derivable from the arc of the chapters. If
you can't distill the tutorial to five principles, your chapters aren't
teaching coherent principles.

## 6. Generate illustrations

If you haven't already, generate N illustrations using the
`nano-banana` MCP tool (or equivalent). Follow the prompt pattern from
`implementation-patterns.md`. Save to `docs/<project>/bulls/` (or
`docs/illustrations/`, name to taste).

```
mcp__nano-banana__image_generate_gemini(
  prompt="Hand-drawn charcoal sketch...",
  filenameHint="bull-N-<stage>"
)
```

Move/rename from `outputs/` to `docs/<project>/bulls/` with stable names.

## 7. Capture screenshots

If the topic has a UI:

1. Add a launch-argument harness to the app (see
   `implementation-patterns.md` → "Deterministic screenshot harness").
2. Write `scripts/capture-screenshots.sh` that launches the app for each
   state, captures with `peekaboo image --window-id …`, crops with
   `/usr/bin/swift scripts/crop-png.swift`.
3. Run it. Commit the PNGs.

## 8. Wire up the single-file HTML

Start from the blueprint skeleton. Paste in:
- CSS token variables (light + dark mode)
- Typography rules
- All component CSS (goal, checkpoint, chapter-header-row, speak-btn,
  miniplayer, settings-panel, firstrun, app-link, tt, external,
  chapter-nav, resources, cheatsheet)
- JS: Shiki init + chalkboard theme, copy buttons, glossary annotator,
  tap-to-toggle, sticky chapter nav, external-link annotator, read-aloud
  (if shipping), typewriter title (if shipping), hover-video (if shipping).

Reference the exemplar's source to copy-paste proven implementations.

## 9. Wiring Shiki (verbatim)

Inline at the bottom of `<body>`:

```html
<script type="module">
const chalkboardTheme = {
  name: 'chalkboard', type: 'dark',
  colors: { 'editor.background': '#5a4e30', 'editor.foreground': '#ece8e0' },
  tokenColors: [
    { scope: ['comment'], settings: { foreground: '#a8a290', fontStyle: 'italic' } },
    { scope: ['keyword','storage','keyword.other'], settings: { foreground: '#ff9a6c', fontStyle: 'bold' } },
    { scope: ['constant.numeric','constant.language'], settings: { foreground: '#e095b8' } },
    { scope: ['string'], settings: { foreground: '#b8db92' } },
    { scope: ['entity.name.type','support.type'], settings: { foreground: '#f0c878', fontStyle: 'bold' } },
    { scope: ['entity.name.function','support.function'], settings: { foreground: '#7bb8e8', fontStyle: 'bold' } },
    { scope: ['variable.other.enummember','constant.other.caseLabel'], settings: { foreground: '#e095b8' } },
  ],
};
async function highlight() {
  const { createHighlighter } = await import('https://esm.sh/shiki@1.22.2');
  const h = await createHighlighter({ themes: [chalkboardTheme], langs: ['swift','bash','shell'] });
  document.querySelectorAll('pre code[class*="language-"]').forEach(el => {
    const m = el.className.match(/language-(\w+)/);
    if (!m) return;
    const html = h.codeToHtml(el.textContent, { lang: m[1], theme: 'chalkboard' });
    const tmp = document.createElement('div'); tmp.innerHTML = html;
    const inner = tmp.querySelector('code'); if (inner) el.innerHTML = inner.innerHTML;
  });
  annotateGlossary(); // must run after highlighting
}
highlight();
</script>
```

Add/remove langs per your topic.

## 10. Review against the checklist

Run through `review-checklist.md`. Tighten anywhere you answer "not yet."

## 11. Ship

Commit the single HTML + assets + scripts. Push. Point GitHub Pages at the
`docs/` directory. Done.

## Ongoing

When the artifact changes:
1. Regenerate screenshots via the harness.
2. Update the affected chapter's prose — but resist re-structuring. The
   chapter order should be stable.
3. Re-run the review checklist.
