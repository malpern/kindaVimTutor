# Explanation Patterns

Concrete, reusable moves for introducing concepts, transitioning between
code blocks, handling tradeoffs, and closing loops.

## Pattern 1 — User → decision → code

The core rhythm of every explanation in the system.

### Structure

1. One sentence naming what the user experiences, feels, or needs.
2. One sentence (or clause) naming the design decision we're making.
3. The code.

### Example

> "Every lesson in the tutor has to be pickable. On macOS the canonical 'list
> of things to pick from' has one shape — the left-hand sidebar you see in
> Mail, Finder, Xcode. SwiftUI bakes that shape in: `List` with
> `.listStyle(.sidebar)` gives us the padding, the background, the collapse
> behavior, the hover tinting, and the keyboard focus ring, all for free.
> We just fill in the rows."
>
> ```swift
> List(selection: $selectedLessonId) { … }
> ```

Notice: "user need → canonical pattern for this domain → specific API → code."

### When to skip

- The previous paragraph already did the user-grounding. Don't repeat.
- The code is a trivial helper (a getter, a two-line conversion). Just show
  it.

## Pattern 2 — Wrong way first

For any non-trivial extracted abstraction.

### Structure

1. "What happens if we don't" `<h3>` header.
2. A short code example showing the tempting, naive version (logic inside
   a view, state scattered across `@State`, etc.).
3. One paragraph describing the friction: what starts working, what
   breaks, what's painful to evolve.
4. The extract: `<h3>The extract</h3>` (or similar), then the real code.

### Example (from Ch7 of the exemplar)

```swift
// Wrong way
struct DrillStepView: View {
    @State private var currentText = ""
    @State private var keystrokes = 0
    @State private var completedReps = 0
    var body: some View {
        ExerciseEditorView(/* ... */)
            .onChange(of: currentText) {
                keystrokes += 1
                if currentText == exercise.expectedText { /* ... */ }
            }
    }
}
```

> "It works. Then you add timing, then rotating variations, then a 'reset
> the current rep' button, then a guard against `onChange` firing after the
> view disappeared. Each requirement jams another branch into the same
> closure. The validation rule now lives in three `if`s across two files.
> You can't test any of it without spinning up a view."

Then the extraction. The reader remembers the *relief* of extraction.

### When to use

- Introducing a state machine, service, store, controller.
- Explaining why a pattern (MVVM, unidirectional flow, etc.) pays off.
- Any moment a reader might think "couldn't this just live in the view?"

### When to skip

- A pure-data chapter (Ch2 in exemplar) — no logic to misplace.
- Introducing framework APIs that don't have a "naive" alternative.

## Pattern 3 — Pull quote for the load-bearing line

One per chapter, maximum, only for lines you'd want the reader to tweet.

### Structure

```html
<blockquote>
  A line the reader will quote back. First-person is fine here.
</blockquote>
```

### Examples

> "A rep of a drill is done when *current text equals expectedText and
> current cursor equals expectedCursorPosition*. That's the whole rule. The
> engine will run it on every keystroke."

> "A good test of this kind of split: if you can write a meaningful test
> for the logic class without importing SwiftUI, the separation is right.
> If the test needs to build a view, the logic leaked."

### Placement

Usually mid-chapter, after the code has been shown, as the reader's
satisfaction crests. Not at the top (they haven't earned the principle
yet) and not at the bottom (the checkpoint is the last beat).

## Pattern 4 — Concept callout (`aside.concept`)

For a term that deserves a paragraph — not a hover tooltip, not an inline
parenthetical.

### Structure

```html
<aside class="concept">
  <span class="label">@Observable</span>
  <p>A Swift 5.9+ macro (Observation framework) that makes a plain class
  trackable by SwiftUI. You don't annotate properties or write @Published.
  Change selectedLessonId and the sidebar re-renders; change something else
  and it doesn't.</p>
</aside>
```

### Rules

- Max 2 callouts per chapter. The third one gets ignored.
- Label is small-caps via font-feature-settings.
- Body is one paragraph. If it wants to be two, the paragraph breaks out
  of the callout's tight visual idiom.
- Use for: a macro or attribute's full semantics; a system boundary
  explanation (e.g. "The Representable contract"); a gotcha that has
  implications beyond this one chapter.

## Pattern 5 — Diagram before dense code

When the code is structural (enums with many cases, a state machine, a data
model, a sequence of calls), a small inline SVG diagram sits *before* the
code, not after. WWDC-native.

See `implementation-patterns.md` → "Pedagogical diagrams" for the shared
SVG style and palette.

### When

- Data model chapter: composition tree.
- State-lift chapter: source-of-truth triangle.
- Presentation transformation (lesson → steps): flatMap-style before/after.
- State machine: node+transition diagram.
- Data flow / sequence: left-to-right boxes with arrows.

### When not

- View layout examples — the code's shape IS the diagram.
- Any chapter where the prose already does the work.

## Pattern 6 — End-of-tutorial trace

The closing chapter earns its weight with a full trace of one meaningful
event — from user input through every layer to the final side effect.

### Structure

1. A short intro: "One final [event], at a glance:"
2. A sequence diagram (if structural) OR a numbered list.
3. One paragraph reflecting on what was NOT wired manually — the
   observation / reactive / declarative win.

### Example

The keystroke trace in the exemplar's Ch9:
`NSTextView → Coordinator → Engine → ProgressStore → disk / Sidebar ✓`

## Pattern 7 — The closing checkpoint

Every chapter. Single italic sentence. Present-tense. Describes the
artifact's state, not what the reader "learned."

Good:
> "A working lesson flow. Pick a lesson, press `l` to advance, press `h`
> to go back. Title, content, and (stub) drill slides in sequence. The
> drill itself doesn't do anything yet — but the scaffolding's ready."

Bad:
> "In this chapter we covered the step-based lesson flow, the
> LessonStepController, and keyboard navigation."

## Pattern 8 — The inline parenthetical

When a subtlety wants exactly one sentence of context, use an em-dash
aside or parenthetical *inside the flow*, not a callout.

> "Setting `textView.string = ...` triggers the `textDidChange` delegate
> callback — which would bubble back into the engine as a phantom
> keystroke."

> "The directory may not exist on first launch (always
> `createDirectory(at:withIntermediateDirectories: true)` before
> writing.)"

These are the most common asides. Callouts are for things that want more
space.

## Anti-patterns

### "Let me explain"
Don't. Explain.

### "As you can see"
The reader can see. Don't announce what's visible.

### "We'll get to that later"
Either get to it now or don't raise it. Forward references erode trust.

### Listy code explanations
After showing a 20-line class, don't itemize every field in prose:

> ~~"The class has a `state` property, a `keystrokeCount` property, a
> `completedReps` property, a `currentVariation` property…"~~

Pick the 2–3 that matter and explain those. The reader can read code.

### "In this section…"
Dead weight. Start with an observation or a user need.
