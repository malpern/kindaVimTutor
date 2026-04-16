# Curriculum Comparison: vimtutor vs Vimified vs kindaVim Tutor (Proposed)

## kindaVim Supported Features (Accessibility Strategy)

**Navigation:** h j k l, w b e, W B E, ge gE, f F t T, 0 $ ^, gg G, H, g0 g$ gj gk, ; ,, n N
**Editing:** x X, d (dw de d$ dd dG dgg df dt dF dT dB db dW dE), c (cw ce c$ cc cG cgg cf ct cF cT ch cW cE), r, ~, < >, p P, o O, i I, a A, s S, R, u U, Y y yy yf yt yF yT
**Visual:** v, V
**NOT supported:** macros, `:` commands, `/` search entry, `.` dot command, `%` bracket match, `Ctrl-U/D/B/F` scroll, text objects (iw, aw, i", etc.), `J` join lines, `Ctrl-A/X` increment/decrement

## Comparison Table

| Command/Concept | vimtutor | Vimified | kindaVim supports? | Proposed (ours) |
|---|---|---|---|---|
| **CHAPTER 1: BASICS** |
| h j k l movement | 1.1 | Ch1 L1-2 | ✅ | Ch1 L1 |
| x delete char | 1.3 | — | ✅ | Ch1 L2 |
| i insert | 1.4 | Ch4 L5 | ✅ | Ch1 L3 |
| A append EOL | 1.5 | Ch4 L6 | ✅ | Ch1 L4 |
| u undo | 2.7 | — | ✅ | Ch1 L5 |
| w b e word motion | 2.4 | Ch1 L5 | ✅ | Ch1 L6 |
| 0 $ ^ line edges | — | Ch5 L3 | ✅ | Ch1 L7 |
| **CHAPTER 2: DELETION** |
| dw delete word | 2.1 | Ch2 L2 | ✅ | Ch2 L1 |
| d$ delete to EOL | 2.2 | — | ✅ | Ch2 L2 |
| dd delete line | 2.6 | Ch2 L2 | ✅ | Ch2 L3 |
| Operator + motion concept | 2.3 | Ch3 L1-2 | ✅ | Ch2 L4 |
| Count + motion (2w, 3j) | 2.4 | — | ✅ | Ch2 L5 |
| Count + operator (d2w) | 2.5 | — | ✅ | Ch2 L6 |
| **CHAPTER 3: PUT, REPLACE, CHANGE** |
| p put/paste | 3.1 | Ch2 L1 | ✅ | Ch3 L1 |
| r replace char | 3.2 | Ch4 L3 | ✅ | Ch3 L2 |
| ce change word | 3.3 | — | ✅ | Ch3 L3 |
| c$ C change to EOL | 3.4 | — | ✅ | Ch3 L4 |
| o O open line | 6.1 | Ch4 L1 | ✅ | Ch3 L5 |
| **CHAPTER 4: SEARCH & FIND** |
| f F find char | — | Ch5 L1 | ✅ | Ch4 L1 |
| t T till char | — | Ch5 L1 | ✅ | Ch4 L2 |
| ; , repeat find | — | Ch5 L2 | ✅ | Ch4 L3 |
| n N search next/prev | 4.2 | Ch7 L1 | ✅ | Ch4 L4 |
| **CHAPTER 5: VISUAL MODE** |
| v visual char mode | 5.3 | Ch2 L3 | ✅ | Ch5 L1 |
| V visual line mode | — | Ch2 L4 | ✅ | Ch5 L2 |
| Visual + operator (d, y, c) | — | Ch2 L3-4 | ✅ | Ch5 L3 |
| **CHAPTER 6: YANK & ADVANCED** |
| y yank/copy | 6.4 | Ch2 L1 | ✅ | Ch6 L1 |
| yy yank line | — | — | ✅ | Ch6 L2 |
| ~ case toggle | — | Ch8 L6 | ✅ | Ch6 L3 |
| < > indent | — | Ch2 L6 | ✅ | Ch6 L4 |
| gg G document nav | 4.1 | Ch6 L1 | ✅ | Ch6 L5 |
| s S substitute | — | Ch4 L4 | ✅ | Ch6 L6 |
| R replace mode | 6.3 | — | ✅ | Ch6 L7 |

## What We EXCLUDE (not in kindaVim)

| Feature | In vimtutor? | In Vimified? | Why excluded |
|---|---|---|---|
| :q! :wq exit/save | 1.2, 1.6 | — | No files in kindaVim |
| :w write file | 5.2 | — | No files |
| :!command shell | 5.1 | — | No shell |
| :r read file | 5.4 | — | No files |
| :s substitute regex | 4.4 | — | No ex commands |
| / ? search entry | 4.2 | Ch7 | No search prompt |
| % bracket match | 4.3 | Ch8 L3 | Not in kindaVim |
| . dot command | — | Ch8 L4 | Not in kindaVim |
| J join lines | — | Ch8 L5 | Not in kindaVim |
| Ctrl-A/X numbers | — | Ch8 L1 | Not in kindaVim |
| Macros | — | Ch8 L2 | Not in kindaVim |
| Blockwise visual | — | Ch2 L5 | Not in kindaVim |
| Text objects (iw, aw) | — | Ch1 L4 | Limited support |
| Paragraph nav ({ }) | — | Ch6 L3 | Not confirmed |
| .vimrc config | 7.2 | — | Not relevant |
| :help system | 7.1 | — | Not relevant |

## Proposed Progression (6 Chapters, ~35 lessons)

### Chapter 1: Survival Kit (7 lessons) — DONE
hjkl → x → i/Esc → A/a → u → w/b/e → 0/$

### Chapter 2: Deleting & The Vim Grammar (6 lessons)
dw → d$ → dd → operator+motion concept → count+motion → count+operator

### Chapter 3: Put, Replace, Change (5 lessons)
p/P → r → ce → c$/C → o/O

### Chapter 4: Search & Find (4 lessons)
f/F → t/T → ;/, → n/N

### Chapter 5: Visual Mode (3 lessons)
v → V → visual + operators

### Chapter 6: Yank & Advanced (7 lessons)
y → yy → ~ → <> → gg/G → s/S → R

**Total: 32 lessons covering every kindaVim-supported feature**
