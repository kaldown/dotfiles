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

Add new entries to this defaults section only when a decision is genuinely universal across the user's projects (not project-specific). Project-specific choices belong in that project's `rules/`, not here.

## Notes for re-instantiation

- Do not embed file contents from a previous project. Generate fresh content tailored to the new project's stack, naming, and existing conventions.
- The pattern is the architecture, not the boilerplate.
- If the new project uses a different folder convention (e.g., `design/` instead of `docs/specs/`), respect it — adapt the locations, keep the principles.
- The plan-lifecycle rule (move completed plans to `.claude/plans/completed/`) is mandatory across instantiations — it must appear in the new project's `rules/workspace-layout.md` (or equivalent), not only in `CLAUDE.md`. Plans of unknown completion status should be left alone unless the user confirms.
