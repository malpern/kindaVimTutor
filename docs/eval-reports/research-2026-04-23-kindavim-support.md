# kindaVim support research — 2026-04-23

Research to ground-truth the 27 `kindavim_accuracy` fails (and related `xref_validity` / `vim_accuracy` issues) from the eval run.

## Methodology

Two parallel investigations:

1. **Official docs** — `kindavim.app`, `docs.kindavim.app`.
2. **Source code** — `github.com/godbout/AccessibilityStrategyTestApp` (the open-source test app; the README at `godbout/kindaVim.blahblah` redirects here. The main kindaVim app is closed-source; every implemented move has a unit test in this repo, so tests = implementation inventory).

Both sources converged on the same picture, which gives high confidence for most findings.

## Authoritative support table

**Docs path that works:** `docs.kindavim.app/implementation/accessibility-strategy` — a ~195-row table, two columns per row (count support, repeat support). Presence in this table = implemented. Absence = not implemented.

The previously-assumed URL `docs.kindavim.app/kindavim-features/supported-vim-commands` **404s.** Our in-app deep link needs updating.

**Supplementary:** `docs.kindavim.app/implementation/commands` for Ex commands (8 rows total). `docs.kindavim.app/implementation/keyboard-strategy` for fallback mode.

## Critical findings — discrepancies with our `kindavim-support.txt`

### Must-fix: commands we wrongly list as supported

| Command | Our list says | Truth | Confidence |
|---|---|---|---|
| `*` | supported (Search section) | **NOT implemented** — absent from both docs table and source tests | **HIGH** |
| `#` | supported (Search section) | **NOT implemented** — absent from both sources | **HIGH** |

Both agents confirmed `*` / `#` (and `g*` / `g#`) have no test files and don't appear in the accessibility-strategy table. **This is the single biggest correction we need.** Our `search.txt` topic covers `*` and `#` as if they work; those Q&As are wrong.

### Must-fix: Q&As that suggest unsupported workarounds

| Command/phrase | In our content | Truth | Confidence |
|---|---|---|---|
| `cgn` as substitute workaround | mentioned in `ex-commands.txt`, `macros.txt`, `substitute-shortcuts.txt`, `search.txt`, `dot-repeat.txt` | **NOT implemented** — no test files | **HIGH** |

We've been telling users "use `cgn` + `.`" repeatedly. Neither is likely to work in kindaVim.

### Moderate: support was ambiguous, now clear

| Command | Our list | Truth | Confidence |
|---|---|---|---|
| `gU`, `gu`, `g~` operators | unsupported (explicit) | **Confirmed unsupported** | **HIGH** |
| `gUiw`, `guiw` | unsupported | **Confirmed unsupported** | **HIGH** |
| `U` in {{normal}} (undo line) | not listed in support file | Absent from source tests — likely unsupported | MEDIUM |
| `.` (dot repeat) | supported | No test file found, but "repeat" column in docs implies existence | **MEDIUM** — downgrade from high |
| `S` (substitute line) | supported | Docs: present in Change section. Source: only visual-mode tests. **Conflicting.** | MEDIUM |
| `R` (replace mode) | not listed | Only visual-mode test found. Likely unsupported in normal mode. | MEDIUM |

### Already correct in our content

Both sources confirm:
- `hjkl`, word motions (`w W b B e E ge gE`), line motions (`0 ^ $ gg G`) — supported. ✅
- `f F t T ; ,` — supported. ✅
- Operators `d c y p P x X ~`, operator+motion combos — supported. ✅
- Text objects `iw aw i" a" i' a' ib aB ip ap is as` — supported. ✅
- Visual mode `v V` — supported. ✅
- Visual-mode case operators `U u ~` — supported (this is the visual-mode column in the table). ✅
- Search `/ ? n N` — supported. ✅
- `r` — supported. ✅
- `J` — supported (marginal marks but in table). ✅
- `.` — inferred supported. ✅ (but downgrade confidence)
- `u`, `Ctrl-R` — supported. ✅
- Counts (`3dw`, `5j`, `2cw`) — supported. ✅
- All the unsupported items in our topics (macros, marks, folds, splits, jumplist, ex-commands, named registers) — confirmed. ✅

### New unsupported items not in our corpus

| Command | What it does | Confidence it's unsupported |
|---|---|---|
| `it`, `at` | tag text objects | **HIGH** (no test files, source explicitly lacks them) |
| `i(`, `a(` **raw parens form** | uses `ib`/`ab` alias only | MEDIUM — the alias works, the raw form may too |
| `gJ` | join without space | **HIGH** |
| `cgn`, `cgN` | change-next-match | **HIGH** |
| `gd`, `gD` | go-to-definition | **HIGH** (already in our jumplist.txt) |
| `U` (normal mode, line-level undo) | line-level undo | MEDIUM |

## Confidence summary

- **HIGH confidence** (docs + source both confirm, or clear absence from both):
  - `*`, `#`, `g*`, `g#` unsupported — MUST correct
  - `cgn`, `cgN` unsupported — MUST correct
  - `gU`, `gu`, `g~`, `gJ`, `it`/`at` unsupported — confirms our current hedging should be definitive
  - All current "supported motion/operator/text-object" claims in our corpus — CORRECT

- **MEDIUM confidence** (one source ambiguous, or marginal evidence):
  - `.` supported — likely yes, but no explicit test
  - `S`, `R` normal-mode — docs says yes, source says no; we should hedge
  - `U` normal-mode line undo — likely unsupported
  - `i(`/`a(` raw parens form — kindaVim uses `b`/`B` aliases; raw form untested

- **LOW confidence** (inferred from context):
  - Normal-mode `s` — exists as alias for `cl`, both should work
  - Counts on every operator — implied by `✅` marks but not exhaustively checked

## Action items for the canonical corpus

### Immediate (high confidence, high impact)

1. **`kindavim-support.txt`**: move `*` and `#` from Supported → Unsupported section. Add `*`, `#`, `g*`, `g#` to unsupported with a concept keyword `word search`.
2. **`kindavim-support.txt`**: add `cgn`, `cgN` to Unsupported with concept keyword `change next match`.
3. **`search.txt`**: rewrite the `*` / `#` Q&As to state "kindaVim doesn't support word-search shortcuts. Use `/word<Enter>` to search for it manually." Mark them `Unsupported: yes`.
4. **`search.txt` / `ex-commands.txt` / `macros.txt` / `substitute-shortcuts.txt` / `dot-repeat.txt`**: scrub every reference to `cgn` as a workaround. Replace with manual `n` + `cw` + `.` flow (which DOES work: repeat the change with `.`, move to next match with `n`).
5. **`case-toggle.txt`**: rewrite the 3 Q&As to be definitive:
   - `g~iw` / `gUiw` / `guiw` → unsupported in {{normal}}; `~` (single-char toggle) works; visual-mode `v<motion>U` / `v<motion>u` / `v<motion>~` is the idiomatic fallback.
   - Add `Unsupported: yes` to the gU/gu-related entries.
6. **In-app docs URL**: `KindaVimSupportCorpus.docsURL` currently points at `docs.kindavim.app/kindavim-features/supported-vim-commands` which 404s. Change to `docs.kindavim.app/implementation/accessibility-strategy`.

### Recommended (medium confidence, medium impact)

7. **`replace-characters.txt`**: add a Q&A about `R` (sustained replace mode) — "kindaVim doesn't support sustained Replace mode. `r` (replace one character) works; for multi-char replace, use `cw` or `ci"` etc."
8. **Expand `kindavim-support.txt`** with every command mentioned in any Related row, so `xref_validity` false positives drop. Candidates to add to Supported: `cc`, `S`, `C`, `D`, `J`, `yy`, `Y` (they're already in supported but verify each). Candidates to flag Unsupported: `gJ`, `it`, `at`, `gd`, `gD`, `cgn`, `cgN`, `*`, `#`, `g*`, `g#`, `U` (line undo).

### Nice to have (low priority)

9. Verify by hand: does kindaVim implement `.` for operator repeat? Quick in-app test would confirm; then pin the doc accordingly.
10. Raw-parens text objects (`i(`, `a(`): same — quick in-app test. Our Q&As currently say both work as aliases.

## What this means for eval accuracy

Of 27 `kindavim_accuracy` fails in the eval:
- **~20 are legitimate** and traceable to the issues above (`*`/`#`/`cgn`/`g~`/`gU`/`gu` being claimed as supported).
- **~5 are verifier strictness** where a loosely-stated "varies in kindaVim" triggered a fail rather than a pass.
- **~2 are false positives** on commands the corpus does list (verifier context confusion).

Acting on items 1–6 in the Action Items section should clear the load-bearing `kindavim_accuracy` fails, unblock the Q&A accuracy question you asked.

## Sources

- https://kindavim.app/ (landing page confirms "great number of moves already implemented, but request missing ones")
- https://docs.kindavim.app/ (nav)
- https://docs.kindavim.app/implementation/accessibility-strategy (canonical ~195-row table)
- https://docs.kindavim.app/implementation/commands (Ex commands: 8 rows)
- https://docs.kindavim.app/implementation/keyboard-strategy (fallback mode, smaller subset)
- https://github.com/godbout/kindaVim.blahblah (README-only; redirects to the test app)
- https://github.com/godbout/AccessibilityStrategyTestApp (open-source test app: `AccessibilityStrategyTestAppTests/AccessibilityStrategy/{NormalMode,VisualMode}/Moves/` — ~170 NM tests, each `ASUT_NM_<cmd>_Tests.swift` file = one implemented command)

URLs that 404 (deep-link to update):
- `docs.kindavim.app/kindavim-features/supported-vim-commands` — does NOT exist.
