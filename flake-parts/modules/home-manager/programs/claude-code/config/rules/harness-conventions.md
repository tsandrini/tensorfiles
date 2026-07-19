---
paths:
  - "CLAUDE.md"
  - "**/CLAUDE.md"
  - ".claude/**"
  - "**/.claude/**"
---

# Claude harness conventions

Contract for organizing Claude Code knowledge across tsandrini's
workspaces (`meteopress/`, `PesekMudra/`, `tsandrini/`). Loads whenever
harness files are touched. Canonical copy lives in tensorfiles:
`flake-parts/modules/home-manager/programs/claude-code/config/rules/`.

## Tiers, by loading trigger

| Tier | Artifact                    | Trigger                 | Budget                                           |
| ---- | --------------------------- | ----------------------- | ------------------------------------------------ |
| L0   | workspace root `CLAUDE.md`  | every session           | ≤ ~100 lines                                     |
| L1   | `.claude/rules/*.md`        | path match              | ≤ ~40 lines; `paths:` REQUIRED                   |
| L2   | `.claude/skills/*/SKILL.md` | intent or path          | body free; description = 1 line, trigger-phrased |
| L3   | `.claude/memory/`           | dynamic, Claude-written | `MEMORY.md` index ≤ ~60 lines                    |

## Placement decision table

| The knowledge is…                                  | It goes to…                                                                           |
| -------------------------------------------------- | ------------------------------------------------------------------------------------- |
| true for every session in the workspace            | root `CLAUDE.md` (rare — guard jealously)                                             |
| constraint/orientation whenever touching subtree X | rule — subsystem-level by default; repo-level only for hard repo-specific constraints |
| a procedure or deep reference for some tasks       | skill — create once a workflow repeats                                                |
| just learned this session, unvalidated             | memory (via `/retro`); promote once stable, then prune                                |

## Naming

- Rules: `<subsystem>.md`; repo-level rules use the literal repo dir name.
- Skills: `<scope>-<verb>` for procedures, `<scope>-<noun>` for reference;
  the directory name is the slash command.
- Memory topics: `<scope>--<topic>.md`; `MEMORY.md` is the mandatory index.

## Workspace meta layer

Root entries are repo clones, with exactly two exceptions: `.claude/`
(the harness) and `meta/` (workspace tooling). `meta/scripts/` holds
cross-repo and company-wide helper tooling, runnable by human and Claude
alike (e.g. `sync_all_repos`). A script serving a single Claude workflow
lives inside that skill's directory instead. No third root exception —
future meta content nests under `meta/`.

## Secrets

- Token values NEVER appear in rules, skills, memory, CLAUDE.md, or
  command output — never echo or print them. Context carries pointers
  only: variable name, scope, source.
- Env vars are prefixed `CLAUDE_META_<NAME>`; all Claude tokens are
  read-only.
- Values live in per-workspace agenix envfiles
  (`claude-code-<workspace>-meta-envfile`), decrypted at login and
  sourced by the workspace root `.envrc`.
- Read guards for `.env*` files and decrypted agenix paths are enforced
  by permission deny rules in the tensorfiles claude-code module.

## Hard rules

- Never write a rule without `paths:` — it would load unconditionally.
- Rules force-load fully on path match: constraints + pointers only; depth
  belongs in skills.
- Company repos stay clean — no claude files committed to them; personal
  per-repo guidance lives in the workspace meta-root repo instead.
- Prefer subsystem globs (`radar-*/**`) over per-repo globs — new clones
  then inherit coverage with zero config.
- Deep domain truth belongs in the domain's own docs (e.g. meteopress
  `infra-docs-wip/`); rules and skills point at it, they don't copy it.
