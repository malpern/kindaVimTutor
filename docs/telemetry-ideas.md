# Telemetry & LLM-Powered Learning Ideas

## What We Capture

Each drill session records a complete event-sourced log:
- Timestamped events (textChanged, cursorMoved, repStarted/Completed/Reset)
- Full text state and cursor position at every event
- Per-rep timing, keystroke counts, and variation data
- Accumulated across all reps in a drill

## Real-Time Feedback (During Exercise)

### Error Detection
- **Wrong motion used**: Text changes when only cursor should move (e.g., user typed `j` in insert mode instead of normal mode). LLM can detect this pattern and prompt "Are you in Normal mode?"
- **Overshoot detection**: Cursor passes the target then reverses. Indicates the user isn't counting or planning their motion. Feedback: "Try counting the lines before pressing j"
- **Hesitation patterns**: Long pauses (>3s) between events suggest uncertainty. Could offer a contextual hint without the user asking.
- **Repeated undo**: Multiple reversals suggest trial-and-error rather than intentional movement. LLM can suggest: "Instead of guessing, try counting: 4j moves down exactly 4 lines"

### Motion Suggestions
- After completion, LLM analyzes the keystroke sequence and suggests more efficient alternatives: "You used 8 keystrokes. Try `4j` instead of `j j j j` — it does the same thing in 2 keystrokes."
- Context-aware suggestions based on what motions the user has learned so far (don't suggest `w` if they haven't learned it yet)

### Fluency Assessment
- Track rep completion times across a drill. Decreasing times = building muscle memory. Flat or increasing = struggling.
- Compare time variance: consistent times suggest automaticity, high variance suggests conscious thinking
- Cross-session comparison: "Your average j time improved from 2.3s to 0.8s over the last 3 sessions"

## Post-Session Analysis

### Learning Progress Reports
- "You've mastered h/j/k/l — your average rep time is under 1s with no errors"
- "You're still hesitating with $ (end of line) — consider more practice"
- Identify which motions transfer well (e.g., if someone learns `w` quickly after mastering `l`, they understand word-level movement)

### Adaptive Difficulty
- If a user completes 5 reps quickly with 0 errors, skip to harder variations or increase drill count
- If a user is struggling (many resets, high keystroke count), reduce drill count to 3 and offer simpler variations
- Dynamically generate new variations based on the user's weak patterns

### Spaced Repetition
- Track when each motion was last practiced and how well
- Suggest review drills for motions that are decaying (haven't been practiced in X days)
- Priority queue: motions with high error rates get scheduled more frequently

## Cross-User Insights (Aggregate, Anonymized)

### Curriculum Optimization
- Which exercises have the highest error/reset rates? Those need better instruction or easier initial variations.
- Which motions are hardest to learn? Adjust lesson ordering.
- Where do users drop off? Those lessons may be too hard or boring.

### Common Error Taxonomies
- Build a catalog of common mistakes per motion (e.g., "52% of users try arrow keys before remembering hjkl")
- Use this to write better hints and anticipatory guidance

## Technical Integration Points

### LLM Analysis API
- Send DrillSession JSON to Claude API with a system prompt describing the exercise context
- Ask for: error analysis, efficiency suggestions, fluency assessment
- Cache analysis results per session to avoid re-processing

### Live Streaming (Future)
- Instead of post-hoc analysis, stream events to an LLM in real-time
- LLM watches the event stream and can interrupt with feedback: "I notice you keep overshooting — try pressing j more slowly and counting"
- Requires low-latency API or local model

### Replay Visualization
- Render a session replay showing the text editor state changing over time
- Overlay the "optimal" path alongside the user's actual path
- Could be shown as a post-drill review or shared with a tutor
