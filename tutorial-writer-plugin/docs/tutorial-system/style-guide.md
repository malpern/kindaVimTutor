# Style Guide

The voice, typography, and sentence-level patterns. Grounded in concrete
rewrites, not abstract advice.

## Voice

### Target
- Warm, direct, slightly dry.
- "Knowledgeable friend walking a beginner through their first real project."
- Occasionally first-person, never chummy.
- Confident but never condescending.

### Sentence shape
- **Short sentences carry the structure.** ("This runs.")
- **Longer sentences carry the reasoning.** Use em-dashes and semicolons
  rather than breaking into staccato.
- Alternate. Three short sentences in a row reads choppy; three long ones
  reads like a lecture.

### Rewrites

| Spec-sheet | Situated |
|---|---|
| "A vertical stack with four lines. Chapter label, lesson title, subtitle, and a monospaced row of any new motions the lesson introduces." | "Here's what the user sees when they open a lesson: a quiet chapter label overhead, the lesson's title in confident bold, a supporting subtitle, and — when the lesson introduces new motions — a row of them in monospaced type, so the eye catches which keys are about to be practiced. Four lines, each doing one job, none competing." |
| "SwiftUI's List with .listStyle(.sidebar) is the native macOS sidebar. Correct padding, background, collapse behavior — all for free." | "Every lesson in the tutor has to be pickable. On macOS the canonical 'list of things to pick from' has one shape — the left-hand sidebar you see in Mail, Finder, Xcode. SwiftUI bakes that shape in. We just fill in the rows." |
| "You don't need a database. A stable directory, a Codable type, and an atomic file write is the whole recipe." | "At the end of a drill the user has done something real — typed, retyped, earned a rep. If we lose that when they quit, the tutor feels dismissive. So we save. Not to a database, not to a server — to a small JSON file in Application Support." |

Pattern: the rewrite names what the *user* sees, feels, or needs before
naming the code.

## Typography

### Families
- **Body**: serif. Prefer `"New York", "Iowan Old Style", "Charter", Georgia`.
- **Chrome**: sans. Prefer `-apple-system, BlinkMacSystemFont, "SF Pro Text"`.
- **Code**: mono. Prefer `"SF Mono", "JetBrains Mono", ui-monospace, Menlo`.
- **Title (display)**: same serif as body; larger + tighter letter-spacing.

### Sizes and leading
- Body: 19px, line-height 1.72.
- H1 title: `clamp(48px, 7vw, 80px)`, letter-spacing -0.035em, line-height 1.05.
- H2 chapter: `clamp(34px, 4.5vw, 46px)`, letter-spacing -0.025em.
- Subtitle (deck): 22–28px italic, muted color.
- Eyebrow / label: 13px sans, 0.14em tracking, uppercase, small-caps via
  `font-feature-settings: "smcp" 1, "c2sc" 1`.

### Microtypography
- `hanging-punctuation: first last` on `body` — quotation marks at paragraph
  starts align optically outside the column.
- `text-wrap: pretty; orphans: 3; widows: 3;` on body copy.
- `text-wrap: balance` on headings **except the typewriter-animated title**
  (balance rebalances on every character append — replace with plain `wrap`
  there).
- Drop cap on the first body paragraph of each chapter: use
  `initial-letter: 3 2` with a `::first-letter` fallback. Color it with the
  accent.
- Em-dash markers on in-chapter prose lists:
  ```css
  .chapter > ul > li::marker { content: "—  "; color: var(--fg-quiet); }
  ```

### Color palette

Light mode (paper):
- `--bg: #faf8f3` — page
- `--paper: #ffffff` — raised cards
- `--fg: #1a1a1a` — default text
- `--fg-muted: #6e6e73` — deck, captions
- `--fg-quiet: #9a9a9a` — marker, dividers
- `--rule: #e8e4d8` — thin borders
- `--accent: #a14a2a` — rust, used sparingly

Dark mode (inverted):
- `--bg: #1a1818`, `--fg: #ece8e0`, `--accent: #e88c5e`

Code blocks ("chalkboard") — same in both modes:
- bg `#5a4e30`, fg `#ece8e0`
- Token palette: keywords `#ff9a6c` bold, types `#f0c878` bold, functions
  `#7bb8e8` bold, strings `#b8db92`, numbers/enum cases `#e095b8`,
  comments `#a8a290` italic, punctuation `#d8d4cc`.

## Formatting

### Chapter openings
Start with one of:
1. A lived observation. ("The first prototype had a scrolling page. It
   worked, and it didn't feel like Vim.")
2. A user-need statement. ("Every lesson in the tutor has to be pickable.")
3. A quietly contrarian claim. ("You don't need a database.")

Avoid:
- "In this chapter we'll…"
- "Let's now look at…"
- "As we saw in chapter 4…"

### Transitions between code blocks
Pattern:
> [one-sentence why] [optional: what to notice] [colon or period]  
> `<pre><code>`

Example:
> "The validation rule, in one line: *current text equals `expectedText` and
> current cursor equals `expectedCursorPosition` (if set)*."

### Checkpoints

Every chapter ends with:

```html
<div class="checkpoint">
  <p class="checkpoint-label">Where we are</p>
  <p>One italic sentence describing what works now.</p>
</div>
```

Tight. "A working lesson flow. Pick a lesson, press `l` to advance, press
`h` to go back." Not "In this chapter we have completed…"

## Callouts

### `aside.concept` — a concept introduced inline

Structure:
```html
<aside class="concept">
  <span class="label">@Observable</span>
  <p>One paragraph. What it is, then why it matters here.</p>
</aside>
```

Use when:
- A term deserves a paragraph of context, not just a tooltip.
- The flow won't tolerate the inline prose expansion.

Don't use when:
- A one-line hover tooltip suffices.
- You've already used two concept callouts in the same chapter (readers stop
  noticing the third).

### Pull quote

```html
<blockquote>
  A memorable sentence that names a principle.
</blockquote>
```

Use at most once per chapter, only for a line the reader should quote back.
The five-principles pull quote at the end of the final chapter is a model.

## Code blocks

- Language-tagged: `<pre><code class="language-swift">` (or `language-bash`).
- First code block of each file: followed by a `<p class="code-caption">` with
  the file path (e.g., `Sources/KindaVimTutorKit/Models/Lesson.swift`).
- Long methods: show a struct outline, `// ...` the body, then expand later
  if needed. Don't dump 40 lines when 10 tell the story.
- Remove boilerplate that doesn't teach (`super.init`, unused imports, empty
  inits that Swift synthesizes).

## External links

Auto-annotated with a subtle dashed accent underline and a hover tooltip
revealing the destination ("Apple Developer", "Hacking with Swift", etc.).
No `↗` prefix — the underline carries the affordance.

Internal anchor links: plain underlined accent.

## Don't

- Don't use emoji in prose.
- Don't use exclamation points.
- Don't use "simply" or "just" or "obviously."
- Don't write summaries ("In this chapter we learned…").
- Don't apologize ("You might be wondering why…").
- Don't write Q&A sections — if a question deserves an answer, rewrite the
  preceding paragraph so the reader doesn't ask it.
