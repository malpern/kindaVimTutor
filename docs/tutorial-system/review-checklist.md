# Review Checklist

Walk through these after a draft is complete. Any "no" answer needs a
fix before shipping.

## Promise

- [ ] Subtitle names the starting point, the artifact, and exactly N
  concrete things the reader will write (not learn).
- [ ] Opening paragraphs establish the domain → artifact → pedagogy in
  exactly three paragraphs.
- [ ] "What you'll take away" aside lists exactly five bullets, each one
  present-tense and specific.
- [ ] The hover-definitions note appears (one italic sentence after the
  takeaways).

## Structure

- [ ] Every chapter has: decorative illustration → chapter-number eyebrow
  → h2 title → goal panel → chapter-opener paragraph → body → checkpoint.
- [ ] Chapter titles are feature-named, not concept-named.
- [ ] Section rules (`<hr class="section-rule">`) separate every chapter.
- [ ] TOC matches chapter titles and has a one-line italic blurb per entry.
- [ ] Cheatsheet and Resources sections close the document, in that order.

## Voice

- [ ] No sentence begins with "In this chapter," "Let me explain," "As we'll
  see," or "Now we'll look at."
- [ ] No "simply," "just," "obviously," or "basically."
- [ ] No exclamation points.
- [ ] No emoji in body prose. (Icons via SVG are fine.)
- [ ] Every chapter opener uses one of the three patterns (observation /
  user-need / contrarian).
- [ ] At least one chapter uses the wrong-way-first pattern.
- [ ] At most two `aside.concept` callouts per chapter.
- [ ] At most one `<blockquote>` per chapter.
- [ ] Checkpoints describe artifact state, not reader's learning.

## Prose rhythm

- [ ] Every post-code paragraph begins by grounding the reader in user
  experience or design decision — not by describing the code just shown.
- [ ] No itemized code re-explanations after code blocks.
- [ ] Sentences of mixed length (short + long alternation).
- [ ] Em-dashes used for asides, not every other line.

## Code

- [ ] All code blocks use language-tagged `<pre><code class="language-…">`.
- [ ] The first code block per file is followed by a `code-caption` path.
- [ ] Long methods are elided with `// ...` rather than dumped.
- [ ] Boilerplate (empty inits, unused imports, etc.) removed.
- [ ] Every `<pre>` has room for a copy button (no flex that breaks the
  button's absolute positioning).

## Typography

- [ ] Body font serif, chrome sans, code mono (family ordering).
- [ ] Hanging punctuation on `body`.
- [ ] `text-wrap: pretty` + orphans/widows on body; `balance` on h2/h3;
  EXPLICITLY `wrap` (not balance) on the animated h1.
- [ ] Drop cap on first body paragraph of each chapter via
  `chapter-opener` class.
- [ ] Small caps on: eyebrow, chapter-number, goal-label, checkpoint-label,
  toc-heading, concept labels. Via `font-feature-settings: "smcp" 1, "c2sc" 1`.
- [ ] Em-dash list markers on in-chapter prose lists (not the TOC or the
  cheatsheet glossary, which have their own styling).

## Color

- [ ] Light mode: warm cream body `#faf8f3`, dark `#1a1a1a` text, accent
  `#a14a2a` used sparingly.
- [ ] Code blocks: dark chalkboard `#5a4e30` bg with bright token palette
  in both modes.
- [ ] Diagram palette matches: cream-box fills for neutral, amber-cream
  for accent/highlighted, rust-accent stroke for emphasis.
- [ ] Dark mode overrides exist for every `--*` token.

## Product features

- [ ] Copy buttons on every `<pre>`, fade-in on hover.
- [ ] Glossary tooltips annotate both inline `<code>` in prose AND token
  spans in highlighted code.
- [ ] Glossary definitions are exactly two sentences each.
- [ ] External links get the dashed underline + destination tooltip, NO
  `↗` prefix.
- [ ] If the title is animated: blinking cursor via CSS animation (not
  JS), `text-wrap: wrap` (not balance), `min-height: 2.1em` reserved,
  non-breaking space before the final word.
- [ ] Sticky chapter nav appears after hero, has prev/current/next and
  a thin progress bar.
- [ ] If a screenshot harness exists: screenshots regenerable via a single
  command.
- [ ] If pedagogical diagrams exist: each sits BEFORE the code it explains,
  not after. Each has a `<figcaption>`.

## Accessibility

- [ ] All images have `alt` text that describes content, not function.
- [ ] Animated title has the full text as `aria-label` on the h1; animated
  span is `aria-hidden="true"`.
- [ ] Keyboard focus (Tab key) reaches all interactive elements (speak
  buttons, copy buttons, tap-to-toggle glossary terms).
- [ ] Focus states are visible.
- [ ] Video elements are `muted` so autoplay on hover works without being
  blocked.
- [ ] Touch / no-hover devices get graceful degradation (hover popovers
  hidden, tooltips work on tap).

## Performance

- [ ] Images below the fold use `loading="lazy"`.
- [ ] Decorative illustrations are WebP (or similarly optimized) and sized
  appropriately for their display size (not 2000×2000 at 400px).
- [ ] Hover video URL is only set on first hover, not eager-loaded.
- [ ] No cache-busting meta tag (`<meta http-equiv="Cache-Control" ...>`)
  in production — that tag is OK in dev but must be removed or weakened
  before shipping.

## SEO / social

- [ ] `<meta name="description">` present.
- [ ] Open Graph tags: `og:title`, `og:description`, `og:image`, `og:url`,
  `og:type="article"`.
- [ ] Twitter Card tags.
- [ ] Canonical URL.
- [ ] Favicon.
- [ ] `<html lang="…">` set correctly.

## Checkpoints

- [ ] Every chapter's final element is a "Where we are" checkpoint.
- [ ] No chapter's checkpoint says "In this chapter we…" or "You've now
  learned…"
- [ ] The final chapter's closing paragraph calls back the hero's promise
  by naming the same N ingredients.

## Fit-and-finish

- [ ] No TODOs, placeholders, or lorem ipsum in the shipped file.
- [ ] Every `href` resolves.
- [ ] Every image loads.
- [ ] Dark-mode rendering checked as well as light-mode.
- [ ] Mobile rendering (375px wide) checked; no horizontal overflow.
