# Principles

The axioms the system rests on. Every other document in this system is an
expansion of these.

## Pedagogical

### 0. Essentials first, on a branch

Before writing a single sentence, strip the codebase down to what the
tutorial will actually teach — on a new `Tutorial` branch, never on main.
Every file in the final artifact should be a file the reader encounters in
a chapter. Incidental complexity (unused code paths, stale feature flags,
shims, abstractions that earn nothing) is noise the reader has to edit out
in their head; do the editing for them first. The branch is the non-
destructive container — if the tutorial is abandoned, nothing real was
lost. See `essentials-branch.md`.

### 1. Features, not concepts

Chapters are named for what the reader *builds* ("A sidebar to pick from,"
"The drill engine"), never for concepts ("Understanding @State," "Observable
patterns"). Concepts arrive ambiently in callouts the moment the code needs
them. The reader finishes each chapter having **added a capability to the
artifact**, not having been taught a topic.

### 2. User → decision → code

Every explanation — whether opening a chapter or transitioning between code
blocks — proceeds in that order. State what the user experiences or needs.
Name the design decision. Show the code. The terse mechanical voice ("A
vertical stack with four lines") is the failure mode; the user-grounded voice
("Here's what the user sees when they open a lesson — a quiet chapter label
overhead…") is the target.

### 3. Concepts only when needed

Do not front-load the reader with definitions. Every term that has a one-line
definition belongs in a hover tooltip, not a preamble. The first mention of a
concept in prose is also the first place it appears in code.

### 4. "Wrong way first" for anything that earns its place

When introducing an extracted abstraction (a state machine, a service, a
helper), first show the tempting version that puts the logic *in the view*.
Let the reader feel the friction. Then pull it out. The reader remembers
*why*, not just *what*.

### 5. Checkpoints, not summaries

Each chapter ends with a single italic sentence — "Where we are" — describing
what now works and what still doesn't. No bullet-list recap. No "what you
learned." The artifact's state is the summary.

### 6. A cheatsheet, not a glossary maze

At the very end: a single compact recall card. Five principles as a numbered
list. Key annotations/protocols as a two-column grid. One page, glanceable,
photograph-able.

## Aesthetic

### 7. Paper, with chalkboard code

Warm off-white body (`#faf8f3`), serif prose (New York / Iowan Old Style),
sans-serif chrome (SF Pro). Code blocks are inverted — dark warm olive
(`#5a4e30`) with a bright chalkboard token palette. The contrast is the
point: prose reads like a magazine; code reads like a terminal.

### 8. Typography as a signal of care

Hanging punctuation. `text-wrap: pretty` on body, explicit override on the
streamed title to prevent rebalance flicker. Drop caps on the first paragraph
after the chapter goal panel. True small caps via `font-feature-settings` on
the uppercase-tracked labels. Em-dash bullet markers for in-chapter prose
lists. These are invisible to most readers and felt by all of them.

### 9. Progressive illustration

A decorative series runs across chapters, increasing in fidelity. In the
kindaVim case: Picasso-inspired charcoal bulls from a single-gesture glyph
(Ch1) to a fully rendered academic study (Ch9). The visual vocabulary
mirrors the learning arc. The subject is yours to choose; the
abstract-to-detailed progression is the pattern.

### 10. Pedagogical diagrams precede code

Where the code is dense or structural (data model, state machine, data
flow), a small SVG diagram using the same warm palette sits *before* the
code, not after. WWDC-style: show the shape, then the implementation.

## Product experience

### 11. Ambient microinteractions

Every interaction — hover tooltips, copy buttons, hover-to-play videos —
stays invisible until asked for. The reading column is never cluttered by
affordances. On touch, the same affordances degrade to tap-to-toggle.

### 12. Single file, no build

The entire tutorial ships as one HTML file. CSS inline. JS inline (ES
modules where needed, loaded from CDN). Highlighting, media, interactions,
analytics — all zero-build. Portable to GitHub Pages, Netlify, a static
bucket, or a flash drive.

### 13. Deterministic screenshots

The artifact the tutorial teaches builds should be launchable into a known
state via a launch argument or environment variable, and screenshotted
deterministically via a shell script. The tutorial's screenshots are
regenerable by anyone checking out the repo.

## Voice

### 14. Occasional first-person is good

A single "I've written that code. You don't want to debug it." in the middle
of a chapter does more for trust than three paragraphs of objective tone. Use
sparingly; earn it.

### 15. No empty transitions

Sentences like "Now let's look at…" and "In this section we'll…" are dead
weight. Every sentence either advances the narrative, introduces a decision,
or sets up a code block.

### 16. Commas, not footnotes

Inline parentheticals (like this one) belong inside the flow. Don't break out
to a callout for every aside — that dilutes the callouts that matter.
