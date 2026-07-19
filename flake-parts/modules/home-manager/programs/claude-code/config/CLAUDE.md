## Environment

- All projects use Nix + Flakes + flake-parts unless stated otherwise.
- Run project tooling through the dev env: `direnv exec . <command>`
  (`direnv allow` first time / after .envrc changes).
- One-off tools not in the project's deps: `nix run nixpkgs#<pkg>` or
  `, <cmd>` — never modify the project's dev environment for them.

## Temporary files

- Throwaway files (intermediate outputs, scripts, scraped data): use the
  session scratchpad directory.
- Files that must live in the project tree (e.g. assets referenced by
  relative path): `.claude-tmp/` at the project root. Never loose files
  in the repo root.

## Git — read-only

Never change git state: no add/commit/push/pull/fetch/checkout/branch/
merge/rebase/reset/stash/tag, no state-mutating `gh`. Read-only
inspection (status, diff, log, show, blame) is fine. When a task ends at
"now commit this", print the exact commands for me and stop — do not
offer or ask to run them. (Deny rules in settings enforce this; this
note is the why.)

## Workflow

Coding happens in phases: idea → architecture discussion → concrete plan
→ implementation → revision. Default to long-term cleanliness and sound
architecture over "just ship it". If my proposal looks wrong —
architecturally, structurally, or as a code smell — push back and
discuss before implementing; I want to be challenged. Skip the phases
only when I explicitly say quick-and-dirty / urgent.

Before declaring a task done, run the project's linters/tests through
`direnv exec` and report the actual results.

## Missing information

If key information is missing (paths, config values, prior context,
genuinely ambiguous intent), do not guess — one clarifying question
beats a confident guess.

## Comments

- Doc comments (`///`, JSDoc, docstrings, Nix `##`): complete and
  conventional — params, returns, errors, examples.
- Inline comments: minimal — only non-obvious constraints, workarounds,
  surprising invariants. Terse phrases, not sentences; `NOTE:` prefix
  for "required for X" remarks; prefer a link (issue/RFC/PR) over prose.
  Past ~2 lines, delete it or move it to docs.
