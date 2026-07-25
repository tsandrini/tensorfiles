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

Top-level directories are independent repo clones — ignored wholesale,
with exactly two tracked exceptions: `.claude/` (the harness) and
`meta/` (workspace tooling). Loose files at the root auto-track and sync
between machines via the meta-root repo. `meta/scripts/` holds cross-repo
and company-wide helper tooling, runnable by human and Claude alike
(e.g. `sync_all_repos`). A script serving a single Claude workflow lives
inside that skill's directory instead. No third directory exception —
future meta content nests under `meta/`. Internal company doc dumps
(regenerable caches, exports) do NOT get tracked — ignore them.

## Secrets

- Token values NEVER appear in rules, skills, memory, CLAUDE.md, or
  command output — never echo or print them. Context carries pointers
  only: variable name, scope, source.
- Env vars are prefixed `CLAUDE_META_<NAME>`; all Claude tokens are
  read-only.
- Values live in per-workspace agenix envfiles
  (`claude-code-<workspace>-meta-envfile`, plain dotenv format — no
  `export`). Each workspace root's `.claude/meta-env` marker names its
  secret; a direnvrc hook (tensorfiles claude-code module) walks up to
  the nearest marker on EVERY direnv evaluation and loads the envfile —
  markers carry identity, the hook carries backend resolution.
- direnv layers do NOT nest — that is exactly why injection lives in the
  direnvrc hook, not in `.envrc` files. Never re-add tokens via nested
  `.envrc` files.
- Read guards for `.env*` files and decrypted agenix paths are enforced
  by permission deny rules in the tensorfiles claude-code module.
- When testing token presence in shell, use ONLY `${VAR:+set}` — never
  `${VAR:-...}`, `echo $VAR`, or `env` dumps: one wrong expansion prints
  the value into the transcript. Tools must fail hard on empty tokens,
  never fall back to other credentials.

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
