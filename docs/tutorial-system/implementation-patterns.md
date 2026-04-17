# Implementation Patterns

Concrete product features and tooling used by the exemplar. For each:
what, why, when, and whether it is **required / recommended / optional**.

## A. Single-file HTML, inline CSS, ES-module JS — REQUIRED

All CSS inline in a `<style>` tag. All JS inline or loaded from CDN. No
build step. No bundler. The tutorial ships as one `.html` plus a `docs/`
directory of images and videos.

Why: portability (GitHub Pages, Netlify, anywhere static), reviewability
(one file open in one editor), no toolchain drift.

## B. Chalkboard syntax highlighting via Shiki + custom theme — RECOMMENDED

Shiki loaded as an ES module from `esm.sh`. Swift, Bash, Shell grammars.
A custom theme JSON embedded inline matches the warm palette.

Why Shiki over Prism: TextMate grammars (same ones VSCode uses) handle
enum-case shorthand, argument labels, macros, attributes correctly;
Prism's regex-based grammars don't.

Fallback: if Shiki fails to load (offline, CDN down), the `pre code` CSS
carries the background + default color, so code stays legible
unhighlighted.

Theme color sketch (tune to your topic):
- bg `#5a4e30` (dark warm olive)
- fg `#ece8e0` (cream)
- keywords `#ff9a6c` bold
- types `#f0c878` bold
- functions `#7bb8e8` bold
- strings `#b8db92`
- numbers / enum cases `#e095b8`
- comments `#a8a290` italic

See `workflow.md` → "Wiring Shiki" for the exact script block.

## C. Progressive illustration series — RECOMMENDED

One decorative image per chapter. Across the tutorial they progress in
fidelity / detail / complexity — abstract → detailed. The visual vocabulary
is the reader's learning arc, obliquely.

### Exemplar: charcoal bulls

- Generated with the `nano-banana` MCP tool (Gemini image generation).
- Prompt pattern: "Hand-drawn charcoal sketch on warm off-white aged paper.
  A bull rendered as [STAGE]. Picasso-inspired. Raw visible charcoal grain.
  No background, no text. Rich black charcoal on cream paper. Landscape."
- Stages: glyph → gesture → contour → details → form → shading → muscle →
  texture → expression → masterwork.
- 10 images, one per chapter + one extra.

### Generalizing the pattern

The subject is yours. Candidates:
- Architectural sketches (hut → house → building → city)
- Ship drawings (raft → sailboat → clipper → carrier)
- Instruments (tuning fork → violin → orchestra → symphony)
- Machines (wheel → bicycle → car → spacecraft)
- Pick one aligned with your topic's metaphor.

### CSS

```css
.bull {  /* or .chapter-illustration */
  display: block;
  width: 100%;
  max-width: 420px;
  margin: 0 auto 36px;
  mix-blend-mode: multiply;
}
@media (prefers-color-scheme: dark) {
  .bull { mix-blend-mode: screen; opacity: 0.92; }
}
```

The `mix-blend-mode` trick makes charcoal-on-white sketches blend
naturally into warm paper (and invert gracefully in dark mode).

## D. Deterministic screenshot harness — RECOMMENDED (if the artifact has a UI)

Two parts:

### D1. App accepts a launch argument for initial state
- `--initial-state welcome` → default
- `--initial-state lesson:ch1.l1` → specific screen
- `--initial-state lesson:ch1.l1:3` → specific step in that screen
- Optional `--seed-progress "id1,id2,…"` for "completed" states
- Honor `KINDAVIM_PROGRESS_DIR` (or equivalent) env var to redirect local
  state to a temp dir so the screenshot run doesn't touch the developer's
  real data.

### D2. A shell script under `Scripts/` that:
1. Rebuilds the app.
2. Launches it for each screenshot with the appropriate args.
3. Captures the window with `peekaboo` (or `screencapture`).
4. Optionally crops with a small CoreGraphics-backed helper (`sips` has
   unreliable `cropOffset` semantics — write a 30-line Swift script that
   uses `CGImage.cropping(to:)`).

Exemplar: `Scripts/capture-screenshots.sh` + `Scripts/crop-png.swift`.

Why: screenshots are regenerable from the real app, versioned alongside
code, and never become stale.

## E. Pedagogical SVG diagrams — RECOMMENDED

Inline SVGs with a shared `<style>` block using the warm palette. Used
BEFORE dense code (data model, state machine, data flow, sequence).

### Shared palette inside SVGs

```css
.dg-box { fill: #f5eeda; stroke: #a69874; stroke-width: 1; }
.dg-accent { fill: #fbe8c6; stroke: #c4a159; stroke-width: 1.3; }
.dg-label { font: 700 13px -apple-system, "SF Pro Text"; fill: #1a1a1a; }
.dg-sub   { font: 10px -apple-system, "SF Pro Text"; fill: #5d5343; }
.dg-edge  { font: italic 500 11px -apple-system, "SF Pro Text"; fill: #5d5343; }
.dg-line  { stroke: #8a8070; stroke-width: 1.5; fill: none; }
@media (prefers-color-scheme: dark) {
  .dg-sub, .dg-edge { fill: #d6cfc1; }
}
```

### Diagram types to consider

- Data model composition (Ch2-style)
- Source-of-truth triangle (Ch5-style)
- Transformation / flatMap before→after (Ch6-style)
- State machine (Ch7-style)
- Sequence diagram (Ch9-style)

Place each inside `<figure class="diagram">` with a `<figcaption>`.

## F. Ambient glossary tooltips — RECOMMENDED

Every protocol / attribute / macro with a one-paragraph definition gets a
dashed underline and a dark-pill tooltip on hover/tap. Covers both inline
`<code>` in prose AND token spans inside highlighted `<pre>` code.

Pattern:
- JS walks tokens/code elements, matches text against a `glossary` dict,
  tags matching elements with `class="tt"` and `data-tt="definition"`.
- CSS handles the rest: dashed underline, absolutely-positioned pill on
  `:hover`/`:focus`/`.is-open`.
- Tap-to-open handler: click toggles `.is-open`, Escape dismisses.

Definitions are **exactly two sentences**: WHAT (sentence 1) + WHY / when /
gotcha (sentence 2). Intro note in the hero tells readers the feature exists.

## G. Copy-to-clipboard buttons — RECOMMENDED

A small sans-serif button appearing in the top-right of every `<pre>` on
hover. Fades in/out. "Copy" → "Copied" confirmation with a green color
flash for ~1.4s after click. Touch users get it always-visible at smaller
scale (exemplar currently doesn't — flagged as a mobile polish item).

## H. Sticky chapter-context nav — RECOMMENDED

A minimal fixed top bar that appears after scrolling past the hero:
- Left: ← previous chapter title (dimmed, clickable)
- Center: Current chapter number + title
- Right: next chapter title → (dimmed, clickable)
- Bottom: a thin 2px progress bar in accent color.

Driven by `IntersectionObserver` on each `section.chapter`.

Why: long-form content is easier to parse when you always know where you
are.

## I. Hover-to-play external video — OPTIONAL

When linking an external product/tool (kindaVim.app in the exemplar), use
the `app-link` pattern: inline icon + bolded name + dashed underline. On
hover, a small floating card appears with the product's demo video
autoplaying muted and looping. Lazy-mounted (video URL only fetched on
first hover). `matchMedia('(hover: hover)')` guards keep touch devices out.

Animation details that make or break the feel:
- 180ms hover-intent delay before show (no flash on quick passes).
- 120ms grace period on mouseleave before hide (lets the reader move the
  cursor into the card).
- Card enters with opacity + scale + translateY, cubic-bezier(0.2, 0.8,
  0.2, 1).
- Video fades in separately when its first frame loads (prevents a white
  flash).
- Transform-origin flips if the card has to render above instead of below
  (not enough room).

## J. Read-aloud feature — OPTIONAL

Per-chapter speak icon button with first-run modal: "Browser voice" (free,
offline) vs "OpenAI voice" (BYOK, expressive). Sentence-level highlighting
during playback. Floating mini-player with play/pause/speed/gear/close.

Complexity: meaningful (~400 lines of JS). Ship it when the audience
plausibly values listen-while-walking; skip when the tutorial is short or
the audience is strictly desk-bound.

## K. Animated typewriter title — OPTIONAL

The hero's h1 animates in character by character with jitter timing and a
green blinking cursor. Two pauses for comedic effect (e.g. "The KindaVim
Tutorial… Tutorial").

Lessons from the exemplar's implementation:
- Cursor blink via **CSS animation with hard steps**, not JS setInterval.
  (Interval-driven opacity changes race with layout reflow during typing.)
- `text-wrap: balance` off on the title (it rebalances per character,
  causing a "flash of full line then reflow" on wrap). Use plain `wrap`.
- `min-height: 2.1em` reserves space for a two-line title so the layout
  doesn't jump when wrapping kicks in.
- Non-breaking space before the final word so it can never orphan onto
  its own line.
- Cursor span is `display: inline` (not inline-block), nudged with
  `vertical-align` (not `transform`), so it never becomes a wrap point.
- Keep the full title as `aria-label` on the `<h1>` for screen readers;
  the animated span is `aria-hidden="true"`.

## L. Cheatsheet card — REQUIRED

The penultimate section. Non-negotiable. See `tutorial-blueprint.md`.

## Priority summary

| Feature | Priority | Cost | Benefit |
|---|---|---|---|
| Single-file, zero-build | Required | — | Portability |
| Cheatsheet | Required | Low | Recall aid |
| Shiki syntax highlighting | Recommended | Low | Accurate code |
| Progressive illustrations | Recommended | Medium | Rhythm + atmosphere |
| Screenshot harness | Recommended (for UI topics) | Medium | Fidelity |
| Pedagogical diagrams | Recommended | Medium | Comprehension |
| Glossary tooltips | Recommended | Low | Ambient learning |
| Copy buttons | Recommended | Low | Practical |
| Sticky chapter nav | Recommended | Low | Orientation |
| External links annotated | Recommended | Low | Trust |
| Hover-video on external refs | Optional | Low | Delight |
| Read-aloud | Optional | High | Accessibility + modality |
| Animated typewriter title | Optional | Low | Personality |

Ship Required + as many Recommended as fit your timeline. Optional items
earn their place only if they match the topic.
