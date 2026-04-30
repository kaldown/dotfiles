# Claude context pattern

A method for organizing project context, operational conventions, and transient work artifacts in a repository where you collaborate with Claude Code.

## Purpose

Keep project context discoverable and durable, separate transient work-in-progress from durable design intent, and ensure no contextual document is orphaned.

## Core principles

- `CLAUDE.md` is the root entry point; Claude Code auto-loads it from the repo root in every session.
- Every contextual document must be reachable from `CLAUDE.md` (no orphans).
- References are forward-only — `CLAUDE.md` points to its children; children do not back-point to `CLAUDE.md`. Back-pointers add no information when the root is always loaded; they only add boilerplate.
- Committed = durable + shared. Gitignored = transient or personal.
- `rules/` holds operational conventions tooling cannot enforce. NOT for coding style (linters do that). NOT for design rationale (specs do that).

## File categories

| Role | Location | Committed? |
|---|---|---|
| Project context root | `CLAUDE.md` | yes |
| Personal Claude directives | `CLAUDE.local.md` | no |
| Operational conventions | `rules/<topic>.md` + `rules/README.md` | yes |
| Durable design intent (specs, roadmaps) | `docs/specs/` (or the project's existing convention) | yes |
| Transient implementation plans | `.claude/plans/` | no |

## Questions for Claude to ask the user when instantiating this pattern

Before generating files, walk the user through these decisions:

1. **What rules to seed on day one?** `workspace-layout.md` is mandatory — it defines the system. `commit-style.md` is usually worth seeding from existing commit history. Anything else should be earned by friction, not aspiration.
2. **What tool-behavior overrides go in `CLAUDE.local.md`?** Most common: redirecting where a tool (e.g., superpowers) writes its output to match this project's spec/plan locations.
3. **Does the project already have a `docs/` convention?** If yes, slot specs into the existing pattern; do not impose `docs/specs/` if `docs/design/` is already in use.
4. **Are there existing docs to retrofit into the cross-reference graph?** Usually not needed — once `CLAUDE.md` exists and references them, they are reachable. Avoid adding back-pointer footers; they violate the forward-only principle.
5. **Where should `rules/` live — repo root or under `docs/`?** Recommend root: rules are operational, not documentary; rooting them next to `CLAUDE.md` makes the "entry point + body of conventions" mental model clearer.

## Final shape

```
project/
├── CLAUDE.md                committed   ← root
├── CLAUDE.local.md          gitignored
├── rules/                   committed
│   ├── README.md
│   ├── workspace-layout.md
│   └── <other rules>
├── docs/
│   └── specs/               committed (durable design intent)
└── .claude/
    └── plans/               gitignored (transient)
```

`.gitignore` must list `/CLAUDE.local.md` and `.claude/` (or `.claude/plans/` specifically).

## Notes for re-instantiation

- Do not embed file contents from a previous project. Generate fresh content tailored to the new project's stack, naming, and existing conventions.
- The pattern is the architecture, not the boilerplate.
- If the new project uses a different folder convention (e.g., `design/` instead of `docs/specs/`), respect it — adapt the locations, keep the principles.
