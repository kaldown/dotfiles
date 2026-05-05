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
- **Plan lifecycle:** once a plan in `.claude/plans/` is fully executed, move it to `.claude/plans/completed/` (do not delete). The spec + git history are the durable, committed record; `completed/` keeps the planning trail as personal scratch. Both `.claude/plans/` and `.claude/plans/completed/` are gitignored.

## File categories

| Role | Location | Committed? |
|---|---|---|
| Project context root | `CLAUDE.md` | yes |
| Personal Claude directives | `CLAUDE.local.md` | no |
| Operational conventions | `rules/<topic>.md` + `rules/README.md` | yes |
| Durable design intent (specs, roadmaps) | `docs/specs/` (or the project's existing convention) | yes |
| Transient implementation plans (in flight) | `.claude/plans/` | no |
| Completed plans (post-execution archive) | `.claude/plans/completed/` | no |

## Questions for Claude to ask the user when instantiating this pattern

Before generating files, walk the user through these decisions:

1. **What rules to seed on day one?** `workspace-layout.md` is mandatory — it defines the system. `commit-style.md` is usually worth seeding from existing commit history. Anything else should be earned by friction, not aspiration.
2. **What tool-behavior overrides go in `CLAUDE.local.md`?** Most common: redirecting where a tool (e.g., superpowers) writes its output to match this project's spec/plan locations.
3. **Does the project already have a `docs/` convention?** If yes, slot specs into the existing pattern; do not impose `docs/specs/` if `docs/design/` is already in use.
4. **Are there existing docs to retrofit into the cross-reference graph?** Usually not needed — once `CLAUDE.md` exists and references them, they are reachable. Avoid adding back-pointer footers; they violate the forward-only principle.
5. **Where should `rules/` live — repo root or under `docs/`?** Recommend root: rules are operational, not documentary; rooting them next to `CLAUDE.md` makes the "entry point + body of conventions" mental model clearer.
6. **Will this project ship production error monitoring?** If yes (recommended for any project with real users), see the **Error monitoring: Sentry** entry in the cross-project defaults below for the wiring pattern, scaffold artifacts, and override conditions. The official Sentry Claude Code plugin (`sentry@claude-plugins-official`) provides a `sentry-sdk-setup` skill that handles language/framework-specific SDK wiring — invoke it once the decision is made, instead of writing init code by hand.

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
    └── plans/               gitignored (transient, in flight)
        └── completed/       gitignored (post-execution archive)
```

`.gitignore` must list `/CLAUDE.local.md` and `.claude/` (or `.claude/plans/` specifically).

## User cross-project defaults

User-level conventions that apply across all the user's projects, independent of stack. When instantiating this template for a new project, evaluate each default against the new project and seed the corresponding rule unless the project explicitly opts out.

| Default | Applies when | Seed as |
|---|---|---|
| **Self-hosted PaaS: Dokploy** | Project will be self-hosted on the user's own VPS (not on managed cloud like Vercel / Railway / Fly). | `rules/deployment.md` — declare Dokploy as the deploy target; project ships as a Docker Compose stack that Dokploy manages, image pulled from GHCR or built from git via Dokploy. |
| **Reverse proxy: Traefik** | Project is self-hosted via Docker (under Dokploy or standalone compose with a host-level Traefik). | Same `rules/deployment.md` — Traefik is the router. Routes declared via container labels in compose. |
| **Error monitoring: Sentry** | Project ships to production with real users (any web service, worker, or scheduled job). | `rules/observability.md` describing init contract + env-var conventions; an `app/observability.py` (or stack-equivalent) wrapper module so call sites never import the SDK directly; a `.sentryclirc` at repo root pinning org/project; a project-local debug skill that defers CLI mechanics to the auto-installed `sentry-cli` agent skill. Use the `sentry-sdk-setup` skill (from `sentry@claude-plugins-official`) to wire the SDK for the project's stack. |
| **Pre-commit local validation** | Project has any CI gating (lint, typecheck, tests, migration check) and pushes to `main` deploy to production. | `rules/pre-commit-checks.md` declaring a single aggregator command (`make check`, `pnpm check`, `cargo check`, etc.) that mirrors CI checks in CI order and must be green before every commit. Project must expose the aggregator alongside individual targets. |
| **Testing scope: own logic, not libraries** | Project has any test suite. | `rules/testing-scope.md` (or `rules/testing.md` if the project already uses that filename) declaring what is in scope (pure logic, domain invariants, anything where a regression in our code silently changes observable behavior) and what is out of scope (settings parsing, third-party integrations, HTTP probes against external services, UI rendering, configuration boilerplate). |
| **Subagent model floor: never haiku** | Project uses Claude Code subagent dispatch (Agent / Task tool) — including in implementation plans authored by `writing-plans`. | `rules/subagent-models.md` declaring sonnet as the floor for mechanical/implementation dispatches and opus for design/review dispatches; haiku forbidden regardless of task simplicity. CLAUDE.md operating principles cite the rule explicitly so it surfaces during plan creation. |
| **Plan-lifecycle gate: move executed plans** | Project uses transient implementation plans (e.g., from `superpowers:writing-plans`, `feature-dev:feature-dev`, or hand-written). | `rules/plan-lifecycle.md` declaring the move-to-`completed/` rule as a completion gate: a plan is not "done" until its file is moved out of the active directory. CLAUDE.md operating principles cite the rule so it triggers at completion time, not as a buried directory layout bullet. |

### Rationale (so future scaffolds can judge overrides)

**Dokploy chosen over Coolify** because: lower idle footprint (~0.8% vs ~6% CPU on a 2-vCPU box) matters on small VPS hosting multiple apps; explicit Project → Environment → Service multi-tenancy fits the "many small projects on one host" pattern; community Terraform provider enables infra-as-code reproduction of the deploy setup; Apache 2.0 license; first-class scheduled-jobs with 4 typed kinds (App / Compose / Server / Dokploy-Server). Trade-off accepted: smaller community than Coolify, fewer one-click DB types, less UI polish.

**Traefik chosen over Caddy** because: it's Dokploy's only built-in proxy; Docker label-based routing is the standard idiom across self-hosted PaaS tooling; the label muscle memory transfers if a project later moves out of PaaS to raw compose with a host-level Traefik. Caddy *can* do label routing via `caddy-docker-proxy`, but neither Dokploy nor Coolify uses that plugin — Caddy in PaaS world means a static Caddyfile, which loses the compose-as-code property.

**Override the PaaS default if:** the project is a single-app deploy on a managed service (Vercel / Railway / Fly), the project genuinely needs a Coolify-only specialty database, or the project must run on a platform where Dokploy can't (e.g., serverless-only).

**Override the proxy default if:** the project is a single-app static-file host where a one-line Caddyfile beats label config, or the project uses Cloudflare Tunnel / Tailscale Funnel (no inbound proxy needed at all).

**Sentry chosen because:** mature SDKs across runtimes with consistent ergonomics; first-class Claude Code plugin (`sentry@claude-plugins-official`) ships maintained `sentry-sdk-setup`, `sentry-workflow`, and `sentry-cli` skills that absorb the boilerplate; the modern `sentry` CLI (distributed at cli.sentry.dev, distinct from the legacy `sentry-cli` from docs.sentry.io) auto-detects org/project from DSN and supports `event list --full` for stack traces and `issue explain` for AI root-cause analysis; provider can be swapped later (e.g., to Datadog) by isolating init in one wrapper module — call sites stay vendor-neutral.

**Override the error-monitoring default if:** the project is a CLI tool / library / experiment with no production deploy (no users to monitor); the project ships to a platform with built-in error tracking already wired (e.g., Vercel's error monitoring); or the project's compliance posture forbids vendor telemetry.

**Pre-commit local validation chosen because:** under the production-only / Dokploy default, every push to `main` triggers a production redeploy. CI is a safety net, not the first line of validation; format/lint/test failures caught only in CI waste a 5-minute round-trip *and* leave broken commits in `main`'s public history. Local validation is seconds when the dev image is already built. Binding the rule on humans and agents alike is what makes "any `main` SHA is deployable" a real invariant rather than an aspiration. The aggregator command shape (`make check` and friends) mirrors CI step-for-step so there is no drift between "what CI runs" and "what I ran locally."

**Override the pre-commit-checks default if:** the project has no CI (nothing to mirror), or the project is a research / scratch repo where commits are intentionally rough and `main` is not deploy-tied.

**Testing scope chosen because:** every test costs maintenance forever; a test against a third-party library passes today, fails when that library upgrades for a legitimate reason, and never once catches a bug we introduced. Tests earn their keep when a green `make check` means "the application still does what we promised" — tests that mirror framework guarantees (pydantic-settings parsing, ORM dialect details, SDK request shapes) dilute that signal. The rule is binding because without it, the test suite drifts toward "passes everything, catches nothing" — a state that is worse than no test suite at all because it inspires false confidence at PR-review time. Domain invariants (e.g., "every archetype declares a `pdf_filename`") belong in their owner's tests (loader/validator/migration) rather than spread across integration tests, so there is one place to fix when the invariant changes.

**Override the testing-scope default if:** the project is a thin wrapper around a third-party library where the integration *is* the product (in which case the integration shape is owned logic, not framework guarantee), or the project's compliance/audit posture mandates exhaustive integration coverage (regulated industries). Neither case is the user's typical project shape.

**Subagent model floor chosen because:** the user has repeatedly observed that haiku-class models produce code that *looks* correct but fails subtly — silent fallbacks, missed validation rules, partial implementations claimed as complete — even when given a clear plan. Re-dispatching the same task on sonnet returns correct work in one shot. Total time-to-correct-output is lower starting from sonnet than from haiku-then-sonnet; the apparent compute saving from haiku is a false economy. The `writing-plans` skill's per-task model-selection table (mechanical → cheap, integration → standard, design → capable) still applies for picking *between* sonnet and opus — the floor moves up, the gradient stays.

**Override the subagent-model-floor default if:** never, in practice. This is a hard floor, not a default. If a future model release introduces a tier between haiku and sonnet that proves reliable, this rule gets revised explicitly — not silently bypassed.

**Plan-lifecycle gate chosen because:** the skill chain that produces and executes plans (`superpowers:brainstorming` → `superpowers:writing-plans` → `superpowers:subagent-driven-development` → `superpowers:finishing-a-development-branch`) ends at clean boundaries that do not include plan-file cleanup. With the rule only documented as a workspace-layout bullet, Claude finishes the last task and reports "done" without ever moving the plan — every time, in every project. Surfacing the rule as a CLAUDE.md operating principle (not just a `rules/` entry) turns it into a completion-time tripwire. The `completed/` directory exists so the planning trail is preserved (as personal gitignored scratch) without polluting the active queue.

**Override the plan-lifecycle default if:** never. The directory paths can change to fit a project's existing convention (e.g., a project that commits plans under `docs/plans/` adapts the path), but the move-on-completion ritual stays. A project where plans are not used at all does not need the rule — the trigger is "project uses transient plans."

### What to scaffold in the new project's `rules/deployment.md`

Concrete starter content the future scaffold should generate (adapt names to the new project):

```markdown
# Deployment

## Host
- Self-hosted via **Dokploy** on a Hetzner VPS.
- Project is registered in Dokploy as a Compose application.

## Proxy
- **Traefik** (Dokploy-managed). Routes declared via container labels in `docker-compose.yml`.
- TLS via Let's Encrypt, managed by Dokploy.

## Pipeline
- GitHub Actions runs tests + builds the image.
- Image pushed to **GHCR** (`ghcr.io/<owner>/<repo>`).
- Dokploy pulls the new tag and redeploys via webhook (or polling, per Dokploy config).
- Secrets live in Dokploy environment variables — never in `.env` files committed or shipped to the box.

## Production-only
- There is no staging. Every push to `main` is a production deploy.
- See `rules/production-only.md` (or equivalent) for the binding rule.
```

### What to scaffold for Sentry observability

Three artifacts at the repo, plus a one-time auth step that lives outside the repo.

**1. `rules/observability.md`** — declares the init contract:

```markdown
# Observability

- Provider: Sentry. All wiring lives in `app/observability.py` (or stack equivalent). Call sites must NOT import `sentry_sdk` directly — vendor swap stays a one-module change.
- DSN comes from `SENTRY_DSN` env var. Empty DSN is the kill-switch (init no-ops, app continues running).
- Init failures are caught and logged; observability must never take down a process.
- For multi-process apps (web + worker + cron + migrations), set `tag:process` to differentiate. Per-process sample rates live in the `Settings` class. High-frequency endpoints (e.g., `/healthz`) are dropped via a `traces_sampler` to avoid quota burn.
- Logging integration is capped at WARNING (lower-severity records become breadcrumbs, attached to error events for free).
```

**2. `.sentryclirc`** at repo root (committed; contains no secrets — only the project mapping):

```ini
[defaults]
org = <org-slug>
project = <project-slug>
```

This pins debugging from this repo to the right Sentry project even when the user has multiple projects on the same account. The CLI reads `[defaults]` before any DSN auto-detection or cache lookup — it's the authoritative override.

**3. Project-local debug skill** at `.claude/skills/<project>-debug/SKILL.md`:

- Triggers on present-tense debug language ("I have an issue", "debug this with me", "X is failing").
- **Defers CLI mechanics** (commands, auth, JSON output, Seer AI, exit codes) to the auto-installed `sentry-cli` skill — do not duplicate.
- Adds **only project-specific context**: process-tag filters, source-mapping convention (e.g., in-app frames map to `app/<...>`), recommended drilldown flow with the project's tag values pre-filled, fallback path (e.g., SSH to deploy host) for cases when Sentry has nothing.
- Aim for under 80 lines. If it exceeds that, the project probably has too many process types to belong in one skill — split.

**4. Auth (one-time, outside the repo).** The default scope from `sentry auth login` is `org:ci` — enough to upload releases / sourcemaps but blocks every read endpoint with 403. For agent-driven debugging, create a personal API token at the vendor's account-token settings page with `event:read project:read org:read` scopes and authenticate via `sentry auth login --token <...>` or `SENTRY_AUTH_TOKEN` env var. The `~/.sentryclirc` `[auth]` section is the user-level credential store; project-level `.sentryclirc` should hold ONLY `[defaults]` and is safe to commit.

### What to scaffold for pre-commit-checks

Two artifacts: the rule and the aggregator target.

**1. `rules/pre-commit-checks.md`:**

```markdown
# Pre-commit checks

Every CI check must pass locally before commit. CI is a safety net, not the first line of validation. Pushing `main` triggers a production redeploy (see `rules/deployment.md`); a failure caught locally saves a CI round-trip and keeps half-broken code out of `main`'s history.

## How to run

One command:

    <aggregator>   # e.g. `make check`, `pnpm check`, `cargo check`, `nx check`

It runs the same checks CI runs, in CI order, exits non-zero on first failure.

## Common fixes

- formatter check fails → run the formatter target.
- lint check fails → fix the source (auto-fix flag if available).
- type check fails → fix typing or add a justified ignore comment.
- tests fail → fix the test or fix the code; never commit red tests.
- migration check fails → fix the migration; never commit a broken chain.

## Why this is binding

`main` is one push from production. Skipping local validation wastes the runner, pushes broken commits into permanent history, and weakens the assumption that any `main` SHA is deployable.
```

**2. The aggregator target.** Pick the right idiom for the stack and ensure it runs CI checks in CI order. Examples:

- **Python (Make + Docker)** — what subscriber uses:
  ```make
  lint:           ; $(RUN) sh -c "ruff check . && ruff format --check ."
  typecheck:      ; $(RUN) pyright app/
  migrate-check:  ; $(RUN) sh -c "DATABASE_URL=sqlite:////tmp/m.db <required-vars> alembic upgrade head"
  test:           ; $(RUN) pytest
  check: lint typecheck migrate-check test
  ```
- **Node / TypeScript** — `package.json` scripts:
  ```json
  { "scripts": {
      "lint": "eslint . && prettier --check .",
      "typecheck": "tsc --noEmit",
      "test": "vitest run",
      "check": "npm run lint && npm run typecheck && npm run test"
  } }
  ```
- **Rust** — `cargo` aliases in `.cargo/config.toml`:
  ```toml
  [alias]
  check-all = ["fmt", "--check", "&&", "clippy", "--all-targets", "--", "-D", "warnings"]
  ```

The names matter less than the property: a single command runs every CI check the same way CI runs it. Never recommend a partial check (`make lint && make test` skipping typecheck) in the rule — drift between "what I ran" and "what CI runs" is exactly what the rule prevents.

### What to scaffold for testing-scope

One artifact: `rules/testing-scope.md` (use existing `rules/testing.md` if the project already has it). Adapt the third-party examples to the project's actual stack (Telegram + aiogram for a bot project, Streamlit for a UI project, Cloudflare CDN for static-asset projects, etc.) — the principle is the same; only the names change.

```markdown
# Testing scope

Test what we own. Don't test what we depend on.

## Test

- **Pure logic.** Deterministic input→output functions; domain rules with non-trivial branches; repository queries with non-trivial WHERE/ORDER BY.
- **Domain invariants enforceable from data/config.** Constraints we declared (`Field(min_length=...)`, custom validators), schema rules the app would silently violate without a guard.
- **Anything where a regression in our code would silently change observable behavior.**

## Don't test

- **Pydantic settings parsing.** `pydantic-settings` is tested upstream. Keep tests of constraints *we wrote* (`Field(min_length=1)`, custom validators); drop tests that just verify pydantic accepted a value.
- **Third-party integrations.** SDK transports (Sentry, Telegram, Cloudflare), framework rerun semantics, ORM dialect behavior — out of scope. Verified manually or via observability.
- **HTTP probes against external services.** Production health is not a unit-test concern.
- **UI rendering.** Unless the project ships with a browser harness already, drop UI rendering tests.
- **Configuration boilerplate.** Tests that mirror what the framework already guarantees.

## Why this is binding

Every test costs maintenance forever. A test against a third-party library passes today, fails when the library upgrades for a legitimate reason, and never once catches a bug we introduced. It is dead weight. The suite earns its keep when a green check command means "the application still does what we promised."

If a setting is misconfigured in production, error monitoring (e.g., Sentry) will surface it immediately. No test coverage needed.

## How to apply

- Before writing a test, ask: "if our code stays correct and the library upgrades, will this test still pass?" If no, you're testing the library, not us.
- If you find an existing test that only exercises a third-party library's documented behavior, delete it.
- Domain invariants belong in their owner's tests (loader/validator/repository/migration), not in spread-out integration tests. One place to fix when the invariant changes.
```

Filename note: prefer `testing-scope.md` for new projects (the topic is *scope*, not all-of-testing). Existing projects with `testing.md` should keep the existing filename to avoid churn.

### What to scaffold for subagent-model-floor

Two artifacts: a `rules/subagent-models.md` file and an explicit citation in `CLAUDE.md` operating principles. The rule must be surfaced in CLAUDE.md (not only in `rules/`) because plan creation reads operating principles, and the rule needs to be in context every time a plan assigns models per task.

**1. `rules/subagent-models.md`:**

```markdown
# Subagent model floor

When dispatching subagents (Agent / Task tool with a `model:` parameter), pick from a deliberate floor — never the cheapest model.

## The rule

- **Never haiku.** Haiku-class models produce subtly wrong code, miss the spec, or stall on judgment calls. The cost of bad work is far higher than the cost of compute.
- **Sonnet is the floor** for mechanical implementation tasks (well-specified, 1–2 files, clear acceptance criteria).
- **Opus for design and review.** Spec compliance review, code quality review, architectural decisions, and any task with judgment calls go to the most capable model available.

## Why

Repeated experience: dispatches on haiku produced code that *looked* right but failed in subtle ways (silent fallbacks, missed validation rules, partial implementations claimed as complete). Re-running with sonnet fixed the work in one shot. Total time-to-correct-output was lower starting with the stronger model.

## How to apply

- When calling `Task` / `Agent`: explicitly set `model: "sonnet"` (implementation) or `model: "opus"` (review / design).
- When authoring an implementation plan (`writing-plans` skill): every task that names a model uses sonnet or opus. Reject any plan template that suggests haiku.
- If you find yourself thinking "this task is so simple haiku could do it" — it isn't. Either it's mechanical enough to do inline (no subagent), or it needs sonnet.
- A subagent that returns BLOCKED, gives confused output, or produces wrong code is often a model-choice failure, not a task failure. Re-dispatch with a more capable model before re-explaining the task.

## Scope

This rule applies to the Anthropic / Claude Code subagent dispatch surface used during development. It does NOT prescribe model choice for production app code (if the project itself calls an LLM, that decision is made on its own merits in product code, not under this rule).
```

**2. CLAUDE.md operating principle entry** (append to the project's existing operating-principles list, renumbering as needed):

```markdown
N. **Subagent model floor: never haiku.** Every Agent / Task dispatch — including in implementation plans — uses sonnet (mechanical) or opus (design / review). Haiku is forbidden regardless of task simplicity. See [`rules/subagent-models.md`](rules/subagent-models.md). Plans that name a model per task MUST cite this rule and pick from sonnet/opus only.
```

The CLAUDE.md citation is what makes this rule visible during plan creation. Without it, plans authored by `writing-plans` may silently default to haiku for tasks the skill classifies as "mechanical" — which is exactly the failure mode this rule prevents.

### What to scaffold for git-safety

Two artifacts: a `rules/git-safety.md` file and an explicit citation in `CLAUDE.md` operating principles. The CLAUDE.md surface is mandatory because plan creation and subagent dispatch both happen with `CLAUDE.md` in context — and this rule needs to be there every time a plan is authored or a subagent is sent shell access. Without that surface, the rule sits in `rules/` and gets skipped exactly when it matters.

**1. `rules/git-safety.md`:**

```markdown
# Git safety

Destructive git operations have caused real incidents (lost commits, silent overwrites of unrelated test files, inconsistent working trees that masked test failures). The rule is binding for the human, for Claude directly, and for every subagent dispatched from any plan.

## The rule

**Never run any of the following without explicit user approval:**

- `git stash` (any flavor — `push`, `pop`, `apply`, `drop`)
- `git checkout <ref> -- <file>` (file restoration from another commit)
- `git checkout -- <file>` (discard working-tree changes)
- `git restore` (any flavor)
- `git reset` (any flavor — soft, mixed, hard)
- `git clean`
- `git rebase`
- `git revert`
- `git push --force` / `git push --force-with-lease`
- `git branch -D` / `git branch --delete --force`
- `git worktree remove`

If a task appears to require any of these, STOP and ask. Describe the exact command, the reason it appears necessary, and the files / refs it would touch. Wait for explicit approval. The cost of asking is one message; the cost of silently destroying state is unbounded.

## Allowed without asking

- **Read-only git:** `status`, `log`, `diff`, `show`, `rev-parse`, `ls-files`, `blame`, `branch --show-current`. These never alter state.
- **`git add <specific paths>` and `git commit`** for paths the user (or an approved plan) explicitly named. Never `git add -A` or `git add .` — those quietly stage unintended files (`.env`, build artifacts, scratch notes).
- **`git checkout -b <name>`** on a clean working tree. Branch creation is non-destructive.

## Never silence errors

`2>/dev/null`, `|| true`, `&> /dev/null`, and the equivalent in any shell are forbidden in git command chains regardless of subcommand. Hidden failures are exactly what allow destructive sequences to slip through review. If a command might fail, the failure must be visible — surface it, don't suppress it.

## Why

The trigger incident: a reviewer subagent proposed
`git stash; git checkout <old-sha> -- tests/integration.rs; git checkout <branch> -- tests/integration.rs; git stash pop 2>/dev/null`
while reviewing a change that did not touch `tests/integration.rs` at all. The user caught it. They will not always catch it. The combination of (a) destructive ops out of scope and (b) error-silencing was specifically designed to look benign — that's what makes the rule binding rather than discretionary.

## How to apply

- **Direct work:** before typing any forbidden command, stop and ask.
- **Plan authoring:** every implementation plan MUST include a "Subagent guardrails" section that repeats this rule. No plan ships without it. Plans missing this section should be rejected during self-review.
- **Subagent dispatch:** every Agent / Task dispatch prompt MUST include this rule verbatim. Never assume the subagent inherits context — the prompt is the only briefing they get.
- **Reviewing subagent output:** if a subagent reports having run a forbidden command, treat the result as compromised. Verify with read-only commands and surface to the user before relying on the work.

## Scope

Applies to git operations against the project's working tree and history. Does not apply to git operations on unrelated scratch directories the user explicitly designated as throwaway. When in doubt, ask.
```

**2. CLAUDE.md operating principle entry** (append to the project's existing operating-principles list, renumbering as needed):

```markdown
N. **Git safety: never run destructive git commands without asking.** `stash`, `checkout <ref> -- <file>`, `restore`, `reset`, `clean`, `rebase`, `revert`, `push --force`, `branch -D`, `worktree remove` — all require explicit user approval before execution, by Claude directly and by every subagent dispatched from any plan. Read-only git is fine; `git add <specific paths>` and `git commit` are fine for explicitly named paths. Never silence errors (`2>/dev/null` etc.). See [`rules/git-safety.md`](rules/git-safety.md). Plans MUST include a "Subagent guardrails" section that repeats this rule; subagent dispatch prompts MUST cite it.
```

The CLAUDE.md citation is what makes this rule visible during plan creation and subagent dispatch. It sits next to the subagent-model-floor entry — together they cover "which model" and "what shell access" for every dispatch.

### What to scaffold for plan-lifecycle

Two artifacts: a `rules/plan-lifecycle.md` file and an explicit citation in `CLAUDE.md` operating principles. The CLAUDE.md surface is mandatory — without it, the rule sits in `rules/` and never gets read at completion time, since none of the plan-execution skill flows include plan-file cleanup as a step.

**1. `rules/plan-lifecycle.md`:**

```markdown
# Plan lifecycle

Implementation plans live under `.claude/plans/` (gitignored, transient). Once a plan is fully executed, its file moves to `.claude/plans/completed/` — it is not deleted. The move is a completion gate, not an afterthought.

## The rule

A plan isn't complete until its file has been moved. The order is:

1. Final task of the plan committed.
2. Verification done (pre-commit checks green; manual checks if applicable).
3. **`mv .claude/plans/<plan>.md .claude/plans/completed/`** — *this step*.
4. Now you may report "done" to the user.

If you are about to say "all tasks complete", "implementation finished", "the plan is done", or anything similar without having performed step 3, stop. Move the file first.

## Why

- The `docs/specs/` document and the git history are the durable, committed record of what was built and why. The plan is transient scaffolding for one execution session.
- `.claude/plans/` should reflect *active* plans only. Once executed, a plan no longer guides work; keeping it at the top level looks like an in-flight queue when it isn't.
- Deleting plans loses the planning trail. Moving to `completed/` preserves it as personal scratch (still gitignored) without polluting the active queue.
- The skill flows that produce and execute plans end at clean boundaries that do *not* include plan-file cleanup. Without an explicit project-level rule surfaced as a completion gate, the move gets skipped on every plan.

## How to apply

- During execution: do not declare a plan finished until the file is in `completed/`. Treat the move as part of the plan's completion ritual, on the same level as pre-commit checks passing.
- During reading: when surveying `.claude/plans/`, files outside `completed/` are *active*. If you find an old plan-looking file at the top level, ask whether it's truly active or just unfinished cleanup before assuming.
- Across the project: applies to plans created via any skill or hand-written. The directory is the contract; the skill that authored the plan does not matter.

## Scope

Applies to `.claude/plans/`. Specs in `docs/specs/` follow a separate convention — they are committed documentation; a spec is not "completed" by file move, it stays put as the project's history.
```

**2. CLAUDE.md operating principle entry** (append to the project's existing operating-principles list, renumbering as needed):

```markdown
N. **Plan-lifecycle gate.** A plan in `.claude/plans/` isn't complete until its file is moved to `.claude/plans/completed/`. After the final task of a plan is committed, move the file *before* reporting "done" to the user. The move is part of the completion ritual, on the same level as pre-commit checks passing. See [`rules/plan-lifecycle.md`](rules/plan-lifecycle.md).
```

If the project uses a different plan-file location (e.g., `docs/plans/`), adapt the paths in both the rule body and the operating principle. The directory layout is project-shaped; the move-on-completion ritual is universal.

Add new entries to this defaults section only when a decision is genuinely universal across the user's projects (not project-specific). Project-specific choices belong in that project's `rules/`, not here.

## Notes for re-instantiation

- Do not embed file contents from a previous project. Generate fresh content tailored to the new project's stack, naming, and existing conventions.
- The pattern is the architecture, not the boilerplate.
- If the new project uses a different folder convention (e.g., `design/` instead of `docs/specs/`), respect it — adapt the locations, keep the principles.
- The plan-lifecycle rule (move completed plans to `.claude/plans/completed/`) is mandatory across instantiations — it must appear in the new project's `rules/workspace-layout.md` (or equivalent), not only in `CLAUDE.md`. Plans of unknown completion status should be left alone unless the user confirms.
