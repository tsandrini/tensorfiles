---
name: retro
description: End-of-session retro — distill durable learnings into workspace memory and flag promotion candidates
disable-model-invocation: true
---

# Session retro

Distill this session's durable learnings into the workspace memory layer.

1. Collect durable, non-obvious learnings from the session: dev-env and
   build quirks, debugging discoveries, architectural facts, corrected
   mistakes, stated user preferences. Skip anything derivable from code,
   already recorded, or session-specific.
2. Locate the workspace memory directory: `.claude/memory/` at the
   workspace root (see `autoMemoryDirectory` in the workspace settings).
   Read `MEMORY.md` first.
3. For each learning, append to or update a topic file named
   `<scope>--<topic>.md` (scope = subsystem or repo). Keep the
   `MEMORY.md` index in sync — one line per topic file, ≤ ~60 lines
   total.
4. Promotion pass: for entries now stable (confirmed across sessions or
   by the user), propose promotion per the harness-conventions decision
   table — constraints/orientation into a rule, procedures/reference
   into a skill — and prune the memory entry once promoted. Present
   proposals to the user; never promote silently.
5. Prune stale or disproven entries. The buffer stays small; the curated
   tiers are the archive.
