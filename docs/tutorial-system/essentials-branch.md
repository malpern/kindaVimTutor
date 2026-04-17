# The Essentials Branch

Before you write a tutorial about a real codebase, strip the codebase down
to the essentials that the tutorial will actually teach — on a branch, not
on main. This is the single most effective pre-step in the system.

## The rule

**Create a new `Tutorial` branch before you touch anything.**

This is non-negotiable. The process must be non-destructive. Every deletion,
every rename, every simplification happens on the branch. The main branch
stays exactly as it was. If the tutorial effort is abandoned, the branch is
abandoned — no harm done.

```bash
git checkout -b Tutorial
```

Not "strip first, branch later." Not "make a stash." Branch first, then
strip.

## Why strip at all

Real codebases accumulate: a second persistence path a past contributor
added, an unused preference toggle, three overlapping state objects that
each handle 20% of the same concern, a feature flag gating code that never
shipped. Tutorials that document *that* are unteachable — the reader is
asked to hold too much in their head, and the author ends up apologizing
for incidental complexity in every chapter.

Strip until every file in the repo is a file the tutorial will teach. If
a file doesn't appear in the tutorial, either it belongs to the tutorial
(you missed it) or it doesn't belong in the essentials (delete it on the
branch).

The goal: a codebase where the reader, handed the final artifact, can
point at any file and say "yes, that's from chapter N."

## What to strip

- **Unused code paths.** If two implementations exist and the tutorial only
  teaches one, delete the other.
- **Feature flags for unshipped features.** The flag, the gated code,
  the branch in config.
- **Dead tests** — tests for removed code, tests that were skipped and
  forgotten.
- **Compatibility shims** for platform/library versions the tutorial won't
  discuss.
- **Scratch files, commented-out blocks, `TODO:` markers** from long-gone
  refactors.
- **"Clever" abstractions that earn nothing.** If a protocol has one
  implementation and the tutorial only teaches that implementation, inline
  it.
- **Redundant configuration.** Three build configs when the tutorial teaches
  one.

## What to keep

- Every file that appears in a chapter.
- Every dependency the artifact actually uses at runtime.
- Real-world error handling that would be missed if absent (don't
  simplify away the teaching).
- Tests for the code the tutorial teaches.

## Process

1. **Branch.** `git checkout -b Tutorial`. Confirm you're on it.
2. **Draft the chapter outline first.** You can't know what's essential
   until you know what you're teaching.
3. **Walk the repo file by file.** For each file, ask: "will this appear
   in a chapter?" If no, mark for deletion. If yes but only partially,
   mark for simplification.
4. **Delete, then compile.** Aggressive first pass. Restore the minimum
   needed to get the build green again.
5. **Run the real app.** The stripped artifact must still work end-to-end.
   A simplified codebase that no longer runs is not teachable.
6. **Commit the strip as a single commit** with a message like
   `Strip to essentials for tutorial`. This makes the diff against main
   legible — anyone reviewing can see exactly what the tutorial will and
   won't cover.
7. **Now write the tutorial** against the stripped codebase.

## When NOT to strip

- The codebase is already minimal (under ~1000 lines, every file pulls
  its weight). Skip straight to writing.
- The tutorial is *about* the complexity — e.g., a case study of a real
  production system's trade-offs. Stripping defeats the purpose.
- The user has explicitly said they want the tutorial to cover the full
  existing surface area.

When in doubt, ask the user: "Do you want me to propose an essentials
strip on a `Tutorial` branch before writing, or write against the current
codebase?"

## Relationship to main

After the tutorial ships, the `Tutorial` branch is typically kept as a
reference — a permanent "teachable snapshot" — not merged back to main.
Main continues to evolve; the tutorial branch stays frozen at the version
the tutorial documents.

If main diverges significantly later, you have two options:
1. Regenerate the tutorial against a new essentials branch cut from the
   current main.
2. Update the existing tutorial in place, cherry-picking relevant changes
   from main into the Tutorial branch.

Either works. The branch stays authoritative for the tutorial; main stays
authoritative for the product.
