# tutorial-writer-plugin

A reusable system for producing long-form technical tutorials in a specific
house style — feature-named chapters, user-first prose, single-file HTML
with chalkboard code, progressive illustrations, ambient microinteractions.
Reverse-engineered from the kindaVim Tutor walkthrough.

## Install

This is a **copy-paste plugin**. No installer, no global state, no Claude
Code plugin registry — you copy the whole `tutorial-writer-plugin/`
directory into any project where you want to produce a tutorial.

```bash
# From the root of a new project
cp -r /path/to/tutorial-writer-plugin .
```

That's the whole install. Commit the directory if you want.

Why not a user-level skill at `~/.claude/skills/`? Because we're still
iterating on the system. Per-project copies let each project be on a
specific version without surprise updates breaking old tutorials.

## Use

With the plugin copied into a project, ask Claude (in that project) to do
one of:

- **New tutorial:** "Write a tutorial using the tutorial-writer plugin."
- **Revise existing:** "Revise `docs/tutorial.html` using the tutorial-writer plugin."

Claude finds `tutorial-writer-plugin/skills/tutorial-writer/SKILL.md`,
reads it as a playbook, and proceeds. The SKILL.md references the rest
of the system at `tutorial-writer-plugin/docs/tutorial-system/`.

## Layout

```
tutorial-writer-plugin/
├── plugin.json                              Metadata (self-describing)
├── README.md                                This file
├── skills/
│   └── tutorial-writer/
│       └── SKILL.md                         Orchestrates the whole workflow
├── agents/
│   └── tutorial-architect.md                For the scaffold-before-prose phase
└── docs/
    └── tutorial-system/
        ├── README.md                        System overview
        ├── principles.md                    Pedagogical + aesthetic axioms
        ├── style-guide.md                   Voice, typography, rewrites
        ├── tutorial-blueprint.md            Document skeleton
        ├── explanation-patterns.md          8 concrete prose patterns
        ├── implementation-patterns.md       Required/recommended product features
        ├── workflow.md                      End-to-end production steps
        ├── review-checklist.md              Ship-readiness QA
        ├── generation-prompt.md             Fill-in-the-blanks prompt for new tutorials
        └── revision-prompt.md               Four-phase prompt for revising drafts
```

## Updating

When the plugin evolves in its source repo (e.g., this one), you can:

1. Copy the updated plugin directory over the one in your target project, or
2. Manually merge the changes if your project customized the skill or docs.

Each copy is independent. A tutorial produced against v1.0 of the plugin
stays valid even if you update the plugin to v1.1 somewhere else.

## Required tools

- **Shiki** (via CDN, no install) — syntax highlighting in the output HTML
- **cwebp + sips** (macOS ships `sips`; `brew install webp` for `cwebp`) —
  optimize illustrations
- **nano-banana** (MCP tool) — generate progressive chapter illustrations
- **peekaboo** (brew install) — deterministic screenshot capture, if the
  tutorial's artifact has a UI

All tools are optional except Shiki — tutorials without illustrations,
screenshots, or a UI can still ship using just the prose system.
