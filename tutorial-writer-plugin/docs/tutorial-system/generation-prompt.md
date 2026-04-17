# Generation Prompt

Paste this prompt (filled out with your topic) to an agent to produce a new
tutorial in this system's style.

---

You are producing a long-form technical tutorial in the style of the
kindaVim Tutor walkthrough (which you can read at
`docs/tutorial.html` if available). Follow the system documented in
`docs/tutorial-system/` — specifically:

- `principles.md` for what matters
- `style-guide.md` for voice and typography
- `tutorial-blueprint.md` for document structure
- `explanation-patterns.md` for how to introduce concepts
- `implementation-patterns.md` for product features
- `workflow.md` for end-to-end steps

Do not improvise outside this system. If something is ambiguous, pick the
option that best matches the exemplar.

## Fill in these inputs

- **Topic**: [e.g., "Building a macOS menu-bar Pomodoro app in SwiftUI"]
- **Artifact**: [e.g., "A ~500-line SwiftUI menu-bar app that keeps state across launches and uses AppleScript to automate Focus modes"]
- **Audience**: [e.g., "Developers fluent in Swift basics but new to macOS menu-bar apps and AppleScript"]
- **Chapter count target**: [e.g., "7 chapters"]
- **Five ingredients the reader will write**: [e.g., "a menu bar extra, a timer state machine, keyboard shortcut registration, AppleScript-via-NSAppleScript, and a small JSON preferences store"]
- **Illustration metaphor**: [e.g., "blueprint sketches of clocks, from a sundial to a chronometer"]
- **Demo video URL (if any)**: [e.g., `https://example.com/demo.mp4`]

## Procedure

1. Produce the hero subtitle — the promise. Iterate until it's ≤60 words,
   names the starting point + artifact + five ingredients + meta-claim.

2. Produce the chapter outline. Feature-named titles. One-sentence blurb
   per chapter. Get sign-off before proceeding.

3. For each chapter in order:
   a. Goal-panel sentence.
   b. Chapter-opener paragraph using one of the three patterns.
   c. Body alternating prose and code, grounded in User → Decision → Code.
   d. At least one chapter uses the "wrong way first" pattern.
   e. Checkpoint ("Where we are" + one italic sentence).

4. Generate chapter illustrations using `nano-banana` (or equivalent):
   - One per chapter.
   - Progressive fidelity (abstract → detailed).
   - Shared visual vocabulary from the illustration metaphor.
   - Prompt pattern:
     > "Hand-drawn [medium] sketch on [surface]. [SUBJECT] rendered as
     > [STAGE]. [INFLUENCE]. Raw visible [medium] grain. No background,
     > no text. [COLOR] on [paper]. Landscape."

5. Write the cheatsheet (five principles + annotations grid) and the
   Resources bulleted list.

6. Emit a single HTML file (`docs/tutorial.html`) with inline CSS + JS
   following the exemplar's shape. Include:
   - Shiki syntax highlighting with the chalkboard theme
   - Copy buttons on `<pre>` blocks
   - Glossary tooltips with two-sentence definitions
   - External link annotation
   - Sticky chapter nav
   - Section rules between chapters
   - [Optional, if it fits the tone] animated typewriter title
   - [Optional, if a demo video URL was supplied] hover-to-play video on
     the external product link

7. If the topic has a UI: emit a `Scripts/capture-screenshots.sh` plus a
   launch-argument harness suggestion for the app, so screenshots are
   regenerable.

8. Run the `review-checklist.md` against the draft. Fix anything that
   doesn't pass.

## Do not

- Do not use em-dashes inside code blocks (they're easy to over-apply).
- Do not invent facts about the domain — if you need details, ask.
- Do not ship a chapter that has no code (except Chapter 1).
- Do not write a "Summary" or "Conclusion" chapter — the cheatsheet IS
  the summary.
- Do not inline arbitrary HTML for things the component CSS handles
  (goal panels, checkpoints, callouts) — use the proper classes.

## Do

- Trust the reader.
- Cut anything that doesn't advance the narrative, introduce a decision,
  or set up a code block.
- Write the promise like copy. Polish the subtitle obsessively.
- If you're bored writing a paragraph, the reader will be bored reading
  it — rewrite.
