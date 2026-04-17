# Tutorial Blueprint

The document skeleton. Grounded in the kindaVim Tutor tutorial's actual
structure. Follow it; vary only where the topic genuinely demands.

## Whole-document shape

```
Hero
  eyebrow
  h1 title (animated typewriter, optional)
  subtitle (the promise, ≤60 words)
  opening paragraph (what the app does + what the reader will build)
  takeaway bullets (5 items, aside.concept)
  [optional] note about hover-for-definitions

TOC
  N items (8–10), each with number, title, one-line blurb

Chapter 1 — The artifact you're building
  no code; orients the reader

Chapters 2..N-1 — one feature per chapter
  each delivers one user-visible capability

Chapter N — Closing loop
  the last piece of the artifact + end-to-end trace

Cheatsheet
  five principles + annotations grid

Further reading & watching
  plain bulleted list, grouped

Footer
```

## Hero

- **Eyebrow**: 13px uppercase small-caps label. One of:
  "A SwiftUI walkthrough", "A Rust tutorial", "A design guide", etc.
- **Title**: serif display type. Often a phrase with a playful twist; never
  clinical. "The KindaVim Tutorial… Tutorial" works because the ellipsis +
  repetition *earns* the pause. Adopt an animated typewriter with a green
  blinking cursor for the title on load if the topic deserves theatricality.
- **Subtitle** (the promise): ≤60 words. Name the artifact + the five things
  the reader will write along the way. This is the document's strongest
  commercial copy; polish it. Pattern:

  > "Start from an empty file. **N** chapters later, [describe the artifact
  > and what it does]. Along the way you'll write one of each thing a real
  > [domain] project needs: [five ingredients]. The [N] patterns nearly
  > every [domain] project reuses."

- **Opening paragraphs**: exactly three. Paragraph 1 frames the domain /
  problem (and can link an external product). Paragraph 2 establishes the
  artifact's shape + total size ("About 1,000 lines" or "One screen";
  concrete numbers). Paragraph 3 names the pedagogy (e.g., "The format
  follows Apple's Landmarks tutorial: each chapter is a feature, not a
  concept").

- **Takeaways**: a single `aside.concept` with the label "What you'll take
  away" and a 5-item `<ul>`. Each item is one line, present-tense, specific.

- **Hover-definitions note** (optional but recommended): one italic sentence
  immediately after the takeaways:
  > "A note before we start: any Swift attribute or protocol with a
  > *dashed underline* (in code *or* prose) gives a two-sentence definition
  > on hover or tap. The full glossary is in the cheatsheet at the end."

## Table of contents

- Heading: `"N chapters"` (uses the number). Small-caps.
- Each entry: 2-digit number + chapter title + 1-line italic blurb.
- Anchor links (`#ch1`, `#ch2`, …).

## Chapter anatomy

Every chapter follows this order:

1. **Decorative illustration**
   - A small image placed above the chapter number.
   - Part of a progressive series (abstract → detailed across the tutorial).
   - In the exemplar: charcoal bulls generated with `nano-banana`.
   - For other tutorials: any coherent visual series (sketches of tools, of
     animals, of abstract shapes in escalating detail).

2. **Chapter-number eyebrow**
   - "Chapter one", "Chapter two", … (spelled out, small-caps).

3. **h2 title** (feature-named, not concept-named).
   - Good: "A sidebar to pick from", "The drill engine", "Remembering the user"
   - Bad: "Understanding @State", "Mastering Observation"

4. **Goal panel**
   - A small bordered card. Label: "You'll build" or "You'll see". Followed
     by one sentence naming the capability the reader adds.
   ```html
   <div class="goal">
     <span class="goal-label">You'll build</span>
     <p>A one-sentence description of the capability.</p>
   </div>
   ```

5. **Chapter opener**
   - Marked with `class="chapter-opener"` — gets a drop cap.
   - 1–3 sentences. Situates the user. Sets up the decision.
   - See style-guide for opening patterns.

6. **Body**
   - Alternating prose and code. See `explanation-patterns.md`.
   - One or two concept callouts max per chapter.
   - One screenshot or diagram per chapter minimum where the topic is
     visual or structural. See `implementation-patterns.md`.

7. **Checkpoint**
   - Always the last element. "Where we are" + one italic sentence.

8. **Section rule**
   - A `<hr class="section-rule">` between chapters.

## Chapter sequencing

For a ~10-chapter tutorial:
- Ch1: What you're building (no code; orientation)
- Ch2: Model the data (plain value types, no UI)
- Ch3: First render (one static screen)
- Ch4: First list / picker (select one thing)
- Ch5: Shared state + navigation (the two panes wake up)
- Ch6: The first non-trivial presentation (slides, modes, views)
- Ch7: Core logic extracted (the state machine / engine)
- Ch8: A system boundary (native bridge, hardware, network)
- Ch9: Persistence + end-to-end trace (the keystroke-to-disk paragraph)
- [Ch10]: Optional deploy/ship chapter

For shorter tutorials compress symmetrically: combine 4+5, combine 6+7, etc.
Minimum 4 chapters; fewer and the format loses rhythm.

## Cheatsheet (penultimate section)

- h2: "Cheatsheet"
- italic deck: one sentence ("The shape of this app, at a glance…")
- h3 small-caps: "Five principles" → numbered list where each li has
  `<strong>title.</strong><span>italic reasoning</span>`.
- h3 small-caps: "Annotations & protocols" → 2-column grid:
  `code` + one-line definition.

This is the recall aid. Designed to be glanced at six months later.

## Resources (final section)

- h2: "Further reading & watching"
- Two or three `<h3>` groupings (e.g., "From Apple", "Practitioners",
  "When you need to go deeper").
- Each group: a plain `<ul>` of items.
- Each item: small leading icon (video = play triangle; article = document
  lines) + linked title. No meta, no blurb.

The exemplar used to have blurbs; the user cut them. The plain bullet form
is the right answer.

## Footer

One line, sans, muted. "`<project>` · `<branch>` · `docs/tutorial.html`".
