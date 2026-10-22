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

## Reports & page-shaped output

- A report, dashboard, visualization, or any other "HTML" deliverable
  means a standalone local `.html` file — self-contained (inline
  CSS/JS), openable offline, shareable as a plain file. Place it at the
  path I name, otherwise per the Temporary-files rules above.
- Never substitute a claude.ai Artifact for it: artifacts are hard to
  distribute and I cannot edit them myself. Use the Artifact tool only
  when I explicitly ask for an artifact.

## Browser

- All browser interaction goes through the Playwright MCP server
  (nix-deployed, headless Chromium): navigate / snapshot / screenshot /
  evaluate via its tools.
- Never install, enable, or propose the Claude-in-Chrome extension or
  any other browser extension/driver, and never invoke the
  `claude-in-chrome` skill. If the Playwright MCP is missing or
  misbehaving, stop and tell me — I will fix the deployment.

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
`direnv exec` and report the actual results. Exercise the failure path
too (make the new flow fail on purpose: refused, offline, missing
binary) and check what the built package serves, not only the dev setup.

Anything I have to run, apply, decide or answer goes in the final
message of the turn, complete; text before a tool call may never reach me.

## Knowledge (ccdash)

- Durable knowledge lives in the ccdash hub, not in files: use the ccdash
  tools — `recall` before asking about past decisions or quirks,
  `remember` + `verify` for facts, `issue_add`/`issue_update` for work
  items, `progress` for dated entries, `doc_write` for shared documents.
  Everything is scoped to the current workspace.
- Other sessions: `claim` what you are working on (a few words, the paths
  it touches) when you start on something others might touch, `release`
  when done; `tell_session` hands a message to another session, which
  reads it with its next prompt (it never starts a turn there). Messages
  and claims of others arrive as context with your prompts; a warning
  before an edit means the file is claimed — coordinate first.
- `.claude/memory/` directories are frozen archives (imported into the hub
  2026-10-18): never write there. When the tools report the hub offline,
  writes are queued and land later; carry on.

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
