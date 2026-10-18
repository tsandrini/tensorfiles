---
name: retro
description: End-of-session retro — distill durable learnings into ccdash memories and flag promotion candidates
disable-model-invocation: true
---

# Session retro

Distill this session's durable learnings into the workspace's knowledge in
ccdash (the hub), through the ccdash tools.

1. Collect durable, non-obvious learnings from the session: dev-env and
   build quirks, debugging discoveries, architectural facts, corrected
   mistakes, stated user preferences. Skip anything derivable from code,
   already recorded, or session-specific.
2. For each learning, `recall` first (by query, then by the likely slug
   `<scope>--<topic>`; scope = subsystem or repo). Update an existing
   memory with `remember` on its slug (rewrite the whole body, keep the
   summary current), or create a new one with a one-line `summary` and the
   `project` it belongs to. Open work goes to `issue_add`, what landed to
   `progress`.
3. `verify` every injected or recalled memory the session confirmed; fix
   or `supersedes` the ones it disproved.
4. Promotion pass: for memories now stable (confirmed across sessions or
   by the user), propose promotion per the harness-conventions decision
   table — constraints/orientation into a rule, procedures/reference
   into a skill — and archive the memory once promoted. Present
   proposals to the user; never promote silently.
5. Never write `.claude/memory/` files: they are a frozen archive.
